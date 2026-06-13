# Simple Monitoring with Netdata

Real-time system monitoring dashboard using Netdata. This project provisions an EC2 instance with Terraform, installs Netdata automatically, and provides scripts to test and clean up the monitoring setup.

## Requirements

- AWS account with credentials configured
- Terraform >= 1.5.0
- SSH key pair

## Project Structure

```
08-monitoring-with-netdata/
├── terraform/
│   ├── main.tf               # EC2 instance + security group
│   ├── variables.tf           # Terraform variables
│   ├── outputs.tf             # Public IP, SSH command, dashboard URL
│   ├── provider.tf            # AWS provider configuration
│   ├── terraform.tfvars.example  # Template for your variables
│   └── user_data.sh           # Netdata installation script (runs at boot)
├── test_dashboard.sh          # Generate system load to test monitoring
├── cleanup.sh                 # Remove Netdata from the system
└── README.md
```

## Setup

1. **Configure Terraform variables**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add your SSH public key.

2. **Provision the EC2 instance**

```bash
cd terraform
terraform init
terraform apply
```

3. **Access the dashboard**

Once the instance is running, open the URL shown in the Terraform output:

```
http://<PUBLIC_IP>:19999
```

You will see real-time charts for CPU, memory, disk I/O, and more.

4. **SSH into the instance**

```bash
ssh -i /path/to/private-key ubuntu@<PUBLIC_IP>
```

5. **Run the test script**

```bash
./test_dashboard.sh
```

This generates CPU, memory, and disk load using `stress-ng`. Watch the Netdata dashboard update in real time.

6. **Clean up** (optional)

```bash
./cleanup.sh
```

Removes Netdata and its configuration from the instance.

7. **Tear down infrastructure**

```bash
cd terraform
terraform destroy
```

## Custom Alert

The user data script configures a high-CPU alert:

| Alert Name | Metric | Warning | Critical |
|---|---|---|---|
| high_cpu_usage | system.cpu | > 70% | > 80% |

Alerts are visible in the Netdata dashboard under the Alerts tab.

## What I Learned

- Provisioning cloud infrastructure with Terraform
- Installing and configuring Netdata for system monitoring
- Using EC2 user data scripts for automated setup
- Configuring custom health alerts in Netdata
- Testing monitoring dashboards with stress-ng

## Project URL

https://roadmap.sh/projects/simple-monitoring-dashboard

## Author

Wisdom Azaglo
