# Dummy Systemd Service

Project 09 of the [DevOps Roadmap](https://roadmap.sh/devops). Create a long-running systemd service that logs to a file, demonstrating Linux service management with systemd.

## Project URL

https://roadmap.sh/projects/dummy-systemd-service

---

## Architecture

```
systemd (PID 1)
      │
      ├── Reads: /etc/systemd/system/dummy.service
      │
      └── Spawns: dummy.sh
                │
                └── while true loop
                      │
                      ├── echo >> /var/log/dummy-service.log
                      │
                      └── sleep 10
                            │
                            └── repeat forever
```

**Service lifecycle:**

```
boot → systemd starts → dummy.service enabled?
                          │
                    yes ──┤
                          │
                          ▼
                    dummy.sh runs
                          │
                    every 10 seconds
                          │
                          ▼
                    log message appended
```

---

## Prerequisites

- Linux with systemd (Ubuntu 16.04+, Debian 8+, CentOS 7+, RHEL 7+)
- Root or sudo access

### Verify systemd is installed

```bash
systemctl --version
# systemd 245 or higher
```

---

## Project Structure

```
09-dummy-systemd-service/
├── dummy.sh           # Long-running script that logs every 10 seconds
├── dummy.service      # Systemd unit file
└── README.md          # This file
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/wazaglo/devops-roadmap-projects.git
cd devops-roadmap-projects/09-dummy-systemd-service
```

### 2. Install the service

```bash
# Create the installation directory
sudo mkdir -p /opt/dummy-systemd-service

# Copy the script
sudo cp dummy.sh /opt/dummy-systemd-service/dummy.sh
sudo chmod +x /opt/dummy-systemd-service/dummy.sh

# Copy the service file
sudo cp dummy.service /etc/systemd/system/dummy.service

# Reload systemd to recognize the new service
sudo systemctl daemon-reload
```

### 3. Enable and start

```bash
# Enable on boot
sudo systemctl enable dummy

# Start now
sudo systemctl start dummy
```

### 4. Verify

```bash
# Check status
sudo systemctl status dummy
```

Expected output:

```
● dummy.service - Dummy Systemd Service
     Loaded: loaded (/etc/systemd/system/dummy.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
   Main PID: 12345 (bash)
      Tasks: 1 (limit: 4657)
     Memory: 1.2M
        CPU: 15ms
     CGroup: /system.slice/dummy.service
             └─12345 /bin/bash /opt/dummy-systemd-service/dummy.sh
```

### 5. Check the logs

```bash
# Follow logs in real-time
sudo journalctl -u dummy -f

# View log file directly
sudo tail -f /var/log/dummy-service.log
```

---

## Service File Breakdown

### `[Unit]` Section

| Directive | Value | Purpose |
|-----------|-------|---------|
| `Description` | `Dummy Systemd Service` | Human-readable name shown in `systemctl status` |
| `After` | `network.target` | Start after network is available |

### `[Service]` Section

| Directive | Value | Purpose |
|-----------|-------|---------|
| `Type` | `simple` | The script runs as the main process |
| `ExecStart` | `/bin/bash /opt/dummy-systemd-service/dummy.sh` | Full path to the script |
| `Restart` | `always` | Auto-restart on failure, crash, or manual kill |
| `RestartSec` | `5` | Wait 5 seconds before restarting |

### `[Install]` Section

| Directive | Value | Purpose |
|-----------|-------|---------|
| `WantedBy` | `multi-user.target` | Enable at multi-user boot level (standard for services) |

---

## Commands Reference

### Managing the Service

| Command | Purpose |
|---------|---------|
| `sudo systemctl start dummy` | Start the service now |
| `sudo systemctl stop dummy` | Stop the service |
| `sudo systemctl restart dummy` | Stop and start again |
| `sudo systemctl enable dummy` | Auto-start on boot |
| `sudo systemctl disable dummy` | Remove from boot startup |
| `sudo systemctl status dummy` | Check if running, PID, memory usage |

### Checking Logs

| Command | Purpose |
|---------|---------|
| `sudo journalctl -u dummy -f` | Follow logs in real-time (like `tail -f`) |
| `sudo journalctl -u dummy` | Show all logs for the service |
| `sudo journalctl -u dummy --since "1h ago"` | Logs from the last hour |
| `sudo journalctl -u dummy --since today` | Logs from today |
| `sudo cat /var/log/dummy-service.log` | View the log file directly |

### Debugging

| Command | Purpose |
|---------|---------|
| `sudo systemd-analyze verify /etc/systemd/system/dummy.service` | Verify service file syntax |
| `sudo journalctl -u dummy -n 50` | Show last 50 log lines |
| `sudo systemctl show dummy` | Show all service properties |
| `ps aux | grep dummy` | Find the running process |

---

## Installation Directory

The service is installed to `/opt/dummy-systemd-service/` following Linux conventions:

| Path | Purpose |
|------|---------|
| `/opt/dummy-systemd-service/dummy.sh` | The application script |
| `/etc/systemd/system/dummy.service` | The systemd unit file |
| `/var/log/dummy-service.log` | The log file |

---

## Troubleshooting

### Service won't start

```bash
# Check if the script exists and is executable
ls -la /opt/dummy-systemd-service/dummy.sh

# If missing, reinstall
sudo cp dummy.sh /opt/dummy-systemd-service/dummy.sh
sudo chmod +x /opt/dummy-systemd-service/dummy.sh
```

### Service fails immediately

```bash
# Check status for error details
sudo systemctl status dummy

# Common issue: Wrong path in ExecStart
# Fix: Edit the service file
sudo nano /etc/systemd/system/dummy.service

# Reload after changes
sudo systemctl daemon-reload
sudo systemctl restart dummy
```

### Logs not appearing

```bash
# Check if service is running
sudo systemctl status dummy

# Check if log file exists
ls -la /var/log/dummy-service.log

# If service is running but no logs, check the script
sudo cat /opt/dummy-systemd-service/dummy.sh
```

### Permission denied

```bash
# Make script executable
sudo chmod +x /opt/dummy-systemd-service/dummy.sh

# Check file ownership
ls -la /opt/dummy-systemd-service/dummy.sh
```

### Service file syntax error

```bash
# Verify the service file
sudo systemd-analyze verify /etc/systemd/system/dummy.service

# Check systemd logs for errors
sudo journalctl -u dummy -n 20
```

---

## What I Learned

- How systemd manages services on Linux
- Writing systemd unit files with `[Unit]`, `[Service]`, and `[Install]` sections
- Using `Type=simple` for scripts that run as the main process
- Configuring `Restart=always` for automatic recovery
- Managing services with `systemctl` (start, stop, enable, disable, status)
- Viewing logs with `journalctl` and understanding log levels
- Installing services to `/opt/` following Linux conventions
- Using `daemon-reload` after modifying service files

---

## Skills Demonstrated

| Skill | How |
|-------|-----|
| Linux Administration | Service management with systemd |
| Systemd | Unit files, service lifecycle, boot configuration |
| Shell Scripting | Bash script with infinite loop and logging |
| Process Management | Background processes, auto-restart |
| Log Management | Writing to log files, using journalctl |
| Troubleshooting | Debugging service failures and log issues |

---

## Author

Wisdom Azaglo
