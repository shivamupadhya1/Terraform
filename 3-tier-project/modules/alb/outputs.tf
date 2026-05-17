output "alb_arn" {
  description = "Full ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB — used as CloudWatch dimension (e.g. app/my-alb/abc123)"
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the ALB — point your Route53 record here"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route53 alias records)"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group — passed to the ASG for instance registration"
  value       = aws_lb_target_group.this.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}
