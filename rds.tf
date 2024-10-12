resource "aws_db_instance" "primary_new" {
  identifier             = "primary-db-instance"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "primarydb"
  username               = "prateek"
  password               = "NewSecurePassword123!"
  parameter_group_name   = "default.postgres14"
  skip_final_snapshot    = true
  publicly_accessible    = true
  backup_retention_period = 1
  vpc_security_group_ids = [aws_security_group.rds_sg_new.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  tags = {
    Name = "PrimaryDB"
  }

  lifecycle {
    ignore_changes = [password]
    prevent_destroy = true
  }
}
/*
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["203.192.251.11/32"]
  }
}
*/

resource "aws_security_group" "rds_sg_new" {
  name        = "rds-ec2-security-group"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["203.192.251.11/32"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = ["subnet-03725068c7adfc3b8", "subnet-0abd514b027bac78c"]

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_network_acl" "rds_nacl" {
  vpc_id = var.vpc_id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5432
    to_port    = 5432
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 5432
    to_port    = 5432
  }

  tags = {
    Name = "RDS NACL"
  }
}

resource "aws_network_acl_association" "rds_nacl_association" {
  for_each       = toset(aws_db_subnet_group.rds_subnet_group.subnet_ids)
  network_acl_id = aws_network_acl.rds_nacl.id
  subnet_id      = each.value
}

resource "time_sleep" "wait_for_db" {
  depends_on = [aws_db_instance.primary_new]
  create_duration = "5m"
}

# resource "aws_db_instance" "read_replica" {
# count                  = 1
# identifier             = "read-replica-1"
# instance_class         = "db.t3.micro"
# replicate_source_db    = aws_db_instance.primary.id
# publicly_accessible    = false
# skip_final_snapshot    = true

# tags = {
#     Name = "ReadReplica-1"
# }

# depends_on = [time_sleep.wait_for_db]
# }

#PraIbm@2024