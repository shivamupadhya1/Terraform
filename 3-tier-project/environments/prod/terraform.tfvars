# =============================================================================
# PROD environment — HA topology: 3 AZs, Multi-AZ RDS, one NAT per AZ,
#                   deletion protection enabled, longer backup retention
# Usage: terraform workspace select prod
#        terraform apply -var-file=environments/prod/terraform.tfvars
# =============================================================================

project_name = "my3tier"
aws_region   = "us-east-1"

# Network — 3 AZs for zone-level fault tolerance
vpc_cidr             = "10.2.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets       = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_app_subnets  = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
private_data_subnets = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]

# EC2 / ASG — production sizing with headroom for traffic spikes
ami_id           = "ami-0c02fb55956c7d316"
instance_type    = "t3.medium"
asg_desired      = 3
asg_min          = 2
asg_max          = 10
root_volume_size = 30

# ALB — TLS termination in prod
app_port               = 80
health_check_path      = "/health"
certificate_arn        = ""  # REQUIRED: replace with your ACM certificate ARN

# RDS — Multi-AZ, larger instance, 30-day backup, deletion protection on
db_engine                 = "mysql"
db_engine_version         = "8.0"
db_instance_class         = "db.t3.medium"
db_allocated_storage      = 100
db_max_allocated_storage  = 500
db_parameter_group_family = "mysql8.0"
db_name                   = "appdb"
db_username               = "admin"
db_password               = "CHANGE_ME_prod_password_123!"  # Use AWS Secrets Manager — never hardcode

# CloudWatch — tighter thresholds and ops email for prod
cpu_high_threshold = 60
cpu_low_threshold  = 15
alarm_email        = "ops-team@example.com"
