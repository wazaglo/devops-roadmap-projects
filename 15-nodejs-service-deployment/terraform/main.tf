# -----------------------------------------------
# Data Sources
# -----------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------
# SSH Key Pair
# -----------------------------------------------

resource "aws_key_pair" "devops_key" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = {
    Name      = var.key_name
    ManagedBy = "Terraform"
    Project   = "Roadmap-15"
  }
}

# -----------------------------------------------
# Security Group
# -----------------------------------------------

resource "aws_security_group" "nodejs_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow SSH and HTTP access to the Node.js server"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
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
    Name      = "${var.instance_name}-sg"
    ManagedBy = "Terraform"
    Project   = "Roadmap-15"
  }
}

# -----------------------------------------------
# EC2 Instance
# -----------------------------------------------

resource "aws_instance" "nodejs_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.nodejs_sg.id]

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    tags = {
      Name      = "${var.instance_name}-root"
      ManagedBy = "Terraform"
      Project   = "Roadmap-15"
    }
  }

  tags = {
    Name      = var.instance_name
    ManagedBy = "Terraform"
    Project   = "Roadmap-15"
  }
}
