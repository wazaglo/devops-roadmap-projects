output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private.id
}

output "bastion_instance_id" {
  description = "Bastion Host Instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion Host Public IP"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Bastion Host Public DNS"
  value       = aws_instance.bastion.public_dns
}

output "private_instance_id" {
  description = "Private Server Instance ID"
  value       = aws_instance.private.id
}

output "private_private_ip" {
  description = "Private Server Private IP"
  value       = aws_instance.private.private_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.bastion_key_name} ${var.admin_username}@${aws_instance.bastion.public_ip}"
}

output "private_ssh_command_via_bastion" {
  description = "SSH command to connect to private server via bastion (ProxyJump)"
  value       = "ssh -i ~/.ssh/${var.private_key_name} -J ${var.admin_username}@${aws_instance.bastion.public_ip} ${var.admin_username}@${aws_instance.private.private_ip}"
}

output "ssh_config" {
  description = "SSH config snippet for ~/.ssh/config"
  value       = <<-EOT
    Host bastion
        HostName ${aws_instance.bastion.public_ip}
        User ${var.admin_username}
        IdentityFile ~/.ssh/${var.bastion_key_name}
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null

    Host private-server
        HostName ${aws_instance.private.private_ip}
        User ${var.admin_username}
        IdentityFile ~/.ssh/${var.private_key_name}
        ProxyJump bastion
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
    EOT
}

output "key_pair_names" {
  description = "SSH key pair names (must exist in AWS before deploy)"
  value = {
    bastion = var.bastion_key_name
    private = var.private_key_name
  }
}

output "security_groups" {
  description = "Security group IDs"
  value = {
    bastion_sg = aws_security_group.bastion.id
    private_sg = aws_security_group.private.id
  }
}

output "admin_username" {
  description = "Admin username for both instances"
  value       = var.admin_username
}

output "admin_password" {
  description = "Admin password (for private server password auth)"
  value       = var.admin_password
  sensitive   = true
}