# -----------------------------------------
# Latest Ubuntu 24.04 LTS AMI
# -----------------------------------------
data "aws_ami" "ubuntu24" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------
# AWS Key Pair
# -----------------------------------------
resource "aws_key_pair" "devops_key" {
  key_name   = var.key_name
  public_key = var.public_key
}

# -----------------------------------------
# Security Group
# -----------------------------------------
resource "aws_security_group" "monitoring_access" {
  name        = "netdata-monitoring-access"
  description = "Allow SSH and Netdata dashboard access"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Netdata Dashboard"
    from_port   = 19999
    to_port     = 19999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "netdata-monitoring-access"
  }
}

# -----------------------------------------
# User Data Script - Install Netdata
# -----------------------------------------
locals {
  user_data = file("user_data.sh")
}

# -----------------------------------------
# Ubuntu EC2 Instance
# -----------------------------------------
resource "aws_instance" "netdata_monitoring" {
  ami                         = data.aws_ami.ubuntu24.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.devops_key.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data

  vpc_security_group_ids = [
    aws_security_group.monitoring_access.id
  ]

  tags = {
    Name        = var.instance_name
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "Roadmap-Netdata-Monitoring"
  }
}
