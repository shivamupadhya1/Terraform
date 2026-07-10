# Terraform Complete Interview Revision Guide
### For ~3 Years DevOps Experience | No Word Limit Edition

---

## TABLE OF CONTENTS

1. [Terraform Architecture & Core Concepts](#1-terraform-architecture--core-concepts)
2. [Terraform CLI Commands](#2-terraform-cli-commands)
3. [Providers](#3-providers)
4. [Resources](#4-resources)
5. [Variables (Input / Output / Local)](#5-variables-input--output--local)
6. [Data Sources](#6-data-sources)
7. [State Management](#7-state-management)
8. [Backends](#8-backends)
9. [Modules](#9-modules)
10. [Meta-Arguments](#10-meta-arguments)
11. [Expressions & Dynamic Blocks](#11-expressions--dynamic-blocks)
12. [Type Conversions: toset, tolist, tomap, tostring, tonumber, tobool](#12-type-conversions-toset-tolist-tomap-tostring-tonumber-tobool)
13. [Terraform Built-in Functions](#13-terraform-built-in-functions)
14. [Terraform Workspaces](#14-terraform-workspaces)
15. [Provisioners](#15-provisioners)
16. [Lifecycle Rules](#16-lifecycle-rules)
17. [Terraform Import](#17-terraform-import)
18. [Sensitive Data & Security](#18-sensitive-data--security)
19. [Terraform with CI/CD](#19-terraform-with-cicd)
20. [Terraform Cloud & Remote Execution](#20-terraform-cloud--remote-execution)
21. [Drift Detection & Refresh](#21-drift-detection--refresh)
22. [Real-World Patterns & Best Practices](#22-real-world-patterns--best-practices)
23. [Common Interview Questions & Answers](#23-common-interview-questions--answers)
24. [Scenario-Based Questions](#24-scenario-based-questions)

---

## 1. Terraform Architecture & Core Concepts

### What is Terraform?
- Infrastructure as Code (IaC) tool by HashiCorp
- Declarative — you describe **what** you want, Terraform figures out **how**
- Cloud-agnostic — supports AWS, Azure, GCP, Kubernetes, Datadog, etc.
- Uses **HCL (HashiCorp Configuration Language)** or JSON

### Terraform Execution Lifecycle

```
Write (.tf files)
     ↓
terraform init        → Downloads providers, initializes backend
     ↓
terraform validate    → Validates syntax & config
     ↓
terraform plan        → Compares state with desired config → creates execution plan
     ↓
terraform apply       → Executes the plan, creates/updates/destroys infra
     ↓
terraform destroy     → Tears down all managed infra
```

### Core Components

| Component     | Description |
|---------------|-------------|
| **Provider**  | Plugin that talks to a cloud/API (aws, azurerm, google) |
| **Resource**  | Infrastructure object to create/manage |
| **Data Source** | Read-only reference to existing infrastructure |
| **Variable**  | Input parameter for modules/configs |
| **Output**    | Export values after apply |
| **Local**     | Internal computed value (not exposed outside) |
| **Module**    | Reusable group of resources |
| **State**     | JSON file tracking real-world resource mappings |
| **Backend**   | Where state is stored (local, S3, Terraform Cloud) |

### Terraform vs Other IaC Tools

| Feature         | Terraform | CloudFormation | Pulumi | Ansible |
|-----------------|-----------|----------------|--------|---------|
| Language        | HCL/JSON  | YAML/JSON      | Python/TS/Go | YAML |
| Cloud-agnostic  | Yes       | No (AWS only)  | Yes    | Yes |
| State management| Yes       | Managed by AWS | Yes    | No |
| Declarative     | Yes       | Yes            | Yes    | No (Procedural) |
| Drift detection | Yes       | Yes            | Yes    | No |

---

## 2. Terraform CLI Commands

### Essential Commands

```bash
# Initialize working directory, download providers
terraform init

# Re-initialize and upgrade providers
terraform init -upgrade

# Validate configuration syntax
terraform validate

# Format code to canonical HCL style
terraform fmt
terraform fmt -recursive       # format all subdirectories

# Show planned changes (dry run)
terraform plan
terraform plan -out=tfplan     # save plan to file
terraform plan -var="env=prod"
terraform plan -var-file="prod.tfvars"
terraform plan -target=aws_vpc.main   # plan only specific resource
terraform plan -destroy        # plan for destruction

# Apply changes
terraform apply
terraform apply tfplan         # apply saved plan
terraform apply -auto-approve  # skip confirmation
terraform apply -target=aws_instance.web   # apply specific resource
terraform apply -var="instance_type=t3.micro"

# Destroy infrastructure
terraform destroy
terraform destroy -auto-approve
terraform destroy -target=aws_instance.web

# Show current state
terraform show
terraform show -json | jq .    # pipe to jq for formatting

# List resources in state
terraform state list

# Show specific resource in state
terraform state show aws_vpc.main

# Move resource in state (rename without destroy)
terraform state mv aws_instance.web aws_instance.app

# Remove resource from state (don't destroy, just untrack)
terraform state rm aws_instance.old

# Pull remote state to stdout
terraform state pull

# Push local state to remote backend
terraform state push terraform.tfstate

# Import existing resource into state
terraform import aws_vpc.main vpc-0abc1234
terraform import 'aws_instance.web[0]' i-1234567890abcdef0    # with count

# Refresh state (sync with real world)
terraform refresh

# Output values
terraform output
terraform output vpc_id
terraform output -json

# Graph dependency tree
terraform graph | dot -Tsvg > graph.svg

# Workspace management
terraform workspace list
terraform workspace new dev
terraform workspace select prod
terraform workspace show
terraform workspace delete staging

# Force unlock (use carefully!)
terraform force-unlock LOCK_ID

# Console - interactive expression evaluator
terraform console
> cidrsubnet("10.0.0.0/16", 8, 1)
> length(["a","b","c"])
```

### Less Common but Important

```bash
# Generate dependency graph
terraform graph

# Taint resource (mark for recreation on next apply) — deprecated in TF 0.15+
terraform taint aws_instance.web
terraform untaint aws_instance.web

# In TF 0.15+ use -replace flag instead of taint
terraform apply -replace="aws_instance.web"

# Providers info
terraform providers
terraform providers lock
terraform providers mirror ./mirror-dir

# Version info
terraform version

# Login to Terraform Cloud
terraform login
terraform logout

# Get (download module dependencies)
terraform get
terraform get -update
```

---

## 3. Providers

### Provider Block

```hcl
# Basic AWS provider
provider "aws" {
  region  = "us-east-1"
  profile = "my-aws-profile"
}

# With assume role (common in enterprise)
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/TerraformRole"
    session_name = "TerraformSession"
    external_id  = "UniqueExternalID"
  }
}

# Multiple provider configurations (aliased)
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}

# Use aliased provider in resource
resource "aws_instance" "ireland" {
  provider      = aws.eu_west
  ami           = "ami-12345678"
  instance_type = "t3.micro"
}
```

### Required Providers Block (versions.tf)

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"          # allow 5.x but not 6.x
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"           # exact version
    }
  }
}
```

### Version Constraint Operators

| Operator | Meaning |
|----------|---------|
| `= 1.5.0` | Exact version |
| `!= 1.5.0` | Not this version |
| `>= 1.5.0` | At least 1.5.0 |
| `<= 1.5.0` | At most 1.5.0 |
| `~> 1.5` | Any 1.x but not 2.x (pessimistic constraint) |
| `~> 1.5.0` | Any 1.5.x but not 1.6.x |
| `>= 1.0, < 2.0` | Version range |

---

## 4. Resources

### Resource Block Syntax

```hcl
resource "<PROVIDER>_<TYPE>" "<LOCAL_NAME>" {
  # Arguments
  argument1 = "value1"
  argument2 = var.some_variable

  # Nested block
  tags = {
    Name        = "my-resource"
    Environment = var.environment
  }
}
```

### Resource Addressing

```
<RESOURCE_TYPE>.<NAME>
<RESOURCE_TYPE>.<NAME>.<ATTRIBUTE>
<RESOURCE_TYPE>.<NAME>[INDEX]         # count
<RESOURCE_TYPE>.<NAME>["KEY"]         # for_each
module.<MODULE_NAME>.<RESOURCE_TYPE>.<NAME>
```

### Real Example (EC2)

```hcl
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    db_host = aws_db_instance.main.endpoint
    db_name = var.db_name
  }))

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-web"
    Role = "webserver"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami, user_data]
  }

  depends_on = [aws_db_instance.main]
}
```

---

## 5. Variables (Input / Output / Local)

### Input Variables

```hcl
# String variable
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

# Number variable
variable "instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1
}

# Boolean variable
variable "enable_deletion_protection" {
  type    = bool
  default = false
}

# List variable
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Map variable
variable "instance_types" {
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

# Object variable
variable "database_config" {
  type = object({
    instance_class    = string
    allocated_storage = number
    multi_az          = bool
    engine_version    = string
  })
  default = {
    instance_class    = "db.t3.medium"
    allocated_storage = 20
    multi_az          = false
    engine_version    = "8.0"
  }
}

# List of objects
variable "subnets" {
  type = list(object({
    cidr = string
    az   = string
    tier = string
  }))
}

# Any type (flexible, use sparingly)
variable "tags" {
  type    = any
  default = {}
}

# Sensitive variable (masked in logs)
variable "db_password" {
  type      = string
  sensitive = true
}

# Nullable (can be set to null explicitly)
variable "kms_key_id" {
  type     = string
  default  = null
  nullable = true
}
```

### Variable Precedence (highest → lowest)

1. `-var` CLI flag
2. `-var-file` CLI flag
3. `*.auto.tfvars` (alphabetical order)
4. `terraform.tfvars`
5. Environment variables (`TF_VAR_name`)
6. Default value in variable block

### Output Variables

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_public_ips" {
  description = "Public IPs of all instances"
  value       = aws_instance.web[*].public_ip
}

output "db_endpoint" {
  description = "Database endpoint (sensitive)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "subnet_ids" {
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
  }
}

# Depend on resource creation
output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  depends_on  = [aws_lb_listener.http]
}
```

### Local Values

```hcl
locals {
  # Simple computation
  prefix = "${var.project}-${var.environment}"

  # Derived from variables
  is_production = var.environment == "prod"

  # Map computed once and reused
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CreatedAt   = timestamp()
  }

  # Conditional
  instance_type = local.is_production ? "t3.large" : "t3.micro"

  # List operations
  all_subnets = concat(var.public_subnets, var.private_subnets)

  # Using functions
  bucket_name = lower(replace("${local.prefix}-assets", "_", "-"))

  # Computed CIDR blocks
  vpc_cidrs = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }
  vpc_cidr = local.vpc_cidrs[var.environment]
}
```

---

## 6. Data Sources

### Purpose
- Query existing infrastructure not managed by this Terraform config
- Read-only — never creates/modifies resources

```hcl
# Fetch latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Fetch existing VPC by tag
data "aws_vpc" "existing" {
  tags = {
    Name = "production-vpc"
  }
}

# Fetch caller identity (who is running terraform)
data "aws_caller_identity" "current" {}

# Fetch current region
data "aws_region" "current" {}

# Fetch all availability zones in region
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch Route53 zone
data "aws_route53_zone" "main" {
  name         = "example.com."
  private_zone = false
}

# Fetch SSM parameter
data "aws_ssm_parameter" "db_password" {
  name            = "/myapp/prod/db_password"
  with_decryption = true
}

# Fetch Secrets Manager secret
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "myapp/prod/db-credentials"
}

# Fetch IAM policy document
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "AllowS3Read"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

# Fetch existing subnet IDs
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  tags = {
    Tier = "private"
  }
}

# Read local file
data "local_file" "ssh_public_key" {
  filename = "${path.module}/keys/id_rsa.pub"
}

# Template file
data "template_file" "user_data" {
  template = file("${path.module}/templates/userdata.sh.tpl")
  vars = {
    db_host = aws_db_instance.main.endpoint
    app_env = var.environment
  }
}

# Usage
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnets.private.ids[0]
}
```

---

## 7. State Management

### What is Terraform State?
- JSON file (`terraform.tfstate`) that maps config to real-world resources
- Stores resource IDs, attributes, dependencies
- Required for: tracking resources, detecting drift, planning changes

### State File Structure (simplified)

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "uuid-here",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_vpc",
      "name": "main",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "vpc-0abc12345",
            "cidr_block": "10.0.0.0/16",
            "enable_dns_hostnames": true
          }
        }
      ]
    }
  ]
}
```

### State Commands

```bash
# List all resources
terraform state list

# Show single resource detail
terraform state show aws_vpc.main

# Rename resource in state (no destroy/create)
terraform state mv aws_instance.web aws_instance.app_server

# Move resource to child module
terraform state mv aws_vpc.main module.vpc.aws_vpc.this

# Remove from state (stops managing, doesn't destroy)
terraform state rm aws_instance.old

# Import existing resource into state
terraform import aws_vpc.main vpc-0abc12345

# Pull remote state
terraform state pull > backup.tfstate

# Replace state (dangerous!)
terraform state push backup.tfstate
```

### State Locking
- Prevents concurrent modifications
- DynamoDB lock for S3 backend
- Lock ID shown when locked
- Force unlock: `terraform force-unlock <LOCK_ID>` — use carefully!

### State Isolation Strategies

```
Strategy 1: Separate directories per environment
├── environments/
│   ├── dev/
│   │   └── main.tf  (has its own state)
│   ├── staging/
│   └── prod/

Strategy 2: Workspaces (single config, multiple states)
terraform workspace new dev
terraform workspace new prod

Strategy 3: Separate state files with -backend-config
terraform init -backend-config="key=prod/terraform.tfstate"
```

---

## 8. Backends

### Local Backend (default)

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

### S3 Backend (most common for AWS)

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "3-tier-app/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789:key/abc-123"
    
    # State locking with DynamoDB
    dynamodb_table = "terraform-state-lock"
    
    # Role to assume (cross-account)
    role_arn       = "arn:aws:iam::123456789012:role/TerraformRole"
    
    # Profile
    profile        = "terraform-admin"
  }
}
```

### DynamoDB Table for Locking (bootstrap)

```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}
```

### S3 Bucket for State (bootstrap)

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Remote Backend (Terraform Cloud)

```hcl
terraform {
  backend "remote" {
    organization = "my-org"
    workspaces {
      name = "my-workspace-prod"
    }
  }
}

# OR using cloud block (TF 1.1+)
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      tags = ["app=my-app", "env=prod"]
    }
  }
}
```

### Partial Backend Configuration

```hcl
# backend.tf
terraform {
  backend "s3" {
    # Only static values here
    region = "us-east-1"
  }
}

# Pass dynamic values at init time
terraform init \
  -backend-config="bucket=my-state-bucket" \
  -backend-config="key=myapp/prod/terraform.tfstate" \
  -backend-config="dynamodb_table=terraform-lock"
```

### Reading Remote State (Cross-Stack Reference)

```hcl
# Read state from another Terraform config
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use outputs from that state
resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.vpc.outputs.private_subnet_ids[0]
}
```

---

## 9. Modules

### Module Types
1. **Root module** — main working directory
2. **Child module** — called with `module` block
3. **Published module** — from Terraform Registry

### Module Sources

```hcl
# Local path
module "vpc" {
  source = "./modules/vpc"
}

# Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
}

# GitHub
module "vpc" {
  source = "github.com/myorg/terraform-modules//vpc"
}

# GitHub with branch/tag
module "vpc" {
  source = "github.com/myorg/terraform-modules//vpc?ref=v1.2.0"
}

# S3 bucket
module "vpc" {
  source = "s3::https://s3.amazonaws.com/my-bucket/modules/vpc.zip"
}

# Bitbucket
module "vpc" {
  source = "bitbucket.org/myorg/terraform-vpc"
}

# Generic Git
module "vpc" {
  source = "git::https://example.com/vpc.git?ref=v1.0"
}
```

### Module Structure (Best Practice)

```
modules/
└── vpc/
    ├── main.tf          # Resources
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    ├── versions.tf      # Required providers/versions
    ├── README.md        # Documentation
    └── examples/
        └── basic/
            ├── main.tf
            └── terraform.tfvars
```

### Calling a Module

```hcl
module "vpc" {
  source = "./modules/vpc"

  # Pass input variables
  name               = "${var.project}-${var.environment}"
  cidr_block         = var.vpc_cidr
  public_subnets     = var.public_subnet_cidrs
  private_app_subnets = var.private_app_subnet_cidrs
  private_data_subnets = var.private_data_subnet_cidrs
  azs                = data.aws_availability_zones.available.names
  tags               = local.common_tags

  # Pass providers explicitly (for multi-region)
  providers = {
    aws = aws.us_east
  }
}

# Access module outputs
resource "aws_security_group" "web" {
  vpc_id = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}
```

### Module Input Variables (variables.tf)

```hcl
variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "Must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

### Module Outputs (outputs.tf)

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}
```

### Module with count/for_each

```hcl
# Multiple instances of same module
module "app_server" {
  source   = "./modules/ec2"
  count    = var.server_count

  name          = "${var.project}-app-${count.index + 1}"
  subnet_id     = module.vpc.private_subnet_ids[count.index]
  instance_type = var.instance_type
}

# for_each with module
module "regional_vpc" {
  source   = "./modules/vpc"
  for_each = toset(["us-east-1", "eu-west-1", "ap-southeast-1"])

  region     = each.value
  cidr_block = "10.${index(["us-east-1","eu-west-1","ap-southeast-1"], each.value)}.0.0/16"
}
```

### Passing Providers to Modules

```hcl
# Root module
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr"
  region = "us-west-2"
}

module "primary_infra" {
  source = "./modules/infra"
  providers = {
    aws = aws.primary
  }
}

module "dr_infra" {
  source = "./modules/infra"
  providers = {
    aws = aws.dr
  }
}
```

---

## 10. Meta-Arguments

Meta-arguments apply to any resource or module block.

### count

```hcl
# Create 3 EC2 instances
resource "aws_instance" "web" {
  count         = 3
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index + 1}"
  }
}

# Conditional resource creation
resource "aws_cloudwatch_log_group" "app" {
  count             = var.enable_logging ? 1 : 0
  name              = "/aws/${var.project}/app"
  retention_in_days = 30
}

# Accessing count resources
output "instance_ids" {
  value = aws_instance.web[*].id
}

# Reference specific instance
resource "aws_eip" "web" {
  instance = aws_instance.web[0].id
}
```

### for_each

```hcl
# for_each with set of strings
resource "aws_iam_user" "developers" {
  for_each = toset(["alice", "bob", "charlie"])
  name     = each.value
}

# for_each with map
resource "aws_s3_bucket" "static" {
  for_each = {
    assets    = "my-app-assets"
    backups   = "my-app-backups"
    logs      = "my-app-logs"
  }
  bucket = each.value

  tags = {
    Purpose = each.key
  }
}

# for_each with list of objects (tomap trick)
variable "buckets" {
  default = [
    { name = "assets",   versioning = true  },
    { name = "backups",  versioning = true  },
    { name = "logs",     versioning = false },
  ]
}

resource "aws_s3_bucket" "app" {
  for_each = { for b in var.buckets : b.name => b }

  bucket = "${var.project}-${each.key}"

  dynamic "versioning" {
    for_each = each.value.versioning ? [1] : []
    content {
      enabled = true
    }
  }
}

# Accessing for_each resources
output "bucket_names" {
  value = { for k, v in aws_s3_bucket.app : k => v.id }
}
```

### count vs for_each

| Aspect | count | for_each |
|--------|-------|----------|
| Index | Integer (`count.index`) | Key/value (`each.key`, `each.value`) |
| State key | `resource[0]`, `resource[1]` | `resource["key"]` |
| Reorder impact | Destroys+recreates all following | Only affects changed key |
| Best for | Identical resources | Resources with distinct configs |
| Input type | `number` | `map` or `set` |

### depends_on

```hcl
# Explicit dependency when implicit doesn't exist
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # Terraform doesn't know EC2 needs this IAM role without explicit depends_on
  depends_on = [
    aws_iam_role_policy_attachment.app,
    aws_s3_bucket.app_config
  ]
}

# Module dependency
module "app" {
  source     = "./modules/app"
  depends_on = [module.vpc, module.database]
}
```

### provider

```hcl
# Use specific provider alias for a resource
resource "aws_s3_bucket" "eu_bucket" {
  provider = aws.eu_west
  bucket   = "my-eu-west-bucket"
}
```

### lifecycle

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  lifecycle {
    # Create new resource before destroying old one (zero-downtime)
    create_before_destroy = true

    # Don't destroy this resource (protects production!)
    prevent_destroy = true

    # Ignore changes to these attributes (don't trigger update plan)
    ignore_changes = [
      ami,
      tags["LastModified"],
      user_data,
    ]

    # Custom replacement condition (TF 1.2+)
    replace_triggered_by = [
      aws_launch_template.app.latest_version
    ]
  }
}

# Prevent accidental deletion of RDS
resource "aws_db_instance" "production" {
  lifecycle {
    prevent_destroy = true
  }
}
```

---

## 11. Expressions & Dynamic Blocks

### For Expressions

```hcl
# List comprehension
output "instance_ids" {
  value = [for instance in aws_instance.web : instance.id]
}

# Map comprehension
output "instance_map" {
  value = { for i, instance in aws_instance.web : "server-${i}" => instance.public_ip }
}

# Filter with if condition
output "running_instances" {
  value = [for i in aws_instance.web : i.id if i.instance_state == "running"]
}

# Nested for expression
locals {
  # Flatten: list of subnet CIDRs per AZ
  subnet_cidrs = [
    for az in var.azs : cidrsubnet(var.vpc_cidr, 8, index(var.azs, az))
  ]

  # Map of name → id from list of objects
  sg_name_to_id = {
    for sg in aws_security_group.all : sg.name => sg.id
  }
}

# for expression in resource argument
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in var.ingress_rules :
    "${rule.port}-${rule.protocol}" => rule
  }

  type        = "ingress"
  from_port   = each.value.port
  to_port     = each.value.port
  protocol    = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  security_group_id = aws_security_group.main.id
}
```

### Conditional Expressions

```hcl
# Ternary operator
locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  multi_az      = var.environment == "prod" ? true : false
  
  # Null coalescing pattern
  bucket_name = var.custom_bucket_name != null ? var.custom_bucket_name : "${var.project}-default"
}

# Conditional resource (count trick)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.public_subnets) : 0
  domain = "vpc"
}

# Conditional in variable
variable "db_port" {
  default = null
}

locals {
  # Use default if null
  db_port = var.db_port != null ? var.db_port : 5432
}
```

### Splat Expressions

```hcl
# Legacy splat (list only)
output "instance_ids" {
  value = aws_instance.web.*.id    # same as [for i in aws_instance.web : i.id]
}

# Full splat (works on any type, returns list)
output "instance_ids" {
  value = aws_instance.web[*].id
}

# Nested attribute
output "volume_ids" {
  value = aws_instance.web[*].root_block_device[0].volume_id
}
```

### Dynamic Blocks

```hcl
# Instead of repeating ingress blocks, use dynamic
resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = local.common_tags
}

# Dynamic block with iterator rename
resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_sgs
    iterator = sg_rule        # custom iterator name
    content {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [sg_rule.value]
      description     = "Allow from ${sg_rule.key}"
    }
  }
}

# Nested dynamic blocks
resource "aws_ecs_task_definition" "app" {
  family = "my-app"

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_config != null ? [volume.value.efs_config] : []
        content {
          file_system_id = efs_volume_configuration.value.fs_id
          root_directory = efs_volume_configuration.value.root_dir
        }
      }
    }
  }
}
```

### String Operations & Heredoc

```hcl
# String interpolation
locals {
  name = "${var.project}-${var.environment}-server"
}

