variable "name" {
  description = "Name prefix for IAM resources"
  type        = string
}

variable "app_s3_bucket" {
  description = "S3 bucket name the application needs access to (empty string skips S3 policy)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
