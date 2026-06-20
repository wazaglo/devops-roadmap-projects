# IaC on AWS

Deploy a Debian 12 EC2 instance on AWS using Terraform, with automated security hardening via fail2ban and password complexity policies.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- AWS account with [programmatic access credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) configured
- An SSH key pair (e.g., `~/.ssh/id_rsa.pub`)

## Usage

```bash
cd terraform

# Review and adjust variables as needed
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your public key value

terraform init
terraform plan
terraform apply -auto-approve

# Connect via SSH
ssh admin@$(terraform output -raw public_ip)
```

## Resources Created

| Resource | Description |
|---|---|
| `aws_key_pair` | Imports your public SSH key into AWS |
| `aws_security_group` | Allows inbound SSH (port 22) from anywhere |
| `aws_instance` | Debian 12 EC2 with 20GB gp3 root volume |

## User Data Script

The `user_data.sh` script run on first boot:

- Updates all system packages
- Installs `fail2ban` to protect against brute-force SSH attacks
- Installs `libpam-pwquality` for password complexity enforcement
- Configures password policy (min 12 chars, all character classes required)
- Sets up fail2ban SSH jail (5 retries, 10min find window, 1hr ban)

## Clean Up

```bash
terraform destroy -auto-approve
```

## Project URL

https://roadmap.sh/projects/iac-on-digitalocean
