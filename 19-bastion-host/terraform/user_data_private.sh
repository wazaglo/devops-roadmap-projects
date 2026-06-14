#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Private Server Setup - Password Authentication
# Accessible only via bastion host (SG restricts to bastion-sg)
# --------------------------------------------------

exec > /var/log/user_data_private.log 2>&1
echo "=== Private Server Setup Started at $(date) ==="

# --------------------------------------------------
# System Update & Base Packages
# --------------------------------------------------
apt-get update -y
apt-get install -y \
    curl \
    wget \
    vim \
    htop

# --------------------------------------------------
# Create Admin User with Password
# --------------------------------------------------
ADMIN_USER="${admin_username}"
ADMIN_PASSWORD="${admin_password}"

if ! id "$ADMIN_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$ADMIN_USER"
    usermod -aG sudo "$ADMIN_USER"
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ADMIN_USER
    chmod 440 /etc/sudoers.d/$ADMIN_USER
fi

echo "$ADMIN_USER:$ADMIN_PASSWORD" | chpasswd

# --------------------------------------------------
# SSH Configuration - Password + Key Auth (No MFA)
# --------------------------------------------------
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

cat > "$SSHD_CONFIG" << 'SSH_EOF'
# Private Server SSH Configuration - Password + Key Auth
Port 22
Protocol 2

# Authentication - Password only (no SSH key)
PubkeyAuthentication no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes

# Security Hardening
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
PermitEmptyPasswords no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel no
DebianBanner no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

AllowUsers admin

HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
SSH_EOF

# --------------------------------------------------
# Restart SSH
# --------------------------------------------------
sshd -t && systemctl restart ssh

# --------------------------------------------------
# Final Status
# --------------------------------------------------
echo "=== Private Server Setup Complete at $(date) ==="
echo "Admin User: $ADMIN_USER"
echo "Auth: SSH Key + Password (no MFA)"
echo "Access: Via bastion host only (SG restricts to bastion-sg)"
echo "=== Setup Complete ==="