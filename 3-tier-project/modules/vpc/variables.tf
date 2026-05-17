variable "name" {
  description = "Name prefix for all VPC resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (ALB tier)"
  type        = list(string)
  default     = []
}

variable "private_app_subnets" {
  description = "CIDR blocks for private app-tier subnets (EC2/ASG)"
  type        = list(string)
  default     = []
}

variable "private_data_subnets" {
  description = "CIDR blocks for private data-tier subnets (RDS)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway (cost-saving for non-prod); prod uses one per AZ"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
