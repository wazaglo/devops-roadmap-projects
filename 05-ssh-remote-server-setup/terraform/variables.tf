
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "SSH Public Key"
  type        = string
}
