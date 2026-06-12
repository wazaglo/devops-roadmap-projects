output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.debian_server.id
}

output "public_ip" {
  description = "Public IP Address"
  value       = aws_instance.debian_server.public_ip
}

output "public_dns" {
  description = "Public DNS Name"
  value       = aws_instance.debian_server.public_dns
}

output "ssh_command" {
  description = "SSH Command"
  value       = "ssh admin@${aws_instance.debian_server.public_ip}"
}
