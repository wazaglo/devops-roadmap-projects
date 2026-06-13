variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "SSH Public Key"
  type        = string
}

variable "key_name" {
  description = "Name for the AWS Key Pair"
  type        = string
  default     = "devops-netdata-key"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "devops-netdata-monitoring"
}
