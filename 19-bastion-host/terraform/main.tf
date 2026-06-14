# -----------------------------------------
# Latest Debian 12 AMI
# -----------------------------------------
data "aws_ami" "debian12" {
  most_recent = true

  owners = ["136693071363"]

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
# VPC
# -----------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "bastion-vpc"
  }
}

# -----------------------------------------
# Public Subnet
# -----------------------------------------
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "bastion-public-subnet"
  }
}

# -----------------------------------------
# Private Subnet
# -----------------------------------------
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "bastion-private-subnet"
  }
}

# -----------------------------------------
# Internet Gateway
# -----------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bastion-igw"
  }
}

# -----------------------------------------
# Public Route Table
# -----------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "bastion-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------
# NAT Gateway (Optional)
# -----------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "bastion-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "bastion-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------
# Private Route Table
# -----------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "bastion-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------------------
# Security Group - Bastion (Public)
# -----------------------------------------
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for bastion host - SSH from allowed CIDR only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# -----------------------------------------
# Security Group - Private Server
# -----------------------------------------
resource "aws_security_group" "private" {
  name        = "private-sg"
  description = "Security group for private server - SSH from bastion SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from bastion host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

# -----------------------------------------
# Bastion Host (Public Subnet)
# -----------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.debian12.id
  instance_type               = var.instance_type
  key_name                    = var.bastion_key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_bastion.sh", {
    admin_username = var.admin_username
  })

  tags = {
    Name        = "bastion-host"
    Role        = "bastion"
    Environment = "lab"
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------
# Private Server (Private Subnet)
# -----------------------------------------
resource "aws_instance" "private" {
  ami                    = data.aws_ami.debian12.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = templatefile("${path.module}/user_data_private.sh", {
    admin_username = var.admin_username
    admin_password = var.admin_password
  })

  tags = {
    Name        = "private-server"
    Role        = "private"
    Environment = "lab"
  }
}