# Heredoc (multi-line string)
resource "aws_iam_policy" "s3" {
  name   = "s3-access-policy"
  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": ["s3:GetObject"],
          "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
      ]
    }
  EOF
}

# templatefile (preferred over heredoc for complex templates)
resource "aws_instance" "web" {
  user_data = templatefile("${path.module}/scripts/userdata.sh.tpl", {
    db_host   = aws_db_instance.main.endpoint
    app_port  = var.app_port
    env       = var.environment
  })
}
```

---

## 12. Type Conversions: toset, tolist, tomap, tostring, tonumber, tobool

### Types in Terraform

```
Primitive:   string, number, bool
Complex:     list(TYPE), set(TYPE), map(TYPE)
Structural:  object({...}), tuple([...])
Special:     any, null
```

### toset()

```hcl
# Convert list to set (removes duplicates, loses order)
locals {
  raw_list = ["us-east-1a", "us-east-1b", "us-east-1a", "us-east-1c"]
  unique_azs = toset(local.raw_list)
  # Result: {"us-east-1a", "us-east-1b", "us-east-1c"}
}

# Use case: for_each requires set or map (not list)
resource "aws_iam_user" "devs" {
  for_each = toset(var.developer_names)   # convert list → set for for_each
  name     = each.value
}

# Use case: toset from variable
variable "environments" {
  default = ["dev", "staging", "prod"]
}

