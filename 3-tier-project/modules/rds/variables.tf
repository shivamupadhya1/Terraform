variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of private data-tier subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "engine" {
  description = "Database engine (mysql, postgres)"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GB (set higher for prod)"
  type        = number
  default     = 100
}

variable "parameter_group_family" {
  description = "DB parameter group family (e.g. mysql8.0, postgres15)"
  type        = string
  default     = "mysql8.0"
}

variable "db_name" {
  description = "Name of the initial database schema"
  type        = string
}

variable "db_username" {
  description = "Master DB username"
  type        = string
}

variable "db_password" {
  description = "Master DB password — use AWS Secrets Manager or SSM Parameter Store in production"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ standby for high availability (enable for prod)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy — set false for production"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental RDS deletion — enable for prod"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
