#!/bin/bash
set -e

apt-get update -y
apt-get upgrade -y

apt-get install -y fail2ban libpam-pwquality

cat <<'EOF' > /etc/security/pwquality.conf
minlen = 12
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
minclass = 4
EOF

cat <<'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
EOF

systemctl enable --now fail2ban
