# Production-Grade 3-Tier AWS Architecture — Terraform

A fully modular, workspace-driven Terraform project that provisions a production-ready
3-tier AWS architecture. Built to demonstrate real-world DevOps engineering practices.

---

## Architecture Overview

```
Internet
   │
   ▼
[ALB] ── Public Subnets (Tier 1)
   │
   ▼
[EC2 Auto Scaling Group] ── Private App Subnets (Tier 2)
   │
   ▼
[RDS MySQL] ── Private Data Subnets (Tier 3, no internet route)
```

| Layer | Resource | Description |
|-------|----------|-------------|
| Networking | VPC, Subnets, IGW, NAT | 3-tier isolation across multi-AZ |
| Load Balancing | ALB + Target Group | HTTP/HTTPS, health checks |
| Compute | EC2 Launch Template + ASG | Rolling updates, IMDSv2 enforced |
| Database | RDS MySQL | Encrypted, Multi-AZ in prod |
| Security | IAM Roles + SGs | Least-privilege, SG chaining |
| Observability | CloudWatch Alarms + Dashboard | Auto-scaling triggers, SNS alerts |
| State | S3 + DynamoDB | Remote state + distributed locking |

---

## Project Structure

```
.
├── main.tf                        # Root: wires all modules together
├── variables.tf                   # All input variable definitions
├── outputs.tf                     # Key outputs (ALB DNS, RDS endpoint, etc.)
├── providers.tf                   # AWS provider with default_tags
├── versions.tf                    # Terraform + provider version pins
├── backend.tf                     # S3 remote backend + DynamoDB locking
│
├── modules/
│   ├── vpc/                       # VPC, subnets (3 tiers), IGW, NAT, route tables
│   ├── security-group/            # ALB SG → Web SG → RDS SG (chained, least-privilege)
│   ├── ec2/                       # Launch Template + ASG + scale policies
│   ├── alb/                       # ALB, Target Group, HTTP/HTTPS listeners
│   ├── rds/                       # RDS instance, subnet group, parameter group
│   ├── iam/                       # EC2 IAM role, SSM + CloudWatch policies
│   └── cloudwatch/                # Alarms, SNS topic, dashboard
│
├── global/
│   └── backend-setup/             # One-time S3 bucket + DynamoDB table creation
│
└── environments/
    ├── dev/terraform.tfvars        # Dev: t3.micro, 1 NAT, single-AZ RDS
    ├── staging/terraform.tfvars   # Staging: t3.small, mirrors prod topology
    └── prod/terraform.tfvars      # Prod: t3.medium, Multi-AZ, 3 AZs, deletion protection
```

---

## Step-by-Step Practice Guide

### Step 1 — Prerequisites

