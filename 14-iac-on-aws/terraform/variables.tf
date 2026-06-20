variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "debian-iac-server"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "devops-iac-key"
}

variable "public_key" {
  description = "Public SSH key material to import into AWS"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = "Default SSH user for the AMI"
  type        = string
  default     = "admin"
}

variable "environment" {
  description = "Environment tag value"
  type        = string
  default     = "Lab"
}

variable "project" {
  description = "Project tag value"
  type        = string
  default     = "Roadmap-14"
}
