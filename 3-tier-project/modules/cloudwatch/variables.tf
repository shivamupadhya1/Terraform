variable "name" {
  description = "Name prefix for CloudWatch resources"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used as a CloudWatch dimension (e.g. app/my-alb/abc123)"
  type        = string
}

variable "db_instance_id" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "scale_out_policy_arn" {
  description = "ARN of the ASG scale-out policy — triggered by CPU high alarm"
  type        = string
}

variable "scale_in_policy_arn" {
  description = "ARN of the ASG scale-in policy — triggered by CPU low alarm"
  type        = string
}

variable "cpu_high_threshold" {
  description = "CPU % threshold to trigger scale-out"
  type        = number
  default     = 70
}

variable "cpu_low_threshold" {
  description = "CPU % threshold to trigger scale-in"
  type        = number
  default     = 20
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx error count per minute to trigger alarm"
  type        = number
  default     = 10
}

variable "rds_cpu_threshold" {
  description = "RDS CPU % threshold to trigger alarm"
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold" {
  description = "RDS free storage bytes threshold — default is 5 GB"
  type        = number
  default     = 5368709120
}

variable "create_sns_topic" {
  description = "Create an SNS topic for alarm email notifications"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for alarm notifications (empty string skips subscription)"
  type        = string
  default     = ""
}

variable "sns_alarm_arns" {
  description = "List of existing SNS topic ARNs for alarms (used when create_sns_topic = false)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
