# =============================================================================
# STAGING environment — mirrors prod topology but smaller instance sizes
# Usage: terraform workspace select staging
#        terraform apply -var-file=environments/staging/terraform.tfvars
# =============================================================================

project_name = "my3tier"
aws_region   = "us-east-1"

# Network — separate CIDR range to avoid overlap with dev or prod
vpc_cidr             = "10.1.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnets       = ["10.1.1.0/24", "10.1.2.0/24"]
private_app_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
private_data_subnets = ["10.1.21.0/24", "10.1.22.0/24"]

# EC2 / ASG
ami_id           = "ami-0c02fb55956c7d316"
instance_type    = "t3.small"
asg_desired      = 2
asg_min          = 1
asg_max          = 4
root_volume_size = 20

# ALB
app_port          = 80
health_check_path = "/health"
certificate_arn   = ""  # Add ACM ARN to test HTTPS end-to-end

# RDS — slightly larger, still single-AZ
db_engine                 = "mysql"
db_engine_version         = "8.0"
db_instance_class         = "db.t3.small"
db_allocated_storage      = 20
db_max_allocated_storage  = 100
db_parameter_group_family = "mysql8.0"
db_name                   = "appdb"
db_username               = "admin"
db_password               = "CHANGE_ME_staging_password_123!"  # Use -var or Secrets Manager

# CloudWatch
cpu_high_threshold = 70
cpu_low_threshold  = 20
alarm_email        = "your-email@example.com"
