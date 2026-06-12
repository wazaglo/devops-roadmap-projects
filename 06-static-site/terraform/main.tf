# -----------------------------------------
# Latest Debian 12 AMI
# -----------------------------------------
data "aws_ami" "debian12" {
  most_recent = true

  owners = ["136693071363"] # Debian Official

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
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
resource "aws_security_group" "web_access" {
  name        = "web-access"
  description = "Allow SSH and HTTP access"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
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
    Name = "web-access"
  }
}

# -----------------------------------------
# User Data Script - Install and configure Nginx
# -----------------------------------------
locals {
  user_data = file("user_data.sh")
}

# -----------------------------------------
# Debian EC2 Instance
# -----------------------------------------
resource "aws_instance" "static_site_server" {
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.devops_key.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data

  vpc_security_group_ids = [
    aws_security_group.web_access.id
  ]

  tags = {
    Name        = var.instance_name
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "Roadmap-Static-Site"
  }
}