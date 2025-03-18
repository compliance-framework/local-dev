provider "aws" {
  region = "eu-west-2"
}

locals {
  vpc_cidr = "10.0.0.0/16" # 10.0.0.0 - 10.0.255.255
  availability_zones = [
    "euw2-az1",
    "euw2-az2",
    "euw2-az3",
  ]
}

# 🔹 VPC Setup
resource "aws_vpc" "ccf_demo_vpc" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = "CCF-demo-VPC"
  }
}

/**
AWS Subnet Design:

Public: 10.0.1.0/20   # 10.0.0.0 - 10.0.15.255
  AZ-1: 10.0.0.0/22   # 10.0.0.0 - 10.0.3.255
  AZ-2: 10.0.4.0/22   # 10.0.4.0 - 10.0.7.255
  AZ-3: 10.0.8.0/22   # 10.0.8.0 - 10.0.11.255
  Spare: 10.0.12.0/22 # 10.0.12.0 - 10.0.15.255

Private: 10.0.16.0/20 # 10.0.16.0 - 10.0.31.255
  AZ-1: 10.0.16.0/22  # 10.0.16.0 - 10.0.19.255
  AZ-2: 10.0.20.0/22  # 10.0.20.0 - 10.0.23.255
  AZ-3: 10.0.24.0/22  # 10.0.24.0 - 10.0.27.255
  Spare: 10.0.28.0/22 # 10.0.28.0 - 10.0.31.255

Spare: 10.0.32.0/20 # Capable of supporting a bunch more subnets.
 */


resource "aws_subnet" "public-az-1" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 0)
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "CCF-demo-Public-AZ-1"
  }
}

resource "aws_subnet" "public-az-2" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 1)
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "CCF-demo-Public-AZ-2"
  }
}

resource "aws_subnet" "public-az-3" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 2)
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "CCF-demo-Public-AZ-3"
  }
}

resource "aws_subnet" "public-spare" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 3)
  map_public_ip_on_launch = true

  tags = {
    Name = "CCF-demo-Public-Spare"
  }
}

resource "aws_subnet" "private-az-1" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 4)
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "CCF-demo-Private-AZ-1"
  }
}

resource "aws_subnet" "private-az-2" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 5)
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "CCF-demo-Private-AZ-2"
  }
}

resource "aws_subnet" "private-az-3" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 6)
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "CCF-demo-Private-AZ-3"
  }
}

resource "aws_subnet" "private-spare" {
  vpc_id                  = aws_vpc.ccf_demo_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 6, 7)
  map_public_ip_on_launch = false

  tags = {
    Name = "CCF-demo-Private-Spare"
  }
}

# 🔹 Security Groups
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.ccf_demo_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CCF-demo-Bastion-SG"
  }
}

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.ccf_demo_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "CCF-demo-App-SG"
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.ccf_demo_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  tags = {
    Name = "CCF-demo-DB-SG"
  }
}

# 🔹 EC2 Instances
resource "aws_instance" "bastion" {
  ami             = "ami-0e56583ebfdfc098f"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public-az-1.id
  security_groups = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "CCF-demo-Bastion"
  }
}

resource "aws_instance" "app" {
  ami             = "ami-0e56583ebfdfc098f"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private-az-1.id
  security_groups = [aws_security_group.app_sg.id]

  tags = {
    Name = "CCF-demo-App"
  }
}

# 🔹 Generate a Secure Random Password
resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!@#%^&*()-_=+[]{}<>:?"
}

# 🔹 Create a KMS Key for Encryption
resource "aws_kms_key" "db_key" {
  description             = "CCF-demo KMS key for encrypting RDS password"
  deletion_window_in_days = 10

  tags = {
    Name = "CCF-demo-KMS-Key"
  }
}

resource "aws_db_subnet_group" "database" {
  name = "database"
  subnet_ids = [
    aws_subnet.private-az-1.id,
    aws_subnet.private-az-2.id,
    aws_subnet.private-az-3.id,
  ]

  tags = {
    Name = "CCF-demo-RDS-subnet-group"
  }
}


# 🔹 RDS Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "ccf-demo-aurora-cluster"
  engine                 = "aurora-postgresql"
  master_username        = "administrator"
  master_password        = random_password.db_master_password.result
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.db_key.arn
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.database.name

  tags = {
    Name = "CCF-demo-RDS-Cluster"
  }
}
