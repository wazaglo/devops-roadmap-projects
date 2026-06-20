# -----------------------------------------------
# Data Sources
# -----------------------------------------------

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -----------------------------------------------
# SSH Key Pair
# -----------------------------------------------

resource "aws_key_pair" "devops_key" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = {
    Name        = var.key_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project
  }
}

# -----------------------------------------------
# Security Group
# -----------------------------------------------

resource "aws_security_group" "ssh_access" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH access to the Debian server"

  ingress {
    description = "SSH from anywhere"
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
    Name        = "${var.instance_name}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project
  }
}

# -----------------------------------------------
# EC2 Instance
# -----------------------------------------------

resource "aws_instance" "iac_server" {
  ami                    = data.aws_ami.debian.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    tags = {
      Name        = "${var.instance_name}-root"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project
    }
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project
  }
}
