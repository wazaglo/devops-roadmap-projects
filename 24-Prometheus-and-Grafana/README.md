# Prometheus and Grafana Monitoring Stack

A production-ready monitoring and logging stack built with Docker Compose. Includes Prometheus for metrics collection, Grafana for visualization, Loki for log aggregation, Alloy for automatic log collection, and exporters for system, application, and database monitoring. Log data persists to AWS S3 for durability.

---

## Table of Contents

- [Architecture](#architecture)
- [Services](#services)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Step 1: Provision AWS S3 (Optional)](#step-1-provision-aws-s3-optional)
  - [Step 2: Configure Environment Variables](#step-2-configure-environment-variables)
  - [Step 3: Start the Stack](#step-3-start-the-stack)
  - [Step 4: Verify Services](#step-4-verify-services)
  - [Step 5: Create Dashboards and Alerts](#step-5-create-dashboards-and-alerts)
- [Log Collection](#log-collection)
- [S3 Log Storage](#s3-log-storage)
- [Dashboards](#dashboards)
- [Alert Rules](#alert-rules)
- [Configuration Reference](#configuration-reference)
- [Teardown](#teardown)
- [Troubleshooting](#troubleshooting)
- [What I Learned](#what-i-learned)

---

## Architecture

```
                         monitoring-network (Docker Bridge)
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  ┌─────────────┐         ┌──────────────────┐                      │
│  │   Grafana   │────────▶│    Prometheus    │◀── node-exporter:9100 │
│  │    :3000    │ metrics │      :9090       │◀── nginx-exporter:9113│
│  │             │────────▶│                  │◀── postgres-exporter:9187│
│  │             │  logs   │      Loki        │                      │
│  │             │────────▶│      :3100       │◀── alloy:12345       │
│  └─────────────┘         └──────────────────┘                      │
│                                                                     │
│  ┌───────────┐     ┌─────────────────┐     ┌───────────────┐       │
│  │   Nginx   │────▶│  Nginx Exporter │     │  PG Exporter  │       │
│  │    :80    │     │     :9113       │     │    :9187      │       │
│  └───────────┘     └─────────────────┘     └───────┬───────┘       │
│       │                                            │               │
│       │ stub_status                                │               │
│       ▼                                            ▼               │
│  ┌───────────┐                              ┌─────────────┐        │
│  │  nginx    │                              │  PostgreSQL │        │
│  │ exporter  │                              │    :5432    │        │
│  └───────────┘                              └─────────────┘        │
│                                                                     │
│  ┌────────────────┐                                                │
│  │ Node Exporter  │  Host metrics (CPU, RAM, disk, network)        │
│  │     :9100      │  Mounted: /proc, /sys, /                       │
│  └────────────────┘                                                │
│                                                                     │
│  ┌─────────────┐     ┌──────────────┐     ┌──────────────┐         │
│  │    Alloy    │────▶│     Loki     │────▶│  AWS S3      │         │
│  │   :12345    │logs │    :3100     │     │  (remote)    │         │
│  │ Docker sock │     │              │     │              │         │
│  └─────────────┘     └──────────────┘     └──────────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

**Data flow:**
- **Metrics:** Exporters → Prometheus → Grafana (query & visualize)
- **Logs:** Docker containers → Alloy → Loki → S3 (persist)
- **Queries:** Grafana → Prometheus (PromQL) / Grafana → Loki (LogQL)

---

## Services

| Service | Image | Port | Purpose | Healthcheck |
|---------|-------|------|---------|-------------|
| Prometheus | `prom/prometheus:v3.10.0` | `9090` | Metrics collection, storage, and alerting | `wget --spider localhost:9090/-/healthy` |
| Grafana | `grafana/grafana:12.4.0` | `3000` | Dashboards, visualization, alerting UI | `wget localhost:3000/api/health` |
| Loki | `grafana/loki:3.7.2` | `3100` | Log aggregation and querying (LogQL) | None (distroless image) |
| Alloy | `grafana/alloy:v1.9.0` | `12345` | Automatic Docker log collection | None |
| Node Exporter | `prom/node-exporter:v1.9.0` | `9100` | Host metrics (CPU, RAM, disk, network) | `wget localhost:9100/metrics` |
| Nginx | `nginx:stable-alpine` | `80` | Web server (monitored application) | `wget localhost:80/stub_status` |
| Nginx Exporter | `nginx/nginx-prometheus-exporter:1.5.1` | `9113` | Scrapes Nginx stub_status endpoint | None |
| PostgreSQL | `postgres:16-alpine` | `5432` | Database (monitored application) | `pg_isready -U postgres` |
| PG Exporter | `prometheuscommunity/postgres-exporter:v0.19.1` | `9187` | Scrapes PostgreSQL statistics | None |

---

## Prerequisites

### Required
- **Docker** >= 24.0 and **Docker Compose** v2+
- **curl** and **jq** (for the setup script)
- At least **4GB RAM** available for Docker
- Ports **80, 3000, 5432, 9090, 9100, 9113, 9187, 3100, 12345** available

### For S3 Log Storage (Optional)
- **Terraform** >= 1.0
- **AWS CLI** configured (`aws configure`) with credentials
- An AWS account with S3 and IAM permissions

### Check prerequisites
```bash
docker --version
docker compose version
curl --version
jq --version
terraform --version   # optional, for S3
```

---

## Project Structure

```
24-Prometheus-and-Grafana/
├── docker-compose.yml                  # Defines all 9 services
├── .env                                # Secrets and config (gitignored)
├── .gitignore
│
├── prometheus/
│   └── prometheus.yml                  # Scrape config: 4 targets
│
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasource.yml          # Auto-provisions Prometheus + Loki
│
├── loki/
│   └── loki-config.yaml                # Loki config with S3 backend
│
├── alloy/
│   └── config.alloy                    # Alloy log collection pipeline
│
├── nginx/
│   ├── nginx.conf                      # Nginx config with stub_status
│   └── index.html                      # Simple page served by nginx
│
├── dashboards/
│   ├── node-exporter.json              # System metrics (CPU, RAM, disk)
│   ├── nginx.json                      # Nginx connections & requests
│   ├── postgres.json                   # PostgreSQL connections & stats
│   └── loki.json                       # Log management (19 panels)
│
├── terraform/
│   ├── providers.tf                    # AWS provider (~> 5.0)
│   ├── variables.tf                    # bucket_name, environment, region
│   ├── main.tf                         # S3 bucket + IAM user + policy
│   ├── outputs.tf                      # Access keys + env_config
│   └── terraform.tfvars                # Your values (gitignored)
│
├── setup-monitoring.sh                 # Creates dashboards + alerts via API
└── README.md
```

---

## Getting Started

### Step 1: Provision AWS S3 (Optional)

If you want Loki to store logs in S3 instead of local disk, provision the AWS resources first. If you skip this, Loki will use local storage (logs are lost when containers are removed).

```bash
cd 24-Prometheus-and-Grafana/terraform/

# Initialize Terraform
terraform init

# Plan what will be created
terraform plan

# Create the S3 bucket + IAM user
terraform apply -var="bucket_name=my-loki-logs-$(date +%s)" -var="region=eu-west-1"
```

**Note:** S3 bucket names must be globally unique across all AWS. The command above appends a timestamp to make it unique.

After `terraform apply` completes, get the credentials:

```bash
# Option 1: Get everything formatted for .env
terraform output env_config

# Option 2: Get individual values
terraform output -raw access_key_id
terraform output -raw secret_access_key
terraform output region
terraform output bucket_name
```

### Step 2: Configure Environment Variables

The `.env` file contains all secrets and configuration. Edit it with your values:

```bash
cd 24-Prometheus-and-Grafana/
```

Open `.env` and update the placeholders:

```bash
# ============================================
# Grafana credentials (change for production)
# ============================================
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin

# ============================================
# PostgreSQL credentials
# ============================================
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=monitoring

# ============================================
# PG Exporter connection
# ============================================
DATA_SOURCE_URI=postgres:5432/monitoring?sslmode=disable
DATA_SOURCE_USER=postgres
DATA_SOURCE_PASS=password

# ============================================
# AWS S3 for Loki log storage
# Replace with values from: terraform output env_config
# ============================================
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_REGION=eu-west-1
LOKI_BUCKET=your-unique-bucket-name
```

**Security notes:**
- The `.env` file is gitignored, never commit it
- For production, use strong passwords and rotate them regularly
- The Terraform secret key is stored in plaintext in `terraform.tfstate` - protect this file

### Step 3: Start the Stack

```bash
cd 24-Prometheus-and-Grafana/

# Pull latest images
docker compose pull

# Start all 9 services in detached mode
docker compose up -d
```

### Step 4: Verify Services

Check all containers are running:

```bash
docker compose ps
```

Expected output, all 9 containers should be `Up` or `healthy`:

```
NAME               STATUS                    PORTS
alloy               Up                        0.0.0.0:12345->12345/tcp
grafana             Up (healthy)              0.0.0.0:3000->3000/tcp
loki                Up                        0.0.0.0:3100->3100/tcp
nginx               Up (healthy)              0.0.0.0:80->80/tcp
nginx-exporter      Up                        0.0.0.0:9113->9113/tcp
node-exporter       Up (healthy)              0.0.0.0:9100->9100/tcp
postgres            Up (healthy)              0.0.0.0:5432->5432/tcp
postgres-exporter   Up                        0.0.0.0:9187->9187/tcp
prometheus          Up (healthy)              0.0.0.0:9090->9090/tcp
```

**Note:** Loki shows as `Up` without `(healthy)` because it's a distroless image with no shell tools for healthchecks. Verify it's ready:

```bash
curl http://localhost:3100/ready
# Should return: ready
```

Check Prometheus targets, all 4 should be `UP`:

```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

Or open http://localhost:9090/targets in your browser.

### Step 5: Create Dashboards and Alerts

The setup script creates dashboards and alerts via the Grafana HTTP API.

**1. Create a Service Account Token:**

1. Open Grafana at http://localhost:3000
2. Log in with `admin` / `admin`
3. Go to **Administration** → **Users and access** → **Service accounts**
4. Click **Add service account**
5. Name it `setup-script`, role **Admin**
6. Click **Add service account**, then **Add service account token**
7. Copy the token

**2. Run the setup script:**

```bash
export GRAFANA_TOKEN="your-service-account-token-here"
./setup-monitoring.sh
```

**What it creates:**
- **4 dashboards** in the "Monitoring Stack" folder
- **8 alert rules** (5 Prometheus + 3 Loki)

**3. Verify:**

Open Grafana → **Dashboards** → **Monitoring Stack** folder. You should see:
- Node Exporter - System Metrics
- Nginx - Overview
- PostgreSQL - Overview
- Loki - Log Management Overview

**4. Verify log collection:**

```bash
# Generate some nginx traffic
curl http://localhost/
curl http://localhost/stub_status

# Open Grafana → Explore → Loki datasource
# Query: {service_name="nginx"}
```

---

## Log Collection

### How it works

**Alloy** runs as a single container with access to the Docker socket (`/var/run/docker.sock`). It automatically discovers all running Docker containers and ships their logs to **Loki**.

```
Docker Containers → Alloy (reads logs) → Loki (stores logs) → S3 (persists logs)
```

### Alloy Pipeline (`alloy/config.alloy`)

1. `discovery.docker` - discovers containers via the Docker socket
2. `loki.source.docker` - reads logs from discovered containers
3. `loki.write` - pushes logs to Loki at `http://loki:3100/loki/api/v1/push`

### Automatic Labels

Each log line gets these labels automatically:
- `container_name`. Docker container name (e.g., `nginx`, `grafana`)
- `compose_service`. Docker Compose service name
- `compose_project`. Docker Compose project name
- `service_name` - same as `container_name`

### Querying Logs in Grafana

Open **Explore** → select **Loki** datasource → write LogQL queries:

```logql
# All logs from nginx
{service_name="nginx"}

# Only error logs
{service_name="nginx"} |~ "(?i)error"

# Logs from all services except alloy
{job=~".+"} != "alloy"

# Count logs per service (last 5m)
sum by(service_name) (count_over_time({job=~".+"}[5m]))

# Error rate per service
sum by(service_name) (rate({job=~".+"} |~ "(?i)error" [5m]))
```

---

## S3 Log Storage

### Why S3?

- **Durability**: S3 provides 99.999999999% (11 9's) durability
- **No local state**: logs survive container restarts and removals
- **Scalability**: S3 handles any volume of log data
- **Cost**: pay only for what you store

### How it works

1. **Terraform** creates: S3 bucket + IAM user + scoped policy
2. **Loki** authenticates with AWS using Access Key + Secret Key
3. **Loki** writes chunks and index to S3 over HTTPS
4. **Compactor** merges old chunks in S3

### IAM Permissions (scoped to one bucket)

The IAM policy only allows access to the Loki bucket:

```json
{
  "Effect": "Allow",
  "Action": ["s3:ListBucket"],
  "Resource": "arn:aws:s3:::<bucket_name>"
},
{
  "Effect": "Allow",
  "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
  "Resource": "arn:aws:s3:::<bucket_name>/*"
}
```

### Teardown AWS Resources

```bash
cd terraform/
terraform destroy -var="bucket_name=your-bucket-name" -var="region=eu-west-1"
```

---

## Dashboards

### Node Exporter - System Metrics

| Panel | Type | Description |
|-------|------|-------------|
| CPU Usage | Timeseries | CPU utilization % per instance |
| Memory Usage | Timeseries | RAM utilization % per instance |
| Disk Usage | Timeseries | Disk utilization % per mount point |
| Network Traffic | Timeseries | Bytes in/out per interface |
| System Load | Timeseries | Load average (1m, 5m, 15m) |
| Filesystem I/O | Timeseries | Read/write bytes per mount |

### Nginx - Overview

| Panel | Type | Description |
|-------|------|-------------|
| Active Connections | Timeseries | Current active connections |
| Connections Waiting | Timeseries | Idle/waiting connections |
| Connections Handled | Timeseries | Total connections handled |
| Requests/sec | Timeseries | HTTP requests per second |
| Connection States | Timeseries | Reading/writing/waiting |

### PostgreSQL - Overview

| Panel | Type | Description |
|-------|------|-------------|
| Active Connections | Timeseries | Current DB connections |
| Database Size | Stat | Total database size |
| Cache Hit Ratio | Timeseries | % of queries served from cache |
| Transactions | Timeseries | Commits and rollbacks per second |
| Tuple Operations | Timeseries | Fetched/inserted/updated/deleted rows |
| Deadlocks | Stat | Number of deadlocks |

### Loki - Log Management Overview (19 panels)

| Panel | Type | Description |
|-------|------|-------------|
| Total Log Rate | Stat | Current logs per second |
| Active Log Streams | Stat | Number of active log streams |
| Error Log Rate | Stat | Errors per second |
| Warning Rate | Stat | Warnings per second |
| Log Volume by Service | Timeseries | Which services produce the most logs |
| Error Rate by Service | Timeseries | Error frequency per service |
| Warning Rate by Service | Timeseries | Warning frequency per service |
| Log Volume by Container | Timeseries | Breakdown by Docker container |
| Log Volume Heatmap | Heatmap | Time-based heatmap of log volume |
| Top 10 Log Sources | Table | Most active log sources |
| Error Log Sources | Table | Top error sources by count |
| Recent Errors | Logs | Live filtered error log stream |
| Nginx Access Logs | Logs | Raw nginx HTTP logs |
| PostgreSQL Logs | Logs | Raw postgres logs |
| Log Volume by Compose Project | Piechart | Distribution by project |
| Log Level Distribution | Piechart | info/warn/error/debug breakdown |
| Top Error Patterns | Table | Most common error message patterns |
| Loki Ingestion Rate | Timeseries | Logs per second by service |
| Alloy Log Collection Status | Logs | Alloy error/warning logs |

---

## Alert Rules

### Prometheus Alerts

| Alert | Condition | Duration | Severity | Description |
|-------|-----------|----------|----------|-------------|
| High CPU Usage | CPU > 80% | 5m | critical | Node CPU over threshold |
| High Memory Usage | Memory > 85% | 5m | critical | Node RAM over threshold |
| High Disk Usage | Disk > 90% | 5m | warning | Disk space running low |
| Nginx Down | Target unreachable | 1m | critical | Nginx exporter not responding |
| PostgreSQL Down | Target unreachable | 1m | critical | PostgreSQL exporter not responding |

### Loki Alerts

| Alert | Condition | Duration | Severity | Description |
|-------|-----------|----------|----------|-------------|
| High Error Log Rate | Error rate > 5/s | 5m | critical | Too many error logs |
| No Logs Detected | Zero logs | 10m | warning | Possible collection failure |
| Alloy Collection Errors | Alloy errors > 0 | 5m | critical | Alloy has internal errors |

---

## Configuration Reference

### Environment Variables (`.env`)

| Variable | Description | Default |
|----------|-------------|---------|
| `GF_SECURITY_ADMIN_USER` | Grafana admin username | `admin` |
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password | `admin` |
| `POSTGRES_USER` | PostgreSQL username | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `password` |
| `POSTGRES_DB` | PostgreSQL database name | `monitoring` |
| `DATA_SOURCE_URI` | PG Exporter connection string | `postgres:5432/monitoring?sslmode=disable` |
| `DATA_SOURCE_USER` | PG Exporter username | `postgres` |
| `DATA_SOURCE_PASS` | PG Exporter password | `password` |
| `AWS_ACCESS_KEY_ID` | AWS access key for S3 | `your-access-key-id` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for S3 | `your-secret-access-key` |
| `AWS_REGION` | AWS region for S3 bucket | `eu-west-1` |
| `LOKI_BUCKET` | S3 bucket name for logs | `your-unique-bucket-name` |

### Docker Compose Ports

| Port | Service | Protocol |
|------|---------|----------|
| 80 | Nginx | HTTP |
| 3000 | Grafana | HTTP |
| 5432 | PostgreSQL | TCP |
| 9090 | Prometheus | HTTP |
| 9100 | Node Exporter | HTTP |
| 9113 | Nginx Exporter | HTTP |
| 9187 | PG Exporter | HTTP |
| 3100 | Loki | HTTP |
| 12345 | Alloy | HTTP |

### Persistent Volumes

| Volume | Service | Purpose |
|--------|---------|---------|
| `prometheus_data` | Prometheus | Time-series database |
| `grafana_data` | Grafana | Dashboards, settings |
| `pg_data` | PostgreSQL | Database files |
| `loki_data` | Loki | Local chunks and index |

---

## Teardown

### Stop containers (preserves data)
```bash
docker compose down
```

### Stop containers and remove volumes (deletes all data)
```bash
docker compose down -v
```

### Destroy AWS resources (if provisioned)
```bash
cd terraform/
terraform destroy -var="bucket_name=your-bucket-name" -var="region=eu-west-1"
```

### Full cleanup
```bash
# Stop everything
docker compose down -v

# Remove unused images
docker image prune -f

# Destroy AWS resources
cd terraform/ && terraform destroy -var="bucket_name=YOUR_BUCKET" -var="region=eu-west-1"
```

---

## Troubleshooting

### Loki won't start
```bash
# Check logs
docker logs loki

# Common issue: S3 credentials wrong
# Verify .env has correct AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
curl -s http://localhost:3100/ready
```

### Alloy not collecting logs
```bash
# Check Alpine logs
docker logs alloy

# Common issue: Docker socket not mounted
# Verify /var/run/docker.sock is mounted in docker-compose.yml
```

### Grafana can't connect to Loki
```bash
# Verify Loki is running
curl http://localhost:3100/ready

# Check Grafana datasource
curl -s -u admin:admin http://localhost:3000/api/datasources | jq '.[].name'
```

### Prometheus targets are DOWN
```bash
# Check target status
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health, lastError: .lastError}'
```

### Port conflicts
```bash
# Find what's using a port
sudo lsof -i :80
sudo lsof -i :3000

# Kill the process or change the port in docker-compose.yml
```

---

## What I Learned

- Setting up Prometheus for multi-target metric collection with custom scrape configs
- Configuring exporters (Node Exporter, Nginx Exporter, PG Exporter) for different services
- Auto-provisioning Grafana datasources (Prometheus + Loki) via YAML
- Using the Grafana HTTP API to create dashboards and alerts programmatically
- Setting up Loki for log aggregation with a single-binary config
- Configuring Alloy for automatic Docker log collection via the Docker socket
- Building comprehensive Loki dashboards with LogQL queries (19 panels)
- Creating Loki alert rules for error detection and log monitoring
- Provisioning AWS S3 buckets and IAM users with Terraform
- Configuring Loki to use S3 as a remote storage backend with env var expansion
- Writing scoped IAM policies (access to only one bucket, nothing else)
- Docker Compose networking with custom bridge networks
- Persistent volume management for stateful services
- Handling distroless container images (Loki). NOshell tools for healthchecks
- Managing secrets with `.env` files and `.gitignore`

---

## Project URL

https://roadmap.sh/projects/prometheus-grafana

---

## Author

Wisdom Azaglo
