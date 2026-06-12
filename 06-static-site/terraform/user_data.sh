#!/bin/bash
set -euo pipefail

# Update package list and install nginx + rsync
apt-get update -y
apt-get install -y nginx rsync

# Create web directory
mkdir -p /var/www/html

# Configure nginx for static site
cat > /etc/nginx/sites-available/default << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
}
NGINXEOF

# Test nginx configuration
nginx -t

# Enable and start nginx
systemctl enable nginx
systemctl restart nginx

# Set proper permissions for web directory (admin can deploy, nginx can serve)
chown -R admin:www-data /var/www/html
chmod -R 775 /var/www/html

# Create a default placeholder page
cat > /var/www/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deploying...</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        p { color: #666; line-height: 1.6; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Static Site Server</h1>
        <div class="spinner"></div>
        <p>Server is ready! Deploy your static site using <code>./deploy.sh</code></p>
        <p><small>Powered by Nginx on Debian 12 • Provisioned with Terraform</small></p>
    </div>
</body>
</html>
HTMLEOF