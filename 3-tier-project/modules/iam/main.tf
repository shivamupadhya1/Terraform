# IAM Role for EC2 instances — no hardcoded credentials needed on the instance
resource "aws_iam_role" "ec2" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# SSM Session Manager — allows secure shell access without opening port 22
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent — allows instances to push custom metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Least-privilege S3 policy — only the specific app bucket, only needed actions
resource "aws_iam_policy" "s3_app_access" {
  count       = var.app_s3_bucket != "" ? 1 : 0
  name        = "${var.name}-s3-app-policy"
  description = "Least-privilege S3 access for ${var.name} application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AppBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.app_s3_bucket}",
          "arn:aws:s3:::${var.app_s3_bucket}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_app" {
  count      = var.app_s3_bucket != "" ? 1 : 0
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_app_access[0].arn
}

# Instance Profile — bridges the IAM Role to EC2 instances
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = var.tags
}
