# Provider configuration
provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.terraform_role_arn
  }
}
  # EC2 Instance
  resource "aws_instance" "app_server" {
    ami           = var.ami_id
    instance_type = var.instance_type

    vpc_security_group_ids = [aws_security_group.app_server_sg.id]
    iam_instance_profile   = aws_iam_instance_profile.ec2_access_profile.name

    tags = {
      Name = var.app_server_name
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
                sudo systemctl enable amazon-ssm-agent
                sudo systemctl start amazon-ssm-agent
                EOF
  }
# Security Group
resource "aws_security_group" "app_server_sg" {
  name        = "app_server_security_group"
  description = "Security group for the application server"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_server_security_group"
  }
}
  # S3 Bucket
  resource "aws_s3_bucket" "app_bucket" {
    bucket = "app-bucket-${random_string.bucket_suffix.result}"

    tags = {
      Name = "AppBucket"
    }
  }

  resource "aws_s3_bucket_ownership_controls" "app_bucket_ownership" {
    bucket = aws_s3_bucket.app_bucket.id

    rule {
      object_ownership = "BucketOwnerPreferred"
    }
  }

  resource "aws_s3_bucket_public_access_block" "app_bucket_public_access" {
    bucket = aws_s3_bucket.app_bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }

  resource "aws_s3_bucket_acl" "app_bucket_acl" {
    depends_on = [
      aws_s3_bucket_ownership_controls.app_bucket_ownership,
      aws_s3_bucket_public_access_block.app_bucket_public_access,
    ]

    bucket = aws_s3_bucket.app_bucket.id
    acl    = "private"
  }
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role for EC2 to access S3, RDS, and Session Manager
resource "aws_iam_role" "ec2_access_role" {
  name = "ec2_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = aws_iam_role.ec2_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for RDS access
resource "aws_iam_role_policy" "rds_access_policy" {
  name = "rds_access_policy"
  role = aws_iam_role.ec2_access_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect"
        ]
        Effect   = "Allow"
        Resource = aws_db_instance.primary.arn
      }
    ]
  })
}

# IAM Policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_access_role.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_access_profile" {
  name = "ec2_access_profile"
  role = aws_iam_role.ec2_access_role.name
}

# EC2 to RDS Security Group Rule
resource "aws_security_group_rule" "ec2_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_server_sg.id
  source_security_group_id = aws_security_group.rds_sg.id
}

# RDS from EC2 Security Group Rule
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.app_server_sg.id
}

resource "aws_security_group_rule" "ssm_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_server_sg.id
  description       = "Allow outbound HTTPS traffic for SSM"
}
