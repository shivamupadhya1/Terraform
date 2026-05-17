output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.this.id
}

output "scale_out_policy_arn" {
  description = "ARN of the scale-out ASG policy (wired to CloudWatch CPU high alarm)"
  value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  description = "ARN of the scale-in ASG policy (wired to CloudWatch CPU low alarm)"
  value       = aws_autoscaling_policy.scale_in.arn
}
