output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.nodejs_server.id
}

output "public_ip" {
  description = "Public IPv4 address of the server"
  value       = aws_instance.nodejs_server.public_ip
}

output "public_dns" {
  description = "Public DNS name of the server"
  value       = aws_instance.nodejs_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh ${var.ssh_user}@${aws_instance.nodejs_server.public_ip}"
}

output "service_url" {
  description = "URL to access the Node.js service"
  value       = "http://${aws_instance.nodejs_server.public_ip}"
}
