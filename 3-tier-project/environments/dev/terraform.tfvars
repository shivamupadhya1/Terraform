# =============================================================================
# DEV environment — low cost, single NAT, small instances
# Usage: terraform workspace select dev
#        terraform apply -var-file=environments/dev/terraform.tfvars
# =============================================================================

project_name = "my3tier"
aws_region   = "us-east-1"

# Network — /16 with 3 tiers across 2 AZs
vpc_cidr             = "10.0.0.0/16"
azs                  = ["us-east-1a", "us-east-1b"]
public_subnets       = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
private_data_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

# EC2 / ASG — minimal capacity for cost savings
ami_id           = "ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1) — update as needed
instance_type    = "t3.micro"
asg_desired      = 1
asg_min          = 1
asg_max          = 2
root_volume_size = 20

# ALB
app_port          = 80
health_check_path = "/health"
certificate_arn   = ""  # No HTTPS in dev

# RDS — smallest class, single-AZ, short retention
db_engine                 = "mysql"
db_engine_version         = "8.0"
db_instance_class         = "db.t3.micro"
db_allocated_storage      = 20
db_max_allocated_storage  = 50
db_parameter_group_family = "mysql8.0"
db_name                   = "appdb"
db_username               = "admin"
db_password               = "CHANGE_ME_dev_password_123!"  # Use -var or Secrets Manager

# CloudWatch
cpu_high_threshold = 70
cpu_low_threshold  = 20
alarm_email        = "your-email@example.com"