resource "aws_s3_bucket" "env_buckets" {
  for_each = toset(var.environments)
  bucket   = "${var.project}-${each.value}-bucket"
}

# toset removes duplicates
locals {
  subnets = toset(["subnet-1", "subnet-2", "subnet-1"])
  # Result: {"subnet-1", "subnet-2"}
}
```

### tolist()

```hcl
# Convert set to list (adds ordering, allows indexing)
locals {
  az_set  = toset(["us-east-1a", "us-east-1b", "us-east-1c"])
  az_list = tolist(local.az_set)
}

# Access by index (sets don't support indexing)
output "first_az" {
  value = tolist(data.aws_availability_zones.available.names)[0]
}

# Convert tuple to list
locals {
  mixed = ["a", "b", "c"]
  as_list = tolist(local.mixed)
}
```

### tomap()

```hcl
# Convert object to map(string)
locals {
  region_map = tomap({
    primary   = "us-east-1"
    secondary = "us-west-2"
    dr        = "eu-west-1"
  })
}

# tomap — all values must be same type
locals {
  tags = tomap({
    Name        = "my-resource"
    Environment = "prod"
    Team        = "platform"
  })
}

# for expression producing a map
locals {
  instance_ips = tomap({
    for idx, inst in aws_instance.web :
    "server-${idx}" => inst.private_ip
  })
}
```

### tostring()

```hcl
# Convert number/bool to string
locals {
  port_str     = tostring(8080)        # "8080"
  enabled_str  = tostring(true)        # "true"
  count_str    = tostring(var.count)   # useful for tags
}