```bash
# Install Terraform
# https://developer.hashicorp.com/terraform/install

terraform -version   # should be >= 1.6.0

# Configure AWS credentials
aws configure
# or use environment variables:
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2 — Bootstrap the Remote Backend (one-time)

This creates the S3 bucket and DynamoDB table that Terraform uses for state storage
and state locking. Run this **once** before everything else.

```bash
cd global/backend-setup
terraform init
terraform apply -var="state_bucket_name=mycompany-terraform-state-2024"
```

Copy the outputs, then update `backend.tf` in the root:
```hcl
backend "s3" {
  bucket         = "mycompany-terraform-state-2024"  # ← your bucket name
  key            = "3tier-app/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

```bash
cd ../..   # back to root
```

### Step 3 — Create and Switch Workspaces

```bash
# Create all three workspaces (once)
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# List workspaces
terraform workspace list

# Switch to the workspace you want to deploy
terraform workspace select dev
```

**Key concept**: Workspaces namespace state files automatically:
- `dev`     → `env:/dev/3tier-app/terraform.tfstate`
- `staging` → `env:/staging/3tier-app/terraform.tfstate`
- `prod`    → `env:/prod/3tier-app/terraform.tfstate`

Each environment is completely isolated — a `terraform destroy` on dev
cannot touch prod state.

### Step 4 — Initialize and Deploy

```bash
# Initialize (downloads providers and modules)
terraform init

# Preview what will be created
terraform plan -var-file=environments/dev/terraform.tfvars

# Deploy
terraform apply -var-file=environments/dev/terraform.tfvars
```

To deploy staging or prod, just switch workspaces and point to the right tfvars:

```bash
terraform workspace select staging
terraform apply -var-file=environments/staging/terraform.tfvars

terraform workspace select prod
terraform apply -var-file=environments/prod/terraform.tfvars
```

### Step 5 — Verify the Deployment

```bash
# Show outputs (ALB DNS name, ASG name, dashboard)
terraform output

# Get the ALB DNS name and test your app
curl http://$(terraform output -raw alb_dns_name)/health
```

Open the CloudWatch dashboard in the AWS Console to see live metrics.

### Step 6 — Test Auto Scaling

```bash
# SSH to an instance via SSM Session Manager (no open port 22 needed)
aws ssm start-session --target <instance-id>

# Simulate CPU load to trigger the scale-out alarm
stress --cpu 4 --timeout 300
```

Watch the CloudWatch dashboard — within 2 evaluation periods (4 minutes) the
ASG should add an instance.

### Step 7 — Tear Down (safely)

```bash
# Dev only — won't touch staging or prod
terraform workspace select dev
terraform destroy -var-file=environments/dev/terraform.tfvars
```

---

## Key Design Decisions (explain these in an interview)

| Decision | Reasoning |
|----------|-----------|
| **Workspaces + S3 backend** | Each workspace gets its own state key. DynamoDB lock prevents two engineers from running `apply` simultaneously. |
| **Single NAT in dev/staging** | One NAT Gateway in dev saves ~$32/month vs one per AZ. Prod uses one per AZ for AZ-level fault tolerance. |
| **SG chaining** | RDS only accepts traffic from the Web SG; Web only accepts from ALB SG. No CIDR-based rules between tiers. |
| **IMDSv2 enforced** | `http_tokens = required` on the Launch Template blocks SSRF attacks from reading instance metadata. |
| **IAM Instance Profile** | EC2 instances never have hardcoded credentials — they assume an IAM role that grants only what they need. |
| **SSM Session Manager** | Port 22 never needs to be open publicly. SSM gives secure shell access audited via CloudTrail. |
| **Multi-AZ RDS in prod** | RDS promotes the standby in ~60s during an AZ failure. Not enabled in dev/staging to reduce cost. |
| **Rolling instance refresh** | ASG replaces instances in batches with `min_healthy_percentage = 50`, ensuring zero-downtime deployments. |
| **`create_before_destroy`** | On Launch Template updates, the new version is created before the old one is deleted. |

---

## Common Interview Questions & Answers

**Q: How does state locking work?**
> When `terraform apply` starts, it writes a lock record to DynamoDB with the operation metadata.
> Any concurrent apply on the same workspace checks for this record and fails with a lock error.
> The lock is released automatically when apply completes or fails.

**Q: How do workspaces isolate environments?**
> The S3 backend prefixes the state key with `env:/<workspace>/`. Dev and prod literally write to
> different files in S3, so there is zero risk of one environment's apply corrupting another.

**Q: Why not just use separate S3 keys without workspaces?**
> Workspaces give you the same isolation but with a single `backend.tf`. The `terraform.workspace`
> built-in variable lets you drive environment-specific behaviour (Multi-AZ, instance size, etc.)
> from one set of module calls instead of duplicating code across directories.

**Q: How would you pass the DB password securely?**
> In a real project: store the password in AWS Secrets Manager, then use a data source to read it
> at plan time, or inject it via `-var` from a CI/CD secret store (GitHub Actions secrets,
> HashiCorp Vault, AWS Parameter Store). The `sensitive = true` attribute prevents it from
> appearing in plan output.

---

## What to show in an interview

1. **Walk the module graph** in `main.tf` — show how outputs of one module feed inputs of the next
2. **Show workspace isolation** — `terraform workspace list`, explain the S3 key naming
3. **Explain the security group chain** in `modules/security-group/main.tf`
4. **Explain the IAM role** in `modules/iam/main.tf` — no hardcoded keys, least-privilege
5. **Open the CloudWatch dashboard** and explain how alarms wire to ASG policies
6. **Show the prod vs dev differences** controlled by `local.is_prod` in `main.tf`
