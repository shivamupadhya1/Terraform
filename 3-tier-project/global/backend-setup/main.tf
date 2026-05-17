# =============================================================================
# ONE-TIME BOOTSTRAP — Run this FIRST before any other Terraform apply
# Creates the S3 bucket and DynamoDB table that all workspaces use for
# remote state storage and state locking.
#
# Steps:
#   cd global/backend-setup
#   terraform init
#   terraform apply -var="state_bucket_name=<your-unique-bucket-name>"
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket — stores all Terraform state files (one per workspace)
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name      = var.state_bucket_name
    Purpose   = "terraform-remote-state"
    ManagedBy = "terraform-bootstrap"
  }
}

# Versioning — keeps every state revision so you can roll back
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption — state files contain sensitive data
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — state must never be public
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table — provides distributed state locking (prevents concurrent applies)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = var.lock_table_name
    Purpose   = "terraform-state-lock"
    ManagedBy = "terraform-bootstrap"
  }
}

# ---- Variables ----

variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state (e.g. acme-terraform-state-2024)"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

# ---- Outputs ----

output "state_bucket_name" {
  description = "S3 bucket name — copy this into root backend.tf"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name — copy this into root backend.tf"
  value       = aws_dynamodb_table.terraform_lock.name
}
