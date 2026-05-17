# Application Load Balancer — sits in public subnets, forwards to private EC2 fleet
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  enable_http2       = true

  # Enable deletion protection on prod to prevent accidental teardown
  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != "" ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "${var.name}-alb"
      enabled = true
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

# Target Group — routes traffic to EC2 instances registered by the ASG
resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-tg"
  })
}

# HTTP Listener — redirects to HTTPS in prod; forwards directly in dev/staging
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.redirect_http_to_https ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.redirect_http_to_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.redirect_http_to_https ? [] : [1]
      content {
        target_group {
          arn = aws_lb_target_group.this.arn
        }
      }
    }
  }
}

# HTTPS Listener — only created when an ACM certificate ARN is provided
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
