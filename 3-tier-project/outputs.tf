output "workspace" {
  description = "Active Terraform workspace (maps to environment)"
  value       = terraform.workspace
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — point your domain here"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.ec2_asg.autoscaling_group_name
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}

output "sns_alarm_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  value       = module.cloudwatch.sns_topic_arn
}
