#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Install Netdata via the official kickstart script
# --------------------------------------------------
apt-get update -y
apt-get install -y wget

wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
bash /tmp/netdata-kickstart.sh --non-interactive

# --------------------------------------------------
# Wait for Netdata to be fully up
# --------------------------------------------------
for i in $(seq 1 30); do
  if systemctl is-active --quiet netdata; then
    echo "Netdata service is active."
    break
  fi
  sleep 2
done

# --------------------------------------------------
# Configure a custom high-CPU alert
# --------------------------------------------------
cat > /etc/netdata/health.d/cpu_alert.conf << 'EOF'
# High CPU usage alert
template: high_cpu_usage
      on: system.cpu
    class: Utilization
     type: System
component: CPU
     calc: $user + $system + $softirq + $irq + $guest
    units: %
    every: 10s
     warn: $this > 70
     crit: $this > 80
    delay: up 30s down 30s
    info: CPU utilization is above the configured threshold
      to: sysadmin
EOF

# --------------------------------------------------
# Apply the alert configuration
# --------------------------------------------------
netdatacli reload-health > /dev/null 2>&1 || systemctl restart netdata

# --------------------------------------------------
# Log completion
# --------------------------------------------------
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "unknown")
echo "Netdata setup complete."
echo "Dashboard URL: http://${PUBLIC_IP}:19999"
echo "Alert configured: CPU > 70% (warn), CPU > 80% (crit)"
