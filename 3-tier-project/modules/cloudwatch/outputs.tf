output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : ""
}

output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high alarm (triggers scale-out)"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cpu_low_alarm_arn" {
  description = "ARN of the CPU low alarm (triggers scale-in)"
  value       = aws_cloudwatch_metric_alarm.cpu_low.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
