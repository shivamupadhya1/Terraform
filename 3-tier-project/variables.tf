# ---- Project ----

variable "project_name" {
  description = "Short project name used as a prefix for all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

# ---- Network ----

variable "vpc_cidr" {
  description = "CIDR block for the VPC (use non-overlapping ranges per workspace)"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones — use 2 for dev/staging, 3 for prod"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets — one per AZ (ALB placement)"
  type        = list(string)
}

variable "private_app_subnets" {
  description = "CIDR blocks for private app-tier subnets — one per AZ (EC2/ASG)"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "CIDR blocks for private data-tier subnets — one per AZ (RDS)"
  type        = list(string)
}

# ---- EC2 / Auto Scaling Group ----

variable "ami_id" {
  description = "EC2 AMI ID — use AWS SSM Parameter Store to dynamically resolve the latest AMI"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro for dev, t3.small/medium for staging/prod)"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired" {
  description = "Desired number of EC2 instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_min" {
  description = "Minimum number of EC2 instances (floor for scale-in)"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of EC2 instances (ceiling for scale-out)"
  type        = number
  default     = 4
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "user_data" {
  description = "EC2 user data bootstrap script (plain text — encoded automatically)"
  type        = string
  default     = ""
}

# ---- ALB ----

variable "app_port" {
  description = "Port the application listens on (ALB target group)"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path for the ALB target group health check"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener — leave empty for dev/staging"
  type        = string
  default     = ""
}

# ---- RDS ----

variable "db_engine" {
  description = "RDS database engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage allocation in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum autoscaled RDS storage in GB"
  type        = number
  default     = 100
}

variable "db_parameter_group_family" {
  description = "RDS parameter group family (e.g. mysql8.0)"
  type        = string
  default     = "mysql8.0"
}

variable "db_name" {
  description = "Name of the initial database schema"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password — never commit real values; use -var or a secrets backend"
  type        = string
  sensitive   = true
}

# ---- IAM ----

variable "app_s3_bucket" {
  description = "S3 bucket name the app tier needs read/write access to (empty = no S3 policy)"
  type        = string
  default     = ""
}

# ---- CloudWatch ----

variable "cpu_high_threshold" {
  description = "CPU utilization % to trigger ASG scale-out"
  type        = number
  default     = 70
}

variable "cpu_low_threshold" {
  description = "CPU utilization % to trigger ASG scale-in"
  type        = number
  default     = 20
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications (empty = no subscription)"
  type        = string
  default     = ""
}
