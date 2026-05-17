# CloudWatch Alarms — scale-out trigger when CPU is high
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Scale out: ASG CPU above ${var.cpu_high_threshold}%"
  alarm_actions       = [var.scale_out_policy_arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = var.tags
}

# CloudWatch Alarm — scale-in trigger when CPU is low
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "Scale in: ASG CPU below ${var.cpu_low_threshold}%"
  alarm_actions       = [var.scale_in_policy_arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  tags = var.tags
}

# CloudWatch Alarm — ALB 5xx error spike
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx error count exceeds ${var.alb_5xx_threshold} in 1 minute"
  treat_missing_data  = "notBreaching"
  alarm_actions       = length(var.sns_alarm_arns) > 0 ? var.sns_alarm_arns : []

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# CloudWatch Alarm — RDS CPU high
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "RDS CPU above ${var.rds_cpu_threshold}%"
  alarm_actions       = length(var.sns_alarm_arns) > 0 ? var.sns_alarm_arns : []

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = var.tags
}

# CloudWatch Alarm — RDS low free storage
resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold
  alarm_description   = "RDS free storage below ${var.rds_free_storage_threshold} bytes (~5 GB)"
  alarm_actions       = length(var.sns_alarm_arns) > 0 ? var.sns_alarm_arns : []

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = var.tags
}

# SNS Topic — receives all alarm notifications
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.name}-alarms"
  tags  = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.create_sns_topic && var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# CloudWatch Dashboard — single pane of glass for the entire stack
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x = 0; y = 0; width = 12; height = 6
        properties = {
          title   = "EC2 CPU Utilization (ASG)"
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.autoscaling_group_name]]
          annotations = {
            horizontal = [
              { value = var.cpu_high_threshold, label = "Scale-Out Threshold", color = "#ff0000" },
              { value = var.cpu_low_threshold, label = "Scale-In Threshold", color = "#00ff00" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x = 12; y = 0; width = 12; height = 6
        properties = {
          title   = "RDS CPU Utilization"
          period  = 300
          stat    = "Average"
          view    = "timeSeries"
          metrics = [["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id]]
        }
      },
      {
        type   = "metric"
        x = 0; y = 6; width = 12; height = 6
        properties = {
          title   = "ALB Request Count"
          period  = 60
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]]
        }
      },
      {
        type   = "metric"
        x = 12; y = 6; width = 12; height = 6
        properties = {
          title   = "ALB 5xx Errors"
          period  = 60
          stat    = "Sum"
          view    = "timeSeries"
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]]
        }
      }
    ]
  })
}
