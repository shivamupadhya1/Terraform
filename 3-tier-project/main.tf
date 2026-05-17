locals {
  env = terraform.workspace # "dev", "staging", or "prod"

  # Common tags merged into every resource
  common_tags = {
    Environment = local.env
    Project     = var.project_name
    ManagedBy   = "terraform"
    Workspace   = terraform.workspace
  }

  # Boolean flags to drive prod-specific behaviour
  is_prod    = local.env == "prod"
  is_staging = local.env == "staging"
}

# =============================================================================
# MODULE: VPC — 3-tier network layout
# Public:       ALB
# Private App:  EC2 / Auto Scaling Group
# Private Data: RDS
# =============================================================================
module "vpc" {
  source = "./modules/vpc"

  name                 = "${var.project_name}-${local.env}"
  cidr_block           = var.vpc_cidr
  azs                  = var.azs
  public_subnets       = var.public_subnets
  private_app_subnets  = var.private_app_subnets
  private_data_subnets = var.private_data_subnets
  enable_nat_gateway   = true
  # Prod: one NAT per AZ for AZ-level fault tolerance
  # Dev/Staging: single shared NAT to reduce cost
  single_nat_gateway = !local.is_prod
  tags               = local.common_tags
}

# =============================================================================
# MODULE: Security Groups — least-privilege, tiered access
# =============================================================================
module "security_groups" {
  source = "./modules/security-group"

  name     = "${var.project_name}-${local.env}"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  tags     = local.common_tags
}

# =============================================================================
# MODULE: IAM — EC2 role with SSM + CloudWatch, least-privilege S3
# =============================================================================
module "iam" {
  source = "./modules/iam"

  name          = "${var.project_name}-${local.env}"
  app_s3_bucket = var.app_s3_bucket
  tags          = local.common_tags
}

# =============================================================================
# MODULE: ALB — internet-facing, terminates TLS, routes to ASG
# =============================================================================
module "alb" {
  source = "./modules/alb"

  name                       = "${var.project_name}-${local.env}"
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.security_groups.alb_sg_id
  app_port                   = var.app_port
  health_check_path          = var.health_check_path
  certificate_arn            = var.certificate_arn
  redirect_http_to_https     = local.is_prod && var.certificate_arn != ""
  enable_deletion_protection = local.is_prod
  tags                       = local.common_tags
}

# =============================================================================
# MODULE: EC2 Auto Scaling Group — fleet management with Launch Template
# =============================================================================
module "ec2_asg" {
  source = "./modules/ec2"

  name                 = "${var.project_name}-${local.env}"
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  subnet_ids           = module.vpc.private_app_subnet_ids
  security_group_ids   = [module.security_groups.web_sg_id]
  target_group_arns    = [module.alb.target_group_arn]
  iam_instance_profile = module.iam.ec2_instance_profile_name
  desired_capacity     = var.asg_desired
  min_size             = var.asg_min
  max_size             = var.asg_max
  root_volume_size     = var.root_volume_size
  user_data            = var.user_data
  tags                 = local.common_tags
}

# =============================================================================
# MODULE: RDS — private, encrypted, Multi-AZ in prod
# =============================================================================
module "rds" {
  source = "./modules/rds"

  name                    = "${var.project_name}-${local.env}"
  subnet_ids              = module.vpc.private_data_subnet_ids
  rds_sg_id               = module.security_groups.rds_sg_id
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_max_allocated_storage
  parameter_group_family  = var.db_parameter_group_family
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = local.is_prod
  backup_retention_period = local.is_prod ? 30 : 7
  skip_final_snapshot     = !local.is_prod
  deletion_protection     = local.is_prod
  tags                    = local.common_tags
}

# =============================================================================
# MODULE: CloudWatch — alarms, auto-scaling triggers, dashboard
# =============================================================================
module "cloudwatch" {
  source = "./modules/cloudwatch"

  name                   = "${var.project_name}-${local.env}"
  autoscaling_group_name = module.ec2_asg.autoscaling_group_name
  alb_arn_suffix         = module.alb.alb_arn_suffix
  db_instance_id         = module.rds.db_instance_id
  scale_out_policy_arn   = module.ec2_asg.scale_out_policy_arn
  scale_in_policy_arn    = module.ec2_asg.scale_in_policy_arn
  cpu_high_threshold     = var.cpu_high_threshold
  cpu_low_threshold      = var.cpu_low_threshold
  create_sns_topic       = true
  alarm_email            = var.alarm_email
  tags                   = local.common_tags
}