# Use in tags (which require map(string))
resource "aws_instance" "web" {
  tags = {
    Port     = tostring(var.app_port)
    Replicas = tostring(var.replica_count)
  }
}
```

### tonumber()

```hcl
# Convert string to number
locals {
  port = tonumber("8080")            # 8080
  size = tonumber(var.disk_size_str) # when tfvars has string value
}

# Arithmetic
locals {
  doubled_port = tonumber(var.port_string) * 2
}
```

### tobool()

```hcl
# Convert string to bool
locals {
  enabled = tobool("true")    # true
  disabled = tobool("false")  # false
}

# Use case: env var input (env vars are strings)
variable "enable_monitoring" {
  type    = string
  default = "true"
}

locals {
  monitoring = tobool(var.enable_monitoring)
}
```

### Type Conversion Cheat Sheet

```hcl
# list → set (deduplicate)
toset(["a", "b", "a"])            # {"a", "b"}

# set → list (enable indexing)
tolist(toset(["a", "b"]))         # ["a", "b"] (order may vary)

# list/set → for_each
for_each = toset(var.names)
for_each = { for k in var.names : k => k }

# Convert all values of a map to strings
{ for k, v in var.tags : k => tostring(v) }

# Check and convert types safely
can(tonumber(var.value)) ? tonumber(var.value) : 0
```

---

## 13. Terraform Built-in Functions

### String Functions

```hcl
# format — string formatting like printf
format("Hello, %s!", "World")                # "Hello, World!"
format("%s-%s-%03d", "app", "prod", 3)       # "app-prod-003"

# formatlist — format each element of a list
formatlist("Hello, %s!", ["Alice", "Bob"])   # ["Hello, Alice!", "Hello, Bob!"]

# lower / upper / title
lower("HELLO WORLD")       # "hello world"
upper("hello world")       # "HELLO WORLD"
title("hello world")       # "Hello World"

# trim / trimspace / trimprefix / trimsuffix
trimspace("  hello  ")           # "hello"
trimprefix("foobar", "foo")      # "bar"
trimsuffix("foobar", "bar")      # "foo"
trim("##hello##", "#")           # "hello"

# replace
replace("hello world", " ", "-")    # "hello-world"
replace("abc 123", "/[0-9]+/", "NUM")  # "abc NUM" (regex)

# substr
substr("hello world", 0, 5)     # "hello"
substr("hello world", 6, -1)    # "world" (-1 = end)

# split / join
split(",", "a,b,c")             # ["a", "b", "c"]
join(", ", ["a", "b", "c"])     # "a, b, c"
join("-", [var.project, var.env])

# contains (for strings: use strcontains in TF 1.5+)
strcontains("hello world", "world")   # true (TF 1.5+)

# startswith / endswith (TF 1.3+)
startswith("hello world", "hello")   # true
endswith("hello world", "world")     # true

# regex / regexall
regex("[0-9]+", "abc123def456")         # "123"
regexall("[0-9]+", "abc123def456")      # ["123", "456"]

# can (check if expression evaluates without error)
can(regex("^[a-z]+$", var.name))        # true/false

# sensitive
sensitive("my-secret-value")

# nonsensitive (use carefully)
nonsensitive(var.db_password)
```

### Numeric Functions

```hcl
abs(-5)          # 5
ceil(1.2)        # 2
floor(1.8)       # 1
max(10, 20, 5)   # 20
min(10, 20, 5)   # 5
pow(2, 10)       # 1024
signum(-3)       # -1   (sign: -1, 0, or 1)
log(8, 2)        # 3    (log base 2 of 8)

# parseint — parse string as integer
parseint("FF", 16)    # 255  (hexadecimal)
parseint("10", 2)     # 2    (binary)
parseint("42", 10)    # 42   (decimal)
```

### Collection Functions

```hcl
# length
length([1, 2, 3])              # 3
length({"a" = 1, "b" = 2})    # 2
length("hello")                # 5

# lookup — get map value with default
lookup(var.instance_types, var.environment, "t3.micro")
lookup({"a" = 1, "b" = 2}, "c", 0)   # 0 (default)

# element — get element from list by index (wraps around)
element(["a", "b", "c"], 0)    # "a"
element(["a", "b", "c"], 4)    # "b" (wraps: 4 % 3 = 1)

# index — find index of element in list
index(["a", "b", "c"], "b")    # 1

# contains — check if list/set contains value
contains(["dev", "prod"], "dev")   # true
contains(["dev", "prod"], "test")  # false

# keys / values — extract map keys or values
keys({"a" = 1, "b" = 2})      # ["a", "b"]
values({"a" = 1, "b" = 2})    # [1, 2]

# merge — merge maps (later maps override earlier)
merge({"a" = 1}, {"b" = 2}, {"a" = 3})   # {"a" = 3, "b" = 2}
merge(local.common_tags, var.extra_tags)

# concat — join lists
concat(["a", "b"], ["c", "d"])     # ["a", "b", "c", "d"]
concat(var.public_subnets, var.private_subnets)

# flatten — flatten nested lists
flatten([["a", "b"], ["c", ["d", "e"]]])  # ["a", "b", "c", "d", "e"]

# distinct — remove duplicates from list (preserves order, unlike toset)
distinct(["a", "b", "a", "c"])    # ["a", "b", "c"]

# compact — remove null/empty strings from list
compact(["a", "", null, "b"])     # ["a", "b"]

# sort — sort list of strings alphabetically
sort(["c", "a", "b"])             # ["a", "b", "c"]

# reverse — reverse a list
reverse(["a", "b", "c"])          # ["c", "b", "a"]

# slice — extract portion of list
slice(["a", "b", "c", "d"], 1, 3)    # ["b", "c"] (start incl, end excl)

# zipmap — create map from keys and values lists
zipmap(["a", "b", "c"], [1, 2, 3])   # {"a" = 1, "b" = 2, "c" = 3}
# Real use case
zipmap(
  data.aws_availability_zones.available.names,
  aws_subnet.public[*].id
)

# chunklist — split list into chunks
chunklist(["a","b","c","d","e"], 2)   # [["a","b"],["c","d"],["e"]]

# setintersection / setunion / setsubtract
setintersection(["a","b","c"], ["b","c","d"])   # ["b","c"]
setunion(["a","b"], ["b","c"])                   # ["a","b","c"]
setsubtract(["a","b","c"], ["b"])                # ["a","c"]

# alltrue / anytrue (TF 1.0+)
alltrue([true, true, true])     # true
alltrue([true, false, true])    # false
anytrue([false, false, true])   # true
anytrue([false, false, false])  # false

# one — assert single element and return it
one(["value"])       # "value"
one([])              # null
one(["a", "b"])      # ERROR

# transpose — transpose a map of lists
transpose({"a" = ["1","2"], "b" = ["1","3"]})
# {"1" = ["a","b"], "2" = ["a"], "3" = ["b"]}

# matchkeys — filter one list by matching another
matchkeys(
  ["i-111","i-222","i-333"],    # values list
  ["web","db","web"],            # keys list
  ["web"]                        # filter keys
)
# ["i-111", "i-333"]
```

### Encoding Functions

```hcl
# base64 encode/decode
base64encode("Hello, World!")             # "SGVsbG8sIFdvcmxkIQ=="
base64decode("SGVsbG8sIFdvcmxkIQ==")     # "Hello, World!"

# Used frequently for user_data
user_data = base64encode(templatefile(...))

# URL encoding
urlencode("hello world&foo=bar")   # "hello+world%26foo%3Dbar"

# JSON encode/decode
jsonencode({"key" = "value", "num" = 42})
# {"key":"value","num":42}

jsondecode("{\"key\":\"value\"}")
# {"key" = "value"}

# Real use: IAM policy as HCL object → JSON
resource "aws_iam_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "*"
      }
    ]
  })
}

# YAML encode (TF 1.0+)
yamlencode({"key" = "value", "list" = [1, 2, 3]})

