variable "name" {
  description = "Name prefix for ASG and launch template resources"
  type        = string
}

variable "ami_id" {
  description = "Amazon Machine Image ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to EC2 instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs to register instances with"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for EC2 instances (for SSM, CloudWatch)"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 4
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "user_data" {
  description = "Base64-encoded user data script for instance bootstrapping"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
