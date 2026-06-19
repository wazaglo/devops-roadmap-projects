# 13 - Ansible Configuration Management

Provision an EC2 instance with CloudFormation and configure it using Ansible.
Part of the [roadmap.sh DevOps projects](https://roadmap.sh/devops/projects).

## Architecture

```
                         CloudFormation
  EC2 Instance (Ubuntu 22.04) ← Security Group (22, 80) ← KeyPair
                              │
                    Ansible (control machine)
                              │
              ┌───────────────┼──────────────┬──────────────┐
              ▼               ▼              ▼              ▼
             base            nginx           app            ssh
        (system setup)   (web server)   (deploy site)   (access)
```

## Prerequisites

- AWS CLI installed & configured (`aws configure`)
- Ansible installed (`pip install ansible` or `apt install ansible`)
- An SSH key pair (`~/.ssh/ansible-key.pem` and `~/.ssh/ansible-key.pub`)
- `jq` installed for JSON parsing
- Appropriate IAM permissions (EC2, CloudFormation)

## Project Structure

```
13-ansible-configuration/
├── README.md                          # This file
├── setup.yml                          # Ansible playbook (entry point)
├── inventory.ini                      # Target server IP and SSH user
├── ansible.cfg                        # Ansible configuration (optional)
├── deploy.sh                          # One-click deploy script
├── static-site.tar.gz                 # Static website tarball
├── cloudformation/
│   ├── template.yaml                  # CloudFormation stack definition
│   └── parameters.json                # Stack parameters
└── roles/
    ├── base/
    │   └── tasks/main.yml             # apt update, fail2ban, ufw, utils
    ├── nginx/
    │   ├── tasks/main.yml             # install & configure nginx
    │   └── templates/site.conf.j2     # nginx site config template
    ├── app/
    │   ├── tasks/main.yml             # deploy static site to web root
    │   └── files/static-site.tar.gz   # site archive (copied to server)
    └── ssh/
        └── tasks/main.yml             # add SSH public key
```

## Roles

| Role | Tags | Description |
|------|------|-------------|
| base | `base` | apt update/upgrade, install curl/wget/htop/git/ufw/fail2ban, enable fail2ban, configure ufw |
| nginx | `nginx` | install nginx, deploy site config template, start & enable service |
| app | `app` | copy static-site.tar.gz to server, unarchive to /var/www/html |
| ssh | `ssh` | add your public key to ubuntu user's authorized_keys |

## Quick Start

### 1. Configure parameters

Edit `cloudformation/parameters.json` — set your SSH key name and public key material.

### 2. Deploy infrastructure

```bash
aws cloudformation create-stack \
  --stack-name ansible-server \
  --template-body file://cloudformation/template.yaml \
  --parameters file://cloudformation/parameters.json

aws cloudformation wait stack-create-complete \
  --stack-name ansible-server
```

### 3. Get the public IP

```bash
aws cloudformation describe-stacks \
  --stack-name ansible-server \
  --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" \
  --output text
```

### 4. Update inventory

```bash
echo "[webserver]" > inventory.ini
echo "<PUBLIC_IP> ansible_user=ubuntu" >> inventory.ini
```

### 5. Run Ansible

```bash
ansible-playbook setup.yml
```

### Or use the automated deploy script

```bash
chmod +x deploy.sh
./deploy.sh
```

## Running Selective Roles

```bash
# Run only nginx role
ansible-playbook setup.yml --tags "nginx"

# Run only app role
ansible-playbook setup.yml --tags "app"

# Skip base role
ansible-playbook setup.yml --skip-tags "base"
```

## Verifying the Setup

```bash
curl http://<PUBLIC_IP>
# Should return the static site HTML
```

## Stretch Goal

Modify `roles/app/tasks/main.yml` to pull from a GitHub repository instead:

```yaml
- name: clone repo
  git:
    repo: https://github.com/your-username/your-repo.git
    dest: /var/www/html
```

## Cleanup

```bash
aws cloudformation delete-stack --stack-name ansible-server
```