# CSV encode
csvdecode("name,age\nAlice,30\nBob,25")
# Returns list of maps: [{"name"="Alice","age"="30"},...]
```

### Filesystem Functions

```hcl
# file — read file contents as string
file("${path.module}/scripts/setup.sh")
file("~/.ssh/id_rsa.pub")

# filebase64 — read file as base64
filebase64("${path.module}/certs/cert.pem")

# filemd5 / filesha256 / filesha512 — file hash
filemd5("${path.module}/scripts/userdata.sh")
filesha256("${path.module}/lambda/function.zip")

# templatefile — render template with variables
templatefile("${path.module}/templates/nginx.conf.tpl", {
  server_name = var.domain_name
  backend_port = var.app_port
})

# Path references (built-in references, not functions)
path.module    # directory of current module
path.root      # root module directory
path.cwd       # current working directory
```

### Date & Time Functions

```hcl
# timestamp — current UTC timestamp (RFC 3339)
timestamp()   # "2024-01-15T10:30:00Z"

# timeadd — add duration to timestamp
timeadd(timestamp(), "24h")     # tomorrow
timeadd(timestamp(), "30m")     # 30 minutes from now
timeadd("2024-01-01T00:00:00Z", "8760h")  # 1 year later

# timecmp — compare timestamps (-1, 0, 1)
timecmp("2024-01-01T00:00:00Z", "2024-06-01T00:00:00Z")   # -1 (first is earlier)

# formatdate — format timestamp
formatdate("YYYY-MM-DD", timestamp())          # "2024-01-15"
formatdate("DD MMM YYYY hh:mm:ss", timestamp()) # "15 Jan 2024 10:30:00"
```

### Hash & Crypto Functions

```hcl
# md5
md5("hello")      # "5d41402abc4b2a76b9719d911017c592"

# sha1 / sha256 / sha512
sha256("hello")

# bcrypt (for password hashing)
bcrypt("my-password", 10)

# uuid — generate random UUID (changes every apply!)
uuid()

# uuidv5 — deterministic UUID from namespace + name (stable)
uuidv5("dns", "www.example.com")

# base64sha256 / base64sha512 — hash as base64
base64sha256(filebase64("lambda.zip"))   # for S3 etag checking
```

### IP Network Functions

```hcl
# cidrhost — compute host address in subnet
cidrhost("10.0.0.0/24", 1)      # "10.0.0.1"
cidrhost("10.0.0.0/24", 254)    # "10.0.0.254"
cidrhost("10.0.0.0/24", -1)     # "10.0.0.255" (last address)

# cidrnetmask — subnet mask
cidrnetmask("10.0.0.0/16")      # "255.255.0.0"

# cidrsubnet — compute subnet CIDR
cidrsubnet("10.0.0.0/16", 8, 0)   # "10.0.0.0/24" (add 8 bits, subnet 0)
cidrsubnet("10.0.0.0/16", 8, 1)   # "10.0.1.0/24"
cidrsubnet("10.0.0.0/16", 8, 255) # "10.0.255.0/24"

# cidrsubnets — compute multiple subnets at once (TF 0.13+)
cidrsubnets("10.0.0.0/16", 4, 4, 8, 4)
# ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/24", "10.0.33.0/20"]

# cidrrange (not built-in, but common pattern)
locals {
  # Create 3 /24 subnets from /16
  subnets = [
    for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  # ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

# Real use: dynamic subnet allocation
resource "aws_subnet" "public" {
  count             = length(var.azs)
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.azs[count.index]
  vpc_id            = aws_vpc.main.id
}
```

### Type Check Functions

```hcl
# can — check if expression evaluates without error
can(tostring(var.value))
can(regex("^[a-z]+$", var.name))

# try — evaluate and return first successful, or default
try(var.complex_object.nested_key, "default")
try(tonumber(var.maybe_number), 0)

# type conversion functions
tostring(var.number)
tonumber(var.string_num)
tobool("true")
tolist(toset(var.list))
toset(var.list_with_dupes)
tomap(var.object)
```

---

## 14. Terraform Workspaces

### What are Workspaces?
- Multiple state files in same backend with same config
- Each workspace has isolated state
- Default workspace: `default`
- Good for: multiple environments with same config, feature branches
- Not recommended for strong environment isolation (use separate dirs instead)

### Workspace Commands

```bash
terraform workspace list      # list all workspaces
terraform workspace new dev   # create and switch to 'dev'
terraform workspace select prod  # switch to 'prod'
terraform workspace show      # show current workspace name
terraform workspace delete staging  # delete workspace (must be empty)
```

### Using Workspace in Config

```hcl
# terraform.workspace returns current workspace name
locals {
  env = terraform.workspace   # "dev", "staging", "prod"
  
  instance_sizes = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }
  
  instance_type = local.instance_sizes[terraform.workspace]
}

resource "aws_instance" "app" {
  instance_type = local.instance_type

  tags = {
    Environment = terraform.workspace
  }
}

# Conditional based on workspace
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = terraform.workspace == "prod" ? 1 : 0
  # ...
}
```

### Workspace State File Locations

```
# Local backend
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate

# S3 backend
s3://bucket/path/to/terraform.tfstate          # default workspace
s3://bucket/env:/dev/path/to/terraform.tfstate # dev workspace
s3://bucket/env:/prod/path/to/terraform.tfstate # prod workspace
```

---

## 15. Provisioners

> **Warning**: Provisioners are a last resort. Use cloud-init, user_data, AWS SSM, or Ansible instead when possible.

### Types of Provisioners

#### local-exec

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  provisioner "local-exec" {
    # Runs on the machine running terraform
    command = "echo ${self.public_ip} >> inventory.txt"
  }

  # Run on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Destroying ${self.id}' >> audit.log"
  }

  # With environment variables
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.public_ip}, playbook.yml"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  # On failure
  provisioner "local-exec" {
    command     = "might-fail-command"
    on_failure  = continue   # or "fail" (default)
  }
}
```

#### remote-exec

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx"
    ]
  }

  # Run a script
  provisioner "remote-exec" {
    script = "${path.module}/scripts/setup.sh"
  }

  # Run multiple scripts
  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
      "${path.module}/scripts/configure.sh"
    ]
  }
}
```

#### file provisioner

```hcl
resource "aws_instance" "web" {
  # ...connection block...

  provisioner "file" {
    source      = "${path.module}/configs/nginx.conf"
    destination = "/etc/nginx/nginx.conf"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/app.conf.tpl", { port = var.port })
    destination = "/etc/app/config.conf"
  }

  # Copy directory
  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/opt/scripts"
  }
}
```

### Provisioner Triggers & Null Resource

```hcl
# null_resource — run provisioners without creating infra
resource "null_resource" "run_ansible" {
  # Triggers re-run when inventory changes
  triggers = {
    instance_ids = join(",", aws_instance.web[*].id)
    playbook_md5 = filemd5("${path.module}/playbook.yml")
  }

  provisioner "local-exec" {
    command = <<-EOT
      ansible-playbook \
        -i "${join(",", aws_instance.web[*].public_ip)}," \
        ${path.module}/playbook.yml
    EOT
  }

  depends_on = [aws_instance.web]
}
```

---

## 16. Lifecycle Rules

```hcl
resource "aws_instance" "production" {
  # ...

  lifecycle {
    # 1. Create new before destroying old (for zero-downtime)
    create_before_destroy = true
    
    # 2. Block any destroy operation (emergency guard)
    prevent_destroy = true
    
    # 3. Ignore changes to specific attributes
    ignore_changes = [
      tags["LastDeployment"],  # Updated by automation
      ami,                     # Don't update if AMI changes
      user_data,               # Don't recreate if user_data changes
    ]
    
    # 4. Trigger replacement when other resource changes (TF 1.2+)
    replace_triggered_by = [
      aws_launch_template.app.latest_version,
      null_resource.config_hash
    ]
    
    # 5. Custom condition check before creating (TF 1.2+)
    precondition {
      condition     = var.environment == "prod" ? var.instance_type != "t3.micro" : true
      error_message = "Production must not use t3.micro instances."
    }
    
    # 6. Custom condition check after creating (TF 1.2+)
    postcondition {
      condition     = self.availability_zone != ""
      error_message = "Instance must be in an AZ."
    }
  }
}
```

### Common Lifecycle Patterns

```hcl
# Zero-downtime replacement
resource "aws_security_group" "main" {
  lifecycle {
    create_before_destroy = true
  }
}

# Ignore auto-scaling changes
resource "aws_autoscaling_group" "app" {
  lifecycle {
    ignore_changes = [desired_capacity, min_size, max_size]
  }
}

# Protect production database
resource "aws_db_instance" "prod" {
  lifecycle {
    prevent_destroy = true
  }
}

