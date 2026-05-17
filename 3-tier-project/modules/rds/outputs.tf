output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}
