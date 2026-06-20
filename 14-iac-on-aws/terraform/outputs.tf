output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.iac_server.id
}

output "public_ip" {
  description = "Public IPv4 address of the Debian server"
  value       = aws_instance.iac_server.public_ip
}

output "public_dns" {
  description = "Public DNS name of the Debian server"
  value       = aws_instance.iac_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the Debian server"
  value       = "ssh ${var.ssh_user}@${aws_instance.iac_server.public_ip}"
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_instance.iac_server.instance_state
}
