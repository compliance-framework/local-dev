provider "aws" {
  region = "eu-west-2"
}

# 🔹 VPC Setup
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
}

# 🔹 Security Groups
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}

# 🔹 EC2 Instances
resource "aws_instance" "bastion" {
  ami             = "ami-0e56583ebfdfc098f"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.bastion_sg.name]
}

resource "aws_instance" "app" {
  ami             = "ami-0e56583ebfdfc098f"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.app_sg.name]
}

# 🔹 Generate a Secure Random Password
resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!@#%^&*()-_=+[]{}<>:?"
}

# 🔹 Create a KMS Key for Encryption
resource "aws_kms_key" "db_key" {
  description             = "KMS key for encrypting RDS password"
  deletion_window_in_days = 10
}

# 🔹 Store the Password in Secrets Manager
resource "aws_secretsmanager_secret" "rds_password" {
  name       = "rds-master-password"
  kms_key_id = aws_kms_key.db_key.arn
}

resource "aws_secretsmanager_secret_version" "rds_password_value" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.db_master_password.result
}

# 🔹 Retrieve the Password Securely
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
}

# 🔹 RDS Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier   = "aurora-cluster"
  engine              = "aurora-postgresql"
  master_username     = "admin"
  master_password     = data.aws_secretsmanager_secret_version.db_password.secret_string
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.db_key.arn
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}
