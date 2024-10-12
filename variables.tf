# Variables
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0182f373e66f89c85"  # Replace with the latest Amazon Linux 2 AMI ID
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the key pair to use for SSH access"
  default     = "your-key-pair-name"  # Replace with your key pair name
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH from anywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "app_bucket_name" {
  description = "Name of the application bucket"
  default     = "app-bucket-2lz9r655"
}

variable "create_read_replicas" {
  description = "Flag to determine whether to create read replicas"
  type        = bool
  default     = true
}
/*
variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
*/

variable "vpc_id" {
  description = "VPC ID"
  default     = "vpc-0de37fbbc866cf6e7"
}

variable "terraform_role_arn" {
  description = "ARN of the IAM role for Terraform"
  type        = string
  default     = "arn:aws:iam::014498640669:role/terraform-deploy"
}

variable "app_server_name_new" {
  description = "Name of the application server"
  type        = string
  default     = "AppServerNewInstance"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "my-app"
}

variable "glue_database_name" {
  type        = string
  description = "Name of the Glue database"
  default     = "your_default_glue_database_name"
}

variable "sample_data_file" {
  type        = string
  description = "Path to the sample data file"
  default     = "data/employees.csv"
}
