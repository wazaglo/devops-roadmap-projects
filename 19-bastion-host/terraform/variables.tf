variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to bastion host (use your IP/32 for security)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "bastion_key_name" {
  description = "Name for bastion host SSH key pair (must exist in AWS)"
  type        = string
  default     = "bastion-host-key"
}

variable "private_key_name" {
  description = "Name for private server SSH key pair (must exist in AWS)"
  type        = string
  default     = "private-server-key"
}

variable "admin_username" {
  description = "Admin username for both instances"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Password for admin user (used on private server for password auth)"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access (costs ~$45/month)"
  type        = bool
  default     = false
}