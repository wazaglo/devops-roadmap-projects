#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Cleanup - Remove Netdata and test artifacts
# --------------------------------------------------

echo "=== Netdata Cleanup ==="
echo ""

# Stop and disable Netdata service
if systemctl is-active --quiet netdata 2>/dev/null; then
  echo "Stopping Netdata service..."
  sudo systemctl stop netdata
fi

if systemctl is-enabled --quiet netdata 2>/dev/null; then
  echo "Disabling Netdata service..."
  sudo systemctl disable netdata
fi

# Remove Netdata packages and configuration
echo "Removing Netdata packages..."
sudo apt-get remove --purge -y netdata netdata-core netdata-web netdata-plugins-bash 2>/dev/null || true
sudo apt-get autoremove --purge -y

echo "Removing Netdata configuration and data directories..."
sudo rm -rf /etc/netdata /var/lib/netdata /var/log/netdata /var/cache/netdata
sudo rm -f /tmp/netdata-kickstart.sh

# Remove Netdata user and group
sudo userdel -r netdata 2>/dev/null || true
sudo groupdel netdata 2>/dev/null || true

# Kill any remaining stress-ng processes
echo "Killing any remaining stress-ng processes..."
pkill stress-ng 2>/dev/null || true

# Remove temp test files
rm -f /tmp/stress-test-*

echo ""
echo "=== Netdata has been removed from the system ==="
