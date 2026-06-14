output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ec2-user@${aws_instance.app.public_ip}"
}

output "service_url" {
  description = "URL to access the service"
  value       = "http://${aws_instance.app.public_ip}:3000"
}
