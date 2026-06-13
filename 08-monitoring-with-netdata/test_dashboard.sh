#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Test Dashboard - Generate system load to exercise
# the Netdata monitoring dashboard
# --------------------------------------------------

cleanup() {
  echo "Cleaning up stress processes..."
  pkill stress-ng 2>/dev/null || true
  rm -f /tmp/stress-test-*
  echo "Cleanup done."
}
trap cleanup EXIT

echo "=== Netdata Dashboard Test ==="
echo ""

# Install stress-ng if not present
if ! command -v stress-ng &>/dev/null; then
  echo "Installing stress-ng..."
  sudo apt-get update -y -qq
  sudo apt-get install -y -qq stress-ng
fi

# Determine the public IP for the dashboard URL
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || hostname -I | awk '{print $1}')
echo "Dashboard URL: http://${PUBLIC_IP}:19999"
echo ""
echo "Generating system load for 120 seconds..."
echo "Open the dashboard URL in your browser to watch the metrics."
echo "Press Ctrl+C to stop early."
echo ""

# Generate CPU load (4 workers)
echo "  [CPU] Spinning up 4 CPU workers..."
stress-ng --cpu 4 --timeout 120s &

# Generate memory pressure
echo "  [RAM] Allocating 2 x 512MB memory workers..."
stress-ng --vm 2 --vm-bytes 512M --timeout 120s &

# Generate disk I/O
echo "  [DISK] Running 2 HDD workers..."
stress-ng --hdd 2 --timeout 120s &

echo ""
echo "Load generation running in the background."
echo "Check the Netdata dashboard at: http://${PUBLIC_IP}:19999"
echo "Waiting for stress-ng to finish..."

wait
echo ""
echo "=== Test complete ==="
