variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB is placed"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "URL path for the target group health check"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (empty string disables HTTPS)"
  type        = string
  default     = ""
}

variable "redirect_http_to_https" {
  description = "Redirect HTTP requests to HTTPS (enable for prod)"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Protect the ALB from accidental deletion (enable for prod)"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (empty string disables)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
