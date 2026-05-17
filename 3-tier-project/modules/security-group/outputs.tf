output "alb_sg_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "Security group ID for the EC2 web/app tier"
  value       = aws_security_group.web.id
}

output "rds_sg_id" {
  description = "Security group ID for the RDS data tier"
  value       = aws_security_group.rds.id
}
