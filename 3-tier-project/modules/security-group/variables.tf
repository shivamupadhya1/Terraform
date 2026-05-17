variable "name" {
  description = "Name prefix for security group resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used to restrict SSH ingress to internal access only"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
