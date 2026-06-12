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
  key_name   = "devops-project-key"
  public_key = var.public_key
}

# -----------------------------------------
# Security Group
# -----------------------------------------
resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH access"

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
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
    Name = "ssh-access"
  }
}

# -----------------------------------------
# Debian EC2 Instance
# -----------------------------------------
resource "aws_instance" "debian_server" {
  ami                         = data.aws_ami.debian12.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.devops_key.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.ssh_access.id
  ]

  tags = {
    Name        = "devops-ssh-project"
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "Roadmap-SSH-Server"
  }
}