# Prevent tag updates from triggering recreation
resource "aws_instance" "web" {
  lifecycle {
    ignore_changes = [tags]
  }
}
```

---

## 17. Terraform Import

### Import Existing Resources

```bash
# Basic import
terraform import aws_vpc.main vpc-0abc12345

# Import resource with index (count)
terraform import 'aws_subnet.public[0]' subnet-0abc123

# Import resource with for_each key
terraform import 'aws_subnet.private["us-east-1a"]' subnet-0def456

# Import module resource
terraform import 'module.vpc.aws_vpc.this' vpc-0abc12345
```

### Config-Driven Import (TF 1.5+)

```hcl
# import block in .tf file (no CLI needed!)
import {
  id = "vpc-0abc12345"
  to = aws_vpc.main
}

import {
  id = "i-1234567890abcdef0"
  to = aws_instance.web
}

# Then run:
# terraform plan    → shows import plan
# terraform apply   → imports and generates state
```

### Generate Config from Import (TF 1.5+)

```bash
# Add import block, then generate config
terraform plan -generate-config-out=generated.tf
# Terraform writes the resource block to generated.tf
```

### Import Workflow (Pre 1.5)

```bash
# 1. Write resource block in .tf (guess attributes)
# 2. Run import
terraform import aws_vpc.main vpc-0abc12345
# 3. Run plan to see differences
terraform plan
# 4. Adjust .tf file to match actual state
# 5. Run plan again until clean
```

---

## 18. Sensitive Data & Security

### Sensitive Variables

```hcl
variable "db_password" {
  type      = string
  sensitive = true
  # Masked in plan/apply output as "(sensitive value)"
}

output "db_connection_string" {
  value     = "postgresql://${var.db_user}:${var.db_password}@${aws_db_instance.main.endpoint}/mydb"
  sensitive = true  # Required if using sensitive inputs
}
```

### Secrets Management — Never Hardcode Secrets

```hcl
# Option 1: AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = "myapp/prod/rds-credentials"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_instance" "main" {
  password = local.db_creds.password
  username = local.db_creds.username
}

# Option 2: SSM Parameter Store
data "aws_ssm_parameter" "db_password" {
  name            = "/myapp/prod/db_password"
  with_decryption = true
}

# Option 3: Vault Provider
provider "vault" {
  address = "https://vault.example.com"
}

data "vault_generic_secret" "db" {
  path = "secret/myapp/database"
}

# Option 4: Environment variables (for provider auth)
# TF_VAR_db_password=mysecret terraform apply
```

### State File Security

```hcl
# S3 backend with encryption
terraform {
  backend "s3" {
    bucket     = "my-terraform-state"
    key        = "app/prod/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true           # Encrypt state at rest
    kms_key_id = "arn:aws:kms:..."  # Customer managed key
  }
}
```

### Security Best Practices

```hcl
# 1. Never commit .tfstate files — add to .gitignore
# .gitignore:
# *.tfstate
# *.tfstate.backup
# .terraform/
# *.tfvars  (if contains secrets)

# 2. Use IAM roles, not access keys
provider "aws" {
  # Don't put access_key/secret_key here!
  # Use IAM roles, profiles, or environment variables
  region = "us-east-1"
}

# 3. Least privilege IAM for Terraform
# Only grant permissions Terraform actually needs

# 4. Enable state versioning (S3)
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

# 5. Validate with custom conditions
variable "allowed_instance_types" {
  type    = list(string)
  default = ["t3.micro", "t3.small", "t3.medium"]
}

variable "instance_type" {
  validation {
    condition     = contains(var.allowed_instance_types, var.instance_type)
    error_message = "Instance type not in allowed list."
  }
}
```

---

## 19. Terraform with CI/CD

### GitHub Actions Workflow

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  pull_request:
    branches: [main]
    paths: ['terraform/**']

env:
  TF_VERSION: '1.5.0'
  AWS_REGION: 'us-east-1'

jobs:
  terraform-plan:
    name: Plan
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # For OIDC
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
          aws-region: ${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -out=tfplan -no-color
        working-directory: terraform/

      - name: Post Plan to PR
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan\n\`\`\`\n${{ steps.plan.outputs.stdout }}\n\`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  terraform-apply:
    name: Apply
    runs-on: ubuntu-latest
    needs: terraform-plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production

    steps:
      - uses: actions/checkout@v4
      - name: Setup AWS + Terraform...
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### GitLab CI Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - plan
  - apply
  - destroy

variables:
  TF_ROOT: ${CI_PROJECT_DIR}/terraform
  TF_VAR_environment: ${CI_ENVIRONMENT_NAME}

default:
  image:
    name: hashicorp/terraform:1.5.0
    entrypoint: [""]

cache:
  key: "${CI_COMMIT_REF_SLUG}"
  paths:
    - ${TF_ROOT}/.terraform

validate:
  stage: validate
  script:
    - cd ${TF_ROOT}
    - terraform init -backend=false
    - terraform validate
    - terraform fmt -check

plan:
  stage: plan
  script:
    - cd ${TF_ROOT}
    - terraform init
    - terraform plan -out=plan.cache
  artifacts:
    paths:
      - ${TF_ROOT}/plan.cache

apply:
  stage: apply
  script:
    - cd ${TF_ROOT}
    - terraform apply plan.cache
  environment:
    name: production
  when: manual
  only:
    - main
```

### Terragrunt (DRY Terraform)

```hcl
# terragrunt.hcl (root)
remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# environments/prod/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  cidr_block   = "10.2.0.0/16"
  environment  = "prod"
}

# Run all modules
# terragrunt run-all plan
# terragrunt run-all apply
```

---

## 20. Terraform Cloud & Remote Execution

### Terraform Cloud Features
- Remote state storage
- Remote plan/apply execution
- Team access controls
- Sentinel policy as code
- Cost estimation
- VCS integration (GitHub, GitLab)

### Sentinel Policy (Enterprise)

```hcl
# policy.sentinel
import "tfplan/v2" as tfplan

# Require all EC2 instances to be t3.* family
main = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is "aws_instance" and rc.mode is "managed" implies
      rc.change.after.instance_type matches "^t3\."
  }
}

# Require tags
require_tags = rule {
  all tfplan.resource_changes as _, rc {
    rc.mode is "managed" implies
      rc.change.after.tags contains "Environment" and
      rc.change.after.tags contains "Project"
  }
}
```

---

## 21. Drift Detection & Refresh

### What is Drift?
- Difference between Terraform state and real infrastructure
- Caused by: manual changes in console, other tools, auto-scaling, etc.

### Detecting Drift

```bash
# Refresh state from real-world (deprecated in TF 0.15.4+)
terraform refresh

# Plan with refresh (default behavior in TF 1.0+)
terraform plan    # always refreshes before planning

# Plan WITHOUT refreshing (faster, use with care)
terraform plan -refresh=false

# Show full diff including refreshed state
terraform plan -detailed-exitcode
# Exit code 0 = no changes, 1 = error, 2 = changes present

# Detect drift only (no apply)
terraform plan -detailed-exitcode ; echo "Exit: $?"
```

### Handling Drift

```hcl
# Option 1: Import the manually created resource
terraform import aws_security_group.extra sg-0123456789

# Option 2: Add to ignore_changes to accept drift
lifecycle {
  ignore_changes = [tags, desired_capacity]
}

# Option 3: Let Terraform overwrite (just run apply)
terraform apply   # Terraform will revert manual changes

# Option 4: Remove from state (accept manual changes)
terraform state rm aws_security_group.extra
```

---

## 22. Real-World Patterns & Best Practices

### Project Structure (3-tier app)

```
infrastructure/
├── global/
│   ├── iam/
│   │   └── main.tf              # IAM roles/policies shared across envs
│   └── s3/
│       └── main.tf              # State bucket, shared S3
├── modules/
│   ├── vpc/
│   ├── ec2/
│   ├── rds/
│   ├── alb/
│   ├── security-group/
│   └── cloudwatch/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── README.md
```

### Naming Conventions

```hcl
# Resource naming: {project}-{environment}-{resource}-{suffix}
locals {
  prefix = "${var.project}-${var.environment}"
  
  names = {
    vpc              = "${local.prefix}-vpc"
    public_subnet    = "${local.prefix}-public"
    private_subnet   = "${local.prefix}-private"
    alb              = "${local.prefix}-alb"
    ec2              = "${local.prefix}-app"
    rds              = "${local.prefix}-db"
  }
}
```

### Tagging Strategy

```hcl
locals {
  mandatory_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "github.com/org/repo"
    Owner       = var.team
    CostCenter  = var.cost_center
  }
  
  # Merge mandatory + optional tags
  all_tags = merge(local.mandatory_tags, var.additional_tags)
}

# Apply to every resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.all_tags, { Name = "${local.prefix}-vpc" })
}
```

### Conditional Resources Pattern

