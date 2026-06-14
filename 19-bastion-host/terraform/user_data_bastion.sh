#!/bin/bash
set -euo pipefail

# --------------------------------------------------
# Bastion Host Setup - Basic Hardening + fail2ban
# MFA (google-authenticator) will be configured manually after deployment
# --------------------------------------------------

exec > /var/log/user_data_bastion.log 2>&1
echo "=== Bastion Host Setup Started at $(date) ==="

# --------------------------------------------------
# System Update & Base Packages
# --------------------------------------------------
apt-get update -y
apt-get install -y \
    fail2ban \
    curl \
    wget \
    vim \
    htop \
    libpam-google-authenticator

# --------------------------------------------------
# Create Admin User
# --------------------------------------------------
ADMIN_USER="${admin_username}"
if ! id "$ADMIN_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$ADMIN_USER"
    usermod -aG sudo "$ADMIN_USER"
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$ADMIN_USER
    chmod 440 /etc/sudoers.d/$ADMIN_USER
fi

# --------------------------------------------------
# SSH Basic Hardening (MFA config done manually later)
# --------------------------------------------------
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"

cat > "$SSHD_CONFIG" << 'SSH_EOF'
# Bastion Host SSH Configuration - Basic Hardening
# MFA (Key + Password + TOTP) to be configured manually
Port 22
Protocol 2

# Authentication
PubkeyAuthentication yes
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
# fail2ban Configuration
# --------------------------------------------------
cat > /etc/fail2ban/jail.local << 'F2B_EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
F2B_EOF

systemctl enable fail2ban
systemctl restart fail2ban

# --------------------------------------------------
# Restart SSH
# --------------------------------------------------
sshd -t && systemctl restart ssh

# --------------------------------------------------
# Final Status
# --------------------------------------------------
echo "=== Bastion Host Setup Complete at $(date) ==="
echo "Admin User: $ADMIN_USER"
echo "fail2ban: Enabled"
echo "SSH: Basic hardening applied"
echo "=== Setup Complete ==="