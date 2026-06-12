output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.static_site_server.id
}

output "public_ip" {
  description = "Public IP Address"
  value       = aws_instance.static_site_server.public_ip
}

output "public_dns" {
  description = "Public DNS Name"
  value       = aws_instance.static_site_server.public_dns
}

output "ssh_command" {
  description = "SSH Command"
  value       = "ssh admin@${aws_instance.static_site_server.public_ip}"
}

output "site_url" {
  description = "Static Site URL"
  value       = "http://${aws_instance.static_site_server.public_ip}"
}

output "deploy_command" {
  description = "Deploy command using rsync"
  value       = "rsync -avz --delete ../static-site/ admin@${aws_instance.static_site_server.public_ip}:/var/www/html/"
}