```hcl
# Enable/disable features via boolean variable
variable "enable_nat_gateway"      { type = bool; default = false }
variable "enable_vpn_gateway"      { type = bool; default = false }
variable "enable_bastion"          { type = bool; default = false }
variable "single_nat_gateway"      { type = bool; default = false }

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

### DRY with for_each Map

```hcl
# Instead of repeating similar resources, use for_each
locals {
  security_group_rules = {
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ssh = {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = [var.office_cidr]
    }
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each    = local.security_group_rules
  type        = "ingress"
  from_port   = each.value.port
  to_port     = each.value.port
  protocol    = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  security_group_id = aws_security_group.web.id
  description = "Allow ${each.key}"
}
```

### Flatten Pattern (complex nested loops)

```hcl
# Create security group rules from complex structure
variable "vpc_configs" {
  default = {
    "vpc-a" = {
      cidr   = "10.0.0.0/16"
      ports  = [80, 443, 8080]
    }
    "vpc-b" = {
      cidr   = "10.1.0.0/16"
      ports  = [80, 9090]
    }
  }
}

locals {
  # Flatten: one entry per vpc+port combination
  sg_rules = flatten([
    for vpc_name, vpc in var.vpc_configs : [
      for port in vpc.ports : {
        key  = "${vpc_name}-${port}"
        cidr = vpc.cidr
        port = port
      }
    ]
  ])

  # Convert to map for for_each
  sg_rules_map = { for rule in local.sg_rules : rule.key => rule }
}

resource "aws_security_group_rule" "allow" {
  for_each    = local.sg_rules_map
  type        = "ingress"
  from_port   = each.value.port
  to_port     = each.value.port
  protocol    = "tcp"
  cidr_blocks = [each.value.cidr]
  security_group_id = aws_security_group.main.id
}
```

### Module Composition Pattern

```hcl
# Root main.tf wiring modules together
module "vpc" {
  source     = "./modules/vpc"
  name       = local.prefix
  cidr_block = var.vpc_cidr
  azs        = data.aws_availability_zones.available.names
  tags       = local.common_tags
}

module "security_groups" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  vpc_cidr      = var.vpc_cidr
  allowed_cidrs = var.allowed_management_cidrs
  tags          = local.common_tags
}

module "rds" {
  source             = "./modules/rds"
  subnet_ids         = module.vpc.private_data_subnet_ids
  security_group_ids = [module.security_groups.db_sg_id]
  db_name            = var.db_name
  db_password        = var.db_password
  tags               = local.common_tags
}

module "ec2" {
  source             = "./modules/ec2"
  subnet_ids         = module.vpc.private_app_subnet_ids
  security_group_ids = [module.security_groups.app_sg_id]
  db_endpoint        = module.rds.endpoint
  db_name            = var.db_name
  tags               = local.common_tags
}

module "alb" {
  source             = "./modules/alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.alb_sg_id]
  target_instance_ids = module.ec2.instance_ids
  tags               = local.common_tags
}
```

---

## 23. Common Interview Questions & Answers

### Q1: What is the difference between `count` and `for_each`?

**Answer:**
- `count` creates resources based on a number, referenced by integer index (`[0]`, `[1]`)
- `for_each` iterates over a map or set, referenced by string key (`["name"]`)
- Key difference: if you remove item from middle of `count` list, all subsequent resources get destroyed and recreated (index shift). With `for_each`, only the removed key is destroyed
- Use `for_each` when resources have unique identities; use `count` for truly identical resources

---

### Q2: What is Terraform state and why is it important?

**Answer:**
- JSON file that maps Terraform config to real infrastructure
- Stores resource IDs, metadata, attribute values
- Used to determine what changes are needed (plan)
- Enables dependency tracking
- Should be stored remotely (S3) and locked (DynamoDB) for team use
- Contains sensitive data — encrypt at rest and in transit

---

### Q3: How do you handle secrets in Terraform?

**Answer:**
- Never hardcode secrets in .tf files or commit to Git
- Use `sensitive = true` on variables to mask in output
- Retrieve from AWS Secrets Manager / SSM Parameter Store via data sources
- Use Vault provider for HashiCorp Vault
- Pass via `TF_VAR_` environment variables in CI/CD
- State file stores secrets in plaintext — encrypt S3 bucket with KMS

---

### Q4: What is `terraform taint` and when would you use it?

**Answer:**
- Marks a resource for recreation on next apply (deprecated in TF 0.15+)
- Use when resource is in bad state but Terraform thinks it's fine
- Modern replacement: `terraform apply -replace="resource.name"`
- Example: EC2 instance became unresponsive, need to recreate it

---

### Q5: Explain `create_before_destroy` lifecycle

**Answer:**
- By default Terraform destroys old then creates new (can cause downtime)
- `create_before_destroy = true` creates new resource first, then destroys old
- Useful for: security groups, load balancers, anything with dependencies
- Caveat: both resources exist temporarily — naming conflicts possible
- Often combined with `random_id` or name prefix strategies

---

### Q6: What are Terraform modules and what are the benefits?

**Answer:**
- Reusable, encapsulated group of resources with defined inputs/outputs
- Benefits: DRY (Don't Repeat Yourself), consistency across environments, abstraction, testability
- Types: local modules (./modules/), Registry modules, Git-sourced modules
- Best practice: version modules, document inputs/outputs, follow standard structure

---

### Q7: How does `terraform plan` work internally?

**Answer:**
1. Reads current state file
2. Refreshes state by querying provider APIs (real-world check)
3. Reads desired configuration from .tf files
4. Computes diff: what to create, update, destroy
5. Shows execution plan (no changes made)
6. Returns exit code: 0 (no changes) or 2 (changes pending)

---

### Q8: What is the difference between `depends_on` and implicit dependencies?

**Answer:**
- Implicit: Terraform auto-detects when you reference one resource in another (`subnet_id = aws_subnet.main.id`)
- Explicit `depends_on`: needed when dependency exists but isn't expressed in config (e.g., EC2 needs IAM role that's not referenced in resource block)
- Use `depends_on` sparingly — only when implicit dependency can't be expressed

---

### Q9: What is `terraform refresh` and is it still needed?

**Answer:**
- Syncs state file with real-world infrastructure
- In TF 1.0+, `terraform plan` automatically does a refresh
- `terraform refresh` as standalone command is deprecated
- Use `terraform plan -refresh=false` to skip refresh for faster plans
- `terraform plan -refresh-only` in TF 1.1+ to see drift without planning changes

---

### Q10: Explain `toset()` and when you'd use it

**Answer:**
- Converts list to set (removes duplicates, loses ordering)
- Common use: converting a `list(string)` variable to set for `for_each`
  - `for_each` requires `map` or `set`, not `list`
- `toset(["dev", "staging", "prod", "dev"])` → `{"dev", "staging", "prod"}`
- Sets are unordered, don't support index access

---

### Q11: What is a Terraform backend and what backends are commonly used?

**Answer:**
- Where state file is stored and how operations are executed
- Local backend: state on disk, no locking (not for teams)
- S3 backend: most common for AWS teams — remote state + DynamoDB locking
- Remote (Terraform Cloud): state + remote execution + collaboration features
- Other: Azure Blob Storage, GCS, Consul, HTTP

---

### Q12: How do you manage multiple environments in Terraform?

**Answer:**
- **Approach 1 — Separate directories**: `environments/dev/`, `environments/prod/` each with own state. Most isolation, most repetition.
- **Approach 2 — Workspaces**: Single config, multiple state files. Less isolation, same config assumptions for all envs.
- **Approach 3 — Terragrunt**: Wrapper that handles DRY backends and variable passing. Most scalable.
- Best practice: separate state per environment, use modules for shared code

---

### Q13: What is `dynamic` block and when should you use it?

**Answer:**
- Generates repeated nested blocks from a collection
- Used when number of nested blocks is variable (e.g., ingress rules, lifecycle hooks)
- Alternative to using multiple identical blocks
- Syntax: `dynamic "BLOCK_NAME" { for_each = ...; content { ... } }`
- Don't overuse — can reduce readability

---

### Q14: How do you import existing infrastructure?

**Answer:**
- Old way (pre 1.5): Write resource block, run `terraform import resource.name ID`
- New way (TF 1.5+): Use `import {}` block in config, run `terraform plan/apply`
- TF 1.5+ can also generate config with `terraform plan -generate-config-out=file.tf`
- After import: always run `terraform plan` to verify no unintended changes

---

### Q15: What happens when you run `terraform destroy`?

**Answer:**
1. Reads state to find all managed resources
2. Runs a plan to destroy all resources
3. Shows destruction plan (shows what will be deleted)
4. On confirmation, destroys resources in reverse dependency order
5. Clears state file
- `prevent_destroy = true` in lifecycle will block this
- `-target` flag can destroy specific resources only

---

### Q16: Explain `templatefile()` function

**Answer:**
- Reads a template file and renders it with provided variables
- Better than heredoc for long/complex scripts
- Template uses `${variable}` syntax
- Common use: user_data scripts, nginx configs, k8s manifests
- Returns string

```hcl
user_data = templatefile("scripts/userdata.sh.tpl", {
  db_host = aws_db_instance.main.endpoint
  app_env = var.environment
})
```

---

### Q17: What is the `.terraform.lock.hcl` file?

**Answer:**
- Dependency lock file created by `terraform init`
- Records exact provider versions and their checksums
- Ensures reproducible builds (same provider version for whole team)
- **Should be committed to Git** (unlike `.terraform/` directory)
- Update with `terraform init -upgrade` to get newer versions

---

### Q18: How do you share outputs between Terraform configurations?

**Answer:**
- Use `terraform_remote_state` data source
- One config outputs values, another reads them via state
- Requires: same backend, correct path, appropriate permissions
- Alternative: Use SSM Parameter Store or Consul for loose coupling

---

### Q19: What is `merge()` function and common use cases?

**Answer:**
- Merges multiple maps into one; later maps override earlier for duplicate keys
- Most common use: merging tags
```hcl
tags = merge(
  local.common_tags,           # base tags
  var.extra_tags,              # caller-provided tags
  { Name = "my-resource" }     # resource-specific override
)
```

---

### Q20: Explain Terraform's execution order

**Answer:**
- Terraform builds a dependency graph from resource references
- Resources with no dependencies are created in parallel (up to provider limits)
- Resources with dependencies wait for dependencies to complete
- Destruction happens in reverse order
- `depends_on` adds explicit edges to this graph
- `terraform graph` visualizes this as DOT format

---

## 24. Scenario-Based Questions

### Scenario 1: Production RDS accidentally deleted

```bash
# Step 1: Panic prevention — check if RDS has automated backups
# Step 2: Restore from snapshot
# Step 3: Import into Terraform state
terraform import aws_db_instance.main <new-db-identifier>

