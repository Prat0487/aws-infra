# Provider configuration
provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.terraform_role_arn
  }
}
  # EC2 Instance
  /*
  resource "aws_instance" "app_server" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = aws_subnet.app_subnet.id

    vpc_security_group_ids = [aws_security_group.app_sg.id]
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
  */
resource "aws_instance" "app_server_new" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.app_subnet.id

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_access_profile.name

  tags = {
    Name = var.app_server_name_new
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
              EOF
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "app_server_security_group"
  description = "Security group for the application server"
  vpc_id      = var.vpc_id

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
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "app_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.96.0/24"  # This CIDR is within the VPC's 172.31.0.0/16 range
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
        Resource = aws_db_instance.primary_new.arn
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
/*
resource "aws_security_group_rule" "ec2_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.rds_sg_new.id
  description              = "Allow outbound PostgreSQL traffic to RDS"
}

# RDS from EC2 Security Group Rule
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg_new.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "Allow inbound PostgreSQL traffic from EC2"
}
*/
resource "aws_security_group_rule" "ec2_to_rds" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_sg_new.id
}

resource "aws_security_group_rule" "rds_from_ec2" {
  security_group_id        = aws_security_group.rds_sg_new.id
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "ssm_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
  description       = "Allow outbound HTTPS traffic for SSM"
}
/*
resource "null_resource" "upload_sample_data" {
  provisioner "local-exec" {
    command = "aws s3 cp ${var.sample_data_file} s3://${aws_s3_bucket.data_bucket.bucket}/"
  }

  depends_on = [aws_s3_bucket.data_bucket]
}
*/
resource "aws_s3_object" "sample_data" {
  bucket = aws_s3_bucket.data_bucket.id
  key    = "data/employees.csv"
  source = var.sample_data_file
}



