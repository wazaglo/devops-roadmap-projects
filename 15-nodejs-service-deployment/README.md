# Node.js Service Deployment

Project 15 of the [DevOps Roadmap](https://roadmap.sh/devops). Automate the deployment of a Node.js Express service to an AWS EC2 instance using **Terraform**, **Ansible**, and **GitHub Actions**.

---

## How It Works

```
┌──────────────────────────────────────────────────────────────────┐
│  You push code to main                                           │
│  15-nodejs-service-deployment/app/                               │
└────────────────────────┬─────────────────────────────────────────┘
                         │ GitHub Actions triggers
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  GitHub Actions Runner (ubuntu-latest)                           │
│                                                                  │
│  1. Checkout the repository                                     │
│  2. Install Ansible                                             │
│  3. Inject SSH key and EC2 IP from Secrets                      │
│  4. Run: ansible-playbook node_service.yml --tags app           │
└────────────────────────┬─────────────────────────────────────────┘
                         │ SSH into EC2
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│  AWS EC2 (Ubuntu 24.04)                                         │
│                                                                  │
│  Ansible's app role will:                                       │
│  ├── Install Node.js 22 + npm (via NodeSource)                  │
│  ├── Clone the repo into /opt/node-app/repo/                    │
│  ├── Copy app files to /opt/node-app/                           │
│  ├── npm ci --production                                        │
│  ├── Write systemd unit (node-app.service)                      │
│  └── systemctl enable --now node-app                            │
│                                                                  │
│  Result: Express server listening on port 80                     │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
              curl http://<EC2_PUBLIC_IP>
              → "Hello, world!"
```

Three tools work together:

| Tool | Role | What it does in this project |
|---|---|---|
| **Terraform** | Provisioning | Creates the EC2 instance, security group, and SSH key pair on AWS |
| **Ansible** | Configuration | Connects to the EC2 instance over SSH and sets up Node.js, clones the repo, installs dependencies, and manages the service with systemd |
| **GitHub Actions** | Automation | Triggers on every push to `main` and runs the Ansible playbook automatically |

---

## Project Structure

```
15-nodejs-service-deployment/
│
├── README.md                           # This file
│
├── app/                                # Node.js service source code
│   ├── package.json                    # Express dependency
│   ├── server.js                       # GET / → "Hello, world!"
│   └── .gitignore                      # node_modules, .env
│
├── terraform/                          # AWS infrastructure as code
│   ├── provider.tf                     # AWS provider (~> 6.0), region
│   ├── variables.tf                    # region, instance_type, keys
│   ├── main.tf                         # EC2, Security Group, Key Pair
│   ├── outputs.tf                      # public_ip, ssh_command, service_url
│   ├── user_data.sh                    # First-boot script (installs python3)
│   └── terraform.tfvars.example        # Template for your variables
│
├── ansible/                            # Configuration management
│   ├── ansible.cfg                     # Ansible control node settings
│   ├── inventory.ini                   # Target server IP (fill after terraform)
│   ├── node_service.yml                # Playbook: runs the app role
│   └── roles/
│       └── app/
│           ├── tasks/main.yml          # Install Node.js, clone, deps, systemd
│           ├── templates/
│           │   └── node-app.service.j2  # systemd unit template
│           └── handlers/
│               └── main.yml            # restart node-app handler
│
└── .github/
    └── workflows/
        └── deploy.yml                  # CI/CD: Ansible in GitHub Actions
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) >= 2.15
- AWS CLI configured (`aws configure`)
- An SSH key pair (e.g., `~/.ssh/id_rsa.pub` / `~/.ssh/id_rsa`)
- GitHub repository with Actions enabled

---

## SSH Key Setup

This project uses one SSH key pair for two purposes:

| Where | What it's called | What it's used for |
|---|---|---|
| Your machine | `~/.ssh/id_rsa` (private, `chmod 600`) | Terraform imports the **public** key into AWS |
| AWS EC2 | `devops-nodejs-key` | AWS injects the public key into `ubuntu`'s `authorized_keys` at launch |
| Ansible control node | `~/.ssh/aws-key.pem` (private) | Referenced in `ansible.cfg` so Ansible can SSH into the EC2 instance |
| GitHub Actions | `PROJECT15_SSH_PRIVATE_KEY` (secret) | Written to `~/.ssh/aws-key.pem` so the runner can SSH into EC2 |

**In short:** You need one key pair. The public key goes into Terraform (to create the AWS key pair). The private key goes into `ansible.cfg` (local Ansible) and GitHub Secrets (CI/CD Ansible).

---

## Task #1: Manual Deployment

### Step 1: Provision the EC2 Instance with Terraform

```bash
cd 15-nodejs-service-deployment/terraform

# Create your variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars - paste your public SSH key into the public_key field

terraform init
terraform plan
terraform apply -auto-approve
```

**What Terraform creates:**

| Resource | Type | Purpose |
|---|---|---|
| `aws_key_pair.devops_key` | Key Pair | Imports your SSH public key so AWS injects it into the instance |
| `aws_security_group.nodejs_sg` | Security Group | Opens port 22 (SSH) and port 80 (HTTP) to the internet |
| `aws_instance.nodejs_server` | EC2 Instance | Ubuntu 24.04 with 20GB gp3 SSD. On first boot, `user_data.sh` installs Python3 - required by Ansible |

After apply completes, get the public IP:

```bash
terraform output public_ip
# Example: 54.123.45.67

terraform output ssh_command
# Example: ssh ubuntu@54.123.45.67

terraform output service_url
# Example: http://54.123.45.67
```

### Step 2: Update Ansible Inventory

Edit `15-nodejs-service-deployment/ansible/inventory.ini` and replace `<PUBLIC_IP>` with the IP from `terraform output public_ip`:

```ini
[webserver]
54.123.45.67 ansible_user=ubuntu
```

Also ensure your SSH private key path is correct in `ansible.cfg`:

```ini
private_key_file = ~/.ssh/aws-key.pem
```

### Step 3: Run the Ansible Playbook

```bash
cd 15-nodejs-service-deployment/ansible
ansible-playbook node_service.yml --tags app
```

**What the `app` role does (every time you run it):**

| # | Ansible Task | What happens |
|---|---|---|
| 1 | Install system packages | Ensures `curl` and `git` are present |
| 2 | Add NodeSource GPG key | Downloads NodeSource's signing key so apt trusts the repo |
| 3 | Add NodeSource repository | Adds `deb https://deb.nodesource.com/node_22.x nodistro main` to apt sources |
| 4 | Install Node.js + npm | `apt install nodejs` pulls in Node.js 22 and npm |
| 5 | Create `/opt/node-app/` | Ensures the working directory exists |
| 6 | Clone the repository | `git clone` from GitHub into `/opt/node-app/repo/`. If already cloned, `git pull` via `force: yes` |
| 7 | Copy app files | Syncs `/opt/node-app/repo/15-nodejs-service-deployment/app/` to `/opt/node-app/` |
| 8 | npm ci --production | Installs dependencies from `package-lock.json` (faster and stricter than `npm install`) |
| 9 | Deploy systemd unit | Renders `node-app.service.j2` to `/etc/systemd/system/node-app.service` |
| 10 | Enable and start service | `systemctl daemon-reload`, `systemctl enable --now node-app` |

All tasks are **idempotent** - running the playbook multiple times produces the same result. If nothing has changed, Ansible reports `ok` and skips.

### Step 4: Verify

```bash
curl http://54.123.45.67
# Hello, world!
```

---

## The systemd Service

Terraform and Ansible set up the server. But **what keeps the Node.js process running if it crashes or the server reboots?**

The answer is **systemd**. The Ansible role deploys this unit file:

```ini
[Unit]
Description=Node.js Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/node /opt/node-app/server.js
Restart=always
RestartSec=5
User=root
WorkingDirectory=/opt/node-app
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Key settings:

| Setting | Purpose |
|---|---|
| `Restart=always` | If the process exits for any reason (crash, `杀`, OOM killer), systemd automatically restarts it |
| `RestartSec=5` | Waits 5 seconds before restarting (prevents restart loops) |
| `WorkingDirectory=/opt/node-app` | Sets the working directory so `require('./...')` paths resolve correctly |
| `WantedBy=multi-user.target` | The service starts automatically when the server boots |

You can inspect the service manually if you SSH into the server:

```bash
sudo systemctl status node-app
sudo journalctl -u node-app -f    # Tail the logs
```

---

## Task #2: Automated Deployment with GitHub Actions

### How the Workflow Works

The file `.github/workflows/deploy.yml` triggers on every push to `main` that changes files in `15-nodejs-service-deployment/`.

```yaml
name: Deploy Node.js Service (Project 15)

on:
  push:
    branches:
      - main
    paths:
      - '15-nodejs-service-deployment/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # 1. Checkout the repository
      - uses: actions/checkout@v4

      # 2. Install Ansible on the runner
      - run: sudo apt-get install -y ansible

      # 3. Write the SSH private key to ~/.ssh/aws-key.pem
      #    (matches the path in ansible.cfg)
      - run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.PROJECT15_SSH_PRIVATE_KEY }}" > ~/.ssh/aws-key.pem
          chmod 600 ~/.ssh/aws-key.pem

      # 4. Write the EC2 IP into inventory.ini
      - run: |
          cat > 15-nodejs-service-deployment/ansible/inventory.ini <<EOF
          [webserver]
          ${{ secrets.PROJECT15_EC2_HOST }} ansible_user=ubuntu
          EOF

      # 5. Run exactly the same playbook you ran manually
      - run: |
          cd 15-nodejs-service-deployment/ansible
          ansible-playbook node_service.yml --tags app