# Prevention:
resource "aws_db_instance" "main" {
  lifecycle {
    prevent_destroy = true    # Would have prevented deletion!
  }
  deletion_protection = true  # AWS-level protection
  skip_final_snapshot = false # Ensure snapshot on delete
}
```

---

### Scenario 2: Someone manually modified a resource in AWS console — now plan shows unexpected changes

```bash
# Option 1: Let Terraform override (recommended for immutable infra)
terraform plan   # See what changed
terraform apply  # Revert manual change

# Option 2: Accept the manual change (update state to match)
terraform refresh  # or:
terraform plan -refresh-only
terraform apply -refresh-only  # Update state without changing infra

# Option 3: Ignore the attribute going forward
lifecycle {
  ignore_changes = [tags]
}
```

---

### Scenario 3: Need to rename a resource without destroying it

```bash
# Move in state
terraform state mv aws_instance.web aws_instance.application_server

# Or if moving to a module
terraform state mv aws_vpc.main module.vpc.aws_vpc.this

# Then update .tf file to match new name
# Run plan to verify no destroy/create planned
```

---

### Scenario 4: Adding a new AZ to existing multi-AZ deployment

```hcl
# If using count (DANGEROUS — causes recreation of all following resources)
variable "azs" {
  default = ["us-east-1a", "us-east-1b"]  # adding "us-east-1c" shifts indices!
}
resource "aws_subnet" "private" {
  count = length(var.azs)  # count.index: 0,1 → 0,1,2 (index 2 is new, 0&1 unchanged)
}

# If using for_each (SAFE — only new key is created)
resource "aws_subnet" "private" {
  for_each = toset(var.azs)     # keys: "us-east-1a", "us-east-1b" → add "us-east-1c"
}
# Adding new AZ only creates new subnet, doesn't touch existing
```

---

### Scenario 5: Circular dependency error

```
Error: Cycle: aws_security_group.a → aws_security_group.b → aws_security_group.a
```

```hcl
# Problem: SG-A references SG-B, SG-B references SG-A
# Solution: Use aws_security_group_rule as separate resources

resource "aws_security_group" "app" { ... }
resource "aws_security_group" "db" { ... }

# Add rules separately (breaks the cycle)
resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}
```

---

### Scenario 6: State lock stuck (someone's apply crashed)

```bash
# Check lock info
terraform plan  # Will show lock ID if locked

# Force unlock (verify no one is actually running terraform first!)
terraform force-unlock <LOCK_ID>

# For DynamoDB lock stuck:
# Manually delete item from DynamoDB table where LockID = "bucket/key"
# AWS Console → DynamoDB → terraform-state-lock table → Delete item
```

---

### Scenario 7: Migrate state from local to S3

```bash
# 1. Create S3 bucket and DynamoDB table
# (create resources manually or with separate terraform)

# 2. Add backend config to main.tf
# terraform {
#   backend "s3" {
#     bucket = "..."
#     key    = "..."
#     region = "us-east-1"
#   }
# }

# 3. Re-initialize (Terraform will detect backend change and offer to migrate)
terraform init
# Terraform will ask: "Do you want to copy existing state?"
# Answer: yes

# 4. Verify migration
terraform state list   # Should show same resources
```

---

### Key Terraform Files Reference

| File | Purpose |
|------|---------|
| `main.tf` | Primary resources |
| `variables.tf` | Input variable declarations |
| `outputs.tf` | Output value declarations |
| `locals.tf` | Local value computations |
| `providers.tf` | Provider configurations |
| `versions.tf` | Required versions constraints |
| `backend.tf` | Backend configuration |
| `data.tf` | Data source definitions |
| `terraform.tfvars` | Variable values (not secrets) |
| `*.auto.tfvars` | Auto-loaded variable values |
| `.terraform.lock.hcl` | Provider dependency lock (commit this!) |
| `terraform.tfstate` | State file (NEVER commit this!) |

---

### Quick Reference: Built-in Function Categories

| Category | Key Functions |
|----------|--------------|
| **String** | `format`, `lower`, `upper`, `trim`, `split`, `join`, `replace`, `regex`, `substr` |
| **Numeric** | `abs`, `ceil`, `floor`, `max`, `min`, `pow`, `parseint` |
| **Collection** | `length`, `lookup`, `element`, `keys`, `values`, `merge`, `concat`, `flatten`, `distinct`, `compact`, `sort`, `zipmap` |
| **Encoding** | `base64encode`, `jsonencode`, `jsondecode`, `yamlencode`, `urlencode` |
| **Filesystem** | `file`, `filebase64`, `filemd5`, `templatefile` |
| **Date/Time** | `timestamp`, `timeadd`, `formatdate` |
| **Hash** | `md5`, `sha256`, `bcrypt`, `uuid`, `uuidv5` |
| **IP Network** | `cidrhost`, `cidrnetmask`, `cidrsubnet`, `cidrsubnets` |
| **Type** | `tostring`, `tonumber`, `tobool`, `toset`, `tolist`, `tomap`, `can`, `try` |

---

### Terraform Cheat Sheet: Common Patterns

```hcl
# 1. Conditional resource creation
count = var.enable_feature ? 1 : 0

# 2. Environment-based sizing
instance_type = lookup(var.instance_sizes, var.environment, "t3.micro")

# 3. Safe null handling
value = var.custom_value != null ? var.custom_value : local.default_value

# 4. Merge tags
tags = merge(local.common_tags, { Name = local.resource_name })

# 5. CIDR subnet calculation
cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)

# 6. for_each from variable list
for_each = toset(var.names)

# 7. for_each from list of objects
for_each = { for item in var.items : item.name => item }

# 8. Flatten nested structure
local.flat = flatten([for k, v in var.map : [for i in v.list : { key=k, val=i }]])

# 9. Base64 encode user_data
user_data = base64encode(templatefile("script.sh.tpl", local.template_vars))

# 10. JSON encode IAM policy
policy = jsonencode({ Version="2012-10-17", Statement=[{...}] })

# 11. Read and hash file (for change detection)
triggers = { hash = filesha256("${path.module}/script.sh") }

# 12. Dynamic block from variable
dynamic "ingress" {
  for_each = var.ingress_rules
  content { from_port = ingress.value.port ... }
}

# 13. Access count resources as list
instance_ids = aws_instance.web[*].id

# 14. String formatting with padding
name = format("server-%03d", count.index + 1)  # server-001, server-002

# 15. Try with default
value = try(jsondecode(var.json_string).key, "default")
```

---

*This guide covers Terraform concepts from fundamentals to advanced patterns for ~3 years of DevOps experience. Practice the scenario questions and make sure you can write code live during interviews.*

*Last updated: 2026 | Terraform 1.5+ syntax*
