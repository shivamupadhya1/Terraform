# DB Subnet Group — places RDS in the isolated private data subnets
resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "RDS subnet group for ${var.name}"

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

# DB Parameter Group — tune engine-level settings
resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-db-params"
  family = var.parameter_group_family

  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance — private, encrypted, no public access
resource "aws_db_instance" "this" {
  identifier              = "${var.name}-rds"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  parameter_group_name   = aws_db_parameter_group.this.name

  # Multi-AZ enabled for prod; single-AZ for dev/staging to cut costs
  multi_az            = var.multi_az
  publicly_accessible = false

  # Snapshot on destroy for prod; skipped for dev/staging
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"
  deletion_protection       = var.deletion_protection

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Performance Insights for query-level visibility
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Export slow query and error logs to CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags = merge(var.tags, {
    Name = "${var.name}-rds"
  })
}
