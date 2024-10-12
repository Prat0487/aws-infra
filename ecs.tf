# security_groups.tf

resource "aws_security_group" "ecs_service" {
  name        = "${var.app_name}-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id

  # Allow inbound HTTP traffic
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "ecs_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.160.0/24"  # Adjust this CIDR block as needed
  
  tags = {
    Name = "${var.app_name}-ecs-subnet"
  }
}
# iam.tf



# IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.app_name}-ecs-instance-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" }
      }
    ]
  })
}

# Attach ECS instance policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Create an instance profile for ECS instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.app_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# main.tf (continued)

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.app_name}-cluster"
}

# launch_configuration.tf

# Get the latest ECS-optimized AMI ID
data "aws_ssm_parameter" "ecs_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}



# User data template for ECS instances
data "template_file" "ecs_user_data" {
  template = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF
}
  # Create a launch template for ECS instances
/*
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.app_name}-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami_id.value
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ecs_service.id]

  user_data = base64encode(data.template_file.ecs_user_data.rendered)
}
*/
# Update the Auto Scaling group to use the launch template
resource "aws_autoscaling_group" "ecs_instances" {
  name                = "${var.app_name}-asg"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.ecs_subnet.id]
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-instance"
    propagate_at_launch = true
  }
}

# Update the launch template to use the correct VPC subnets
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.app_name}-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami_id.value
  instance_type = "t3.micro"  # Free tier eligible

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_service.id]
    subnet_id                   = aws_subnet.ecs_subnet.id  # Use the first subnet from the list
  }

  user_data = base64encode(data.template_file.ecs_user_data.rendered)

  lifecycle {
    create_before_destroy = true
  }
}

# Add a new variable for subnet IDs
/*
variable "subnet_ids" {
  description = "List of subnet IDs for the ECS instances"
  type        = list(string)
}
*/