```

**This is Option 1 from the project spec** - running `ansible-playbook` inside the GitHub Actions runner. The runner acts as the Ansible control node, exactly as your local machine did in Task #1.

### Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret | Value |
|---|---|
| `PROJECT15_EC2_HOST` | Public IP from `terraform output public_ip` |
| `PROJECT15_SSH_PRIVATE_KEY` | The **entire contents** of your private key file (e.g., `cat ~/.ssh/aws-key.pem`) |

### Trigger a Deployment

Push a change to the `app/` directory:

```bash
git add 15-nodejs-service-deployment/app/server.js
git commit -m "Update Node.js service"
git push origin main
```

The workflow automatically runs the Ansible playbook, which pulls the latest code from GitHub, re-installs dependencies if `package.json` changed, and restarts the service via the systemd handler.

---

## Infrastructure as Code Principles

This project demonstrates three core IaC principles:

### 1. Declarative Configuration

Both Terraform and Ansible are **declarative** - you describe the desired state, and the tool figures out what to change:

- **Terraform:** "I want an EC2 instance with this AMI, this security group, and this key pair." Terraform compares the current state against your config and creates/updates/destroys resources to match.
- **Ansible:** "I want Node.js installed, this repo cloned, these dependencies installed, this service running." Ansible checks each task and only makes changes if the current state doesn't match.

### 2. Idempotency

Running the same configuration multiple times produces the same result. If nothing needs changing, nothing changes.

### 3. Automation

The same Ansible playbook runs both locally (Task #1) and in CI/CD (Task #2). No changes needed, the playbook is the single source of truth for server configuration.

---

## Troubleshooting

| Error | Likely Cause | Fix |
|---|---|---|
| `terraform apply` hangs | AWS credentials not configured | Run `aws configure` or set `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars |
| `FAILED: [54.123.45.67] => UNREACHABLE!` | Wrong IP in `inventory.ini` or security group blocks SSH | Verify `terraform output public_ip`. Ensure SG allows port 22. Try `ssh ubuntu@<IP>` manually |
| `Permission denied (publickey)` | Wrong private key or wrong user | Check `private_key_file` in `ansible.cfg`. Default user for Ubuntu 24.04 is `ubuntu` |
| `npm ci` fails | `package-lock.json` missing or outdated | Run `npm install` locally to generate `package-lock.json`, then commit and push |
| `systemctl enable node-app` fails | systemd unit has a syntax error | SSH into the server and run `journalctl -xe` or `systemctl status node-app.service` |
| GitHub Actions workflow fails | Secrets not set or outdated | Go to Settings → Secrets → check `PROJECT15_EC2_HOST` (IP changed?) and `PROJECT15_SSH_PRIVATE_KEY` |
| `Node.js service running on port 80` but curl returns nothing | Security group missing port 80 | Check SG inbound rules. If missing, update `main.tf` and `terraform apply` again |
| `Could not resolve host: deb.nodesource.com` | Server has no internet access | EC2 in a private subnet? Ensure it has a route to the internet (public subnet + IGW) |

---

## Clean Up

```bash
cd 15-nodejs-service-deployment/terraform
terraform destroy -auto-approve
```

This terminates the EC2 instance, deletes the security group, and removes the key pair from AWS.

---

## Skills Demonstrated

| Skill | How |
|---|---|
| **Node.js** | Express server with a single `/` route |
| **Infrastructure as Code** | Terraform provisions EC2, security group, and key pair |
| **Configuration Management** | Ansible idempotently configures the server |
| **Cloud Computing** | AWS EC2 (Ubuntu 24.04) |
| **CI/CD** | GitHub Actions automatically deploys on every push |
| **Linux Administration** | systemd service management, NodeSource repo setup |
| **Secrets Management** | SSH keys and server IPs stored as GitHub Secrets |
| **Idempotent Deployments** | Same Ansible playbook works locally and in CI/CD |

---

## Project URL

https://roadmap.sh/projects/nodejs-service-deployment
