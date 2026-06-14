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
  value       = "ssh -i bastion_key ${var.admin_username}@${aws_instance.bastion.public_ip}"
}

output "private_ssh_command_via_bastion" {
  description = "SSH command to connect to private server via bastion (ProxyJump)"
  value       = "ssh -i private_key -J ${var.admin_username}@${aws_instance.bastion.public_ip} ${var.admin_username}@${aws_instance.private.private_ip}"
}

output "ssh_config" {
  description = "SSH config snippet for ~/.ssh/config"
  value       = <<-EOT
    Host bastion
        HostName ${aws_instance.bastion.public_ip}
        User ${var.admin_username}
        IdentityFile ~/.ssh/bastion_key
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null

    Host private-server
        HostName ${aws_instance.private.private_ip}
        User ${var.admin_username}
        IdentityFile ~/.ssh/private_key
        ProxyJump bastion
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
    EOT
}

output "bastion_key_path" {
  description = "Path to bastion private key (if generated)"
  value       = var.create_ssh_keys ? "${path.module}/bastion_key" : "Use your existing key"
}

output "private_key_path" {
  description = "Path to private server private key (if generated)"
  value       = var.create_ssh_keys ? "${path.module}/private_key" : "Use your existing key"
}

output "bastion_mfa_setup_command" {
  description = "Command to run on bastion to set up MFA for admin user (run after first login)"
  value       = "google-authenticator -t -d -f -r 3 -R 30 -W"
}

output "security_groups" {
  description = "Security group IDs"
  value = {
    bastion_sg = aws_security_group.bastion.id
    private_sg = aws_security_group.private.id
  }
}

output "key_pair_names" {
  description = "SSH key pair names"
  value = {
    bastion = aws_key_pair.bastion.key_name
    private = aws_key_pair.private.key_name
  }
}