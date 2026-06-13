output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.netdata_monitoring.id
}

output "public_ip" {
  description = "Public IP Address"
  value       = aws_instance.netdata_monitoring.public_ip
}

output "public_dns" {
  description = "Public DNS Name"
  value       = aws_instance.netdata_monitoring.public_dns
}

output "ssh_command" {
  description = "SSH Command"
  value       = "ssh -i <your-private-key> ubuntu@${aws_instance.netdata_monitoring.public_ip}"
}

output "dashboard_url" {
  description = "Netdata Dashboard URL"
  value       = "http://${aws_instance.netdata_monitoring.public_ip}:19999"
}
