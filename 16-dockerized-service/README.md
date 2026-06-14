# Dockerized Service Deployment

Project 16 of the [DevOps Roadmap](https://roadmap.sh/devops). Dockerize a Node.js service, provision an AWS EC2 instance with Terraform, and deploy via GitHub Actions to GitHub Container Registry.

## Architecture

```
GitHub Push (main)
       │
       ▼
GitHub Actions (.github/workflows/16-deploy.yml)
       │
       ├── Job 1: Build & Push
       │     ├── Build Docker image from Dockerfile
       │     └── Push to ghcr.io/<owner>/dockerized-service
       │
       └── Job 2: Deploy
             ├── SSH into EC2 instance
             ├── Pull image from ghcr.io
             └── Run container with env vars
                   │
                   ▼
             AWS EC2 (Amazon Linux 2)
                   │
                   └── Docker Container
                         ├── GET /       → "Hello, world!"
                         └── GET /secret → Basic Auth → SECRET_MESSAGE
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 24.0
- [Terraform](https://www.terraform.io/) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- SSH key pair (ED25519 recommended)
- GitHub repository with Actions enabled

## Project Structure

```
16-dockerized-service/
├── app/
│   ├── package.json          # Express + dotenv + express-basic-auth
│   ├── server.js             # Node.js service with / and /secret routes
│   └── .env.example          # Template for required env vars
│
├── Dockerfile                # node:20-alpine based image
├── .dockerignore             # Excludes .env, node_modules, .git
├── .gitignore                # Excludes node_modules, .env, .terraform
│
├── terraform/
│   ├── provider.tf           # AWS provider (~> 5.0)
│   ├── variables.tf          # region, instance_type, key_name, public_key
│   ├── main.tf               # EC2, Security Group, Key Pair, user_data
│   ├── outputs.tf            # public_ip, ssh_command, service_url
│   └── terraform.tfvars.example
│
└── README.md

.github/workflows/
└── 16-deploy.yml             # CI/CD: build → push → deploy
```

## Getting Started

### 1. Local Development

```bash
cd 16-dockerized-service/app

# Create your .env file
cp .env.example .env
# Edit .env with your values

# Install dependencies
npm install

# Run locally
npm start
```

Test:

```bash
curl http://localhost:3000/
# Hello, world!

curl http://localhost:3000/secret
# Prompts for username/password (admin/password123)

curl -u admin:password123 http://localhost:3000/secret
# Returns the secret message
```

### 2. Build and Run Docker Image

```bash
cd 16-dockerized-service

# Build image
docker build -t dockerized-service .

# Run container (pass env vars at runtime)
docker run -d \
  --name dockerized-service \
  -p 3000:3000 \
  -e SECRET_MESSAGE="My secret" \
  -e USERNAME=admin \
  -e PASSWORD=password123 \
  dockerized-service
```

### 3. Provision AWS Infrastructure

```bash
cd 16-dockerized-service/terraform

# Create your variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your SSH public key

# Initialize and apply
terraform init
terraform plan
terraform apply
```

After apply, get the public IP:

```bash
terraform output public_ip
# Example: 54.123.45.67

terraform output ssh_command
# Example: ssh ec2-user@54.123.45.67
```

### 4. Configure GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret | Value |
|--------|-------|
| `PROJECT16_EC2_HOST` | Public IP from `terraform output public_ip` |
| `PROJECT16_EC2_USERNAME` | `ec2-user` |
| `PROJECT16_SSH_PRIVATE_KEY` | Contents of your private key file |
| `PROJECT16_SECRET_MESSAGE` | Your secret message |
| `PROJECT16_USERNAME` | Basic Auth username |
| `PROJECT16_PASSWORD` | Basic Auth password |

### 5. Deploy

Push to `main` branch:

```bash
git add 16-dockerized-service/
git commit -m "feat: add project 16 - dockerized service"
git push origin main
```

The GitHub Actions workflow will:
1. Build the Docker image
2. Push to `ghcr.io/<owner>/dockerized-service`
3. SSH into EC2 and deploy the new image

### 6. Verify

```bash
# Test the deployed service
curl http://<EC2_PUBLIC_IP>:3000/
# Hello, world!

curl -u admin:password123 http://<EC2_PUBLIC_IP>:3000/secret
# Returns your secret message
```

## Secrets Management

This project demonstrates several secrets management practices:

| Secret | Storage | How it's used |
|--------|---------|---------------|
| `.env` file | Local only (gitignored) | Local development |
| Docker image | Not baked in (.dockerignore) | Secrets passed at runtime via `-e` flags |
| GitHub Actions | Repository secrets | CI/CD pipeline authentication and env vars |
| EC2 SSH key | GitHub secret | Deploy to server without storing key in repo |
| GHCR credentials | `GITHUB_TOKEN` (automatic) | No manual token management needed |

## Teardown

### Stop the container (on EC2)

```bash
ssh ec2-user@<EC2_PUBLIC_IP>
docker stop dockerized-service
docker rm dockerized-service
```

### Destroy AWS resources

```bash
cd 16-dockerized-service/terraform
terraform destroy
```

### Remove container image (optional)

```bash
docker rmi dockerized-service
```

## Workflow Details

The GitHub Actions workflow (`.github/workflows/16-deploy.yml`) runs on every push to `main` when files in `16-dockerized-service/` change.

### Job 1: Build & Push

| Step | Action | Purpose |
|------|--------|---------|
| Checkout Repository | `actions/checkout@v4` | Clone the repo to the runner |
| Log in to GHCR | `docker/login-action@v3` | Authenticate with GitHub Container Registry using `GITHUB_TOKEN` |
| Extract metadata | `docker/metadata-action@v5` | Generate image tags (git SHA + branch name) |
| Build and push | `docker/build-push-action@v5` | Build Docker image from Dockerfile, push to `ghcr.io` |

**Image tag strategy:**
- `main` — always points to latest commit on main branch
- `sha-abc1234` — immutable tag for each commit (roll back to any version)

### Job 2: Deploy

| Step | Action | Purpose |
|------|--------|---------|
| Deploy to EC2 | `appleboy/ssh-action@v1` | SSH into the server and run deployment commands |

**What happens on the server:**

```bash
# 1. Login to GitHub Container Registry
echo "$GHCR_TOKEN" | docker login ghcr.io -u <actor> --password-stdin

# 2. Stop and remove old container (if exists)
docker stop dockerized-service || true
docker rm dockerized-service || true

# 3. Pull the new image
docker pull ghcr.io/<owner>/dockerized-service:main

# 4. Run the new container with secrets as env vars
docker run -d \
  --name dockerized-service \
  --restart unless-stopped \
  -p 3000:3000 \
  -e SECRET_MESSAGE="..." \
  -e USERNAME="..." \
  -e PASSWORD="..." \
  ghcr.io/<owner>/dockerized-service:main
```

**Why `--restart unless-stopped`:** Ensures the container automatically restarts if the server reboots, but stays stopped if you manually stop it.

---

## Security Considerations

### What's exposed

| Port | Service | Binding | Risk |
|------|---------|---------|------|
| 22 | SSH | 0.0.0.0/0 | Anyone can attempt SSH login |
| 3000 | Node.js app | 0.0.0.0/0 | Anyone can access the service |

### Production recommendations

| Area | Current | Recommended |
|------|---------|-------------|
| SSH access | Open to all IPs | Restrict to your IP only (`your.ip/32`) |
| App port | Exposed publicly | Put behind a reverse proxy (Nginx) with HTTPS |
| Basic Auth | HTTP only | Use HTTPS to prevent credential sniffing |
| Secrets | Passed via `-e` flags | Use Docker secrets or AWS Secrets Manager |
| EC2 user | `ec2-user` (default) | Create a non-root user with limited privileges |
| Docker socket | Not mounted | Keep it that way — mounting gives root access |

### What's protected

- **`.env` file** — excluded from Docker image via `.dockerignore`, excluded from git via `.gitignore`
- **SSH private key** — stored as `PROJECT16_SSH_PRIVATE_KEY` GitHub secret, never in repo
- **Secrets at runtime** — passed via `-e` flags from GitHub secrets, not baked into the image

---

## Troubleshooting

### Docker build fails

```bash
# Check you're in the right directory
cd 16-dockerized-service
docker build -t dockerized-service .

# Common issue: .dockerignore excludes app/node_modules
# Solution: Make sure app/ directory has package.json before building
ls app/package.json
```

### Container starts but crashes immediately

```bash
# Check container logs
docker logs dockerized-service

# Common issue: Missing env vars
# Solution: Pass all required env vars
docker run -d \
  -e SECRET_MESSAGE="test" \
  -e USERNAME=admin \
  -e PASSWORD=password123 \
  -p 3000:3000 \
  dockerized-service
```

### Cannot access /secret route

```bash
# Check if env vars are set inside the container
docker exec dockerized-service env | grep -E "USERNAME|PASSWORD|SECRET"

# Common issue: Env vars not passed or wrong values
# Solution: Re-create container with correct env vars
docker stop dockerized-service && docker rm dockerized-service
docker run -d --name dockerized-service -p 3000:3000 \
  -e SECRET_MESSAGE="My secret" \
  -e USERNAME=admin \
  -e PASSWORD=password123 \
  dockerized-service
```

### Terraform apply fails

```bash
# Check AWS CLI is configured
aws sts get-caller-identity

# Common issue: SSH public key not set in terraform.tfvars
# Solution: Copy the example and fill in your key
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — replace the public_key value
```

### GitHub Actions deploy job fails

```bash
# Check GitHub Secrets are set correctly
# Go to: Settings → Secrets and variables → Actions

# Common issues:
# 1. PROJECT16_EC2_HOST is wrong → Use: terraform output public_ip
# 2. PROJECT16_SSH_PRIVATE_KEY is wrong → Must be the PRIVATE key matching your public key
# 3. PROJECT16_EC2_USERNAME wrong → Use: ec2-user (Amazon Linux 2)
```

### SSH connection refused from GitHub Actions

```bash
# SSH into the server manually first
ssh -i your-key.pem ec2-user@<EC2_PUBLIC_IP>

# Check Docker is running
sudo systemctl status docker

# Check if port 3000 is in use
sudo lsof -i :3000

# Check if security group allows your IP (for manual SSH)
# AWS Console → EC2 → Security Groups → Inbound rules
```

### Container runs locally but not on EC2

```bash
# SSH into EC2 and check
ssh ec2-user@<EC2_PUBLIC_IP>

# Check if image was pulled
docker images | grep dockerized-service

# Check container status
docker ps -a | grep dockerized-service

# Check container logs
docker logs dockerized-service

# Common issue: GHCR auth failed
# Solution: Re-login manually
echo "$GHCR_TOKEN" | docker login ghcr.io -u <your-username> --password-stdin
```

## Skills Demonstrated

| Skill | How |
|-------|-----|
| Node.js | Express server with Basic Auth |
| Docker | Dockerfile, multi-stage concepts, .dockerignore |
| Container Registry | GitHub Container Registry (ghcr.io) |
| Infrastructure as Code | Terraform provisions EC2 + Security Group |
| Cloud Computing | AWS EC2 (Amazon Linux 2) |
| CI/CD | GitHub Actions workflow (build → push → deploy) |
| Secrets Management | GitHub secrets, runtime env vars, .dockerignore |
| Linux Administration | SSH, Docker installation via user_data |

## Project URL

https://roadmap.sh/projects/dockerized-service-deployment

## Author

Wisdom Azaglo
# test
