#!/bin/bash
# Deploy API Script for Port 80 (Production Setup)
# This deploys the API on port 80 with nginx reverse proxy

set -e

echo "🚀 Deploying Personal AI Assistant on Port 80..."
echo "=============================================="

# Check if running as root for port 80 access
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run with sudo for port 80 access:"
    echo "   sudo ./deploy_port80.sh"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
if [ -z "$ACTUAL_USER" ]; then
    echo "❌ Cannot determine actual user. Please run: sudo -u username ./deploy_port80.sh"
    exit 1
fi

echo "👤 Deploying for user: $ACTUAL_USER"

# Navigate to project directory
cd /home/$ACTUAL_USER/personal-ai-assistant

# Install nginx
echo "📦 Installing nginx..."
apt update
apt install -y nginx

# Create nginx configuration
echo "⚙️ Configuring nginx reverse proxy..."
tee /etc/nginx/sites-available/personal-ai-assistant > /dev/null << EOF
server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Handle static files (if any)
    location /static/ {
        alias /home/$ACTUAL_USER/personal-ai-assistant/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (for future upgrades)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:5000/health;
        access_log off;
    }

    # Error pages
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
        internal;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/personal-ai-assistant /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
nginx -t

# Update systemd service to run as regular user (not on port 80 directly)
echo "⚙️ Updating systemd service..."
tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << EOF
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=/home/$ACTUAL_USER/personal-ai-assistant
Environment=PATH=/home/$ACTUAL_USER/personal-ai-assistant/venv/bin
ExecStart=/home/$ACTUAL_USER/personal-ai-assistant/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:5000 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 fast_chatbot_api:app
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/home/$ACTUAL_USER/personal-ai-assistant

[Install]
WantedBy=multi-user.target
EOF

# Update firewall rules
echo "🔥 Updating firewall rules..."
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Reload systemd and restart services
echo "🔄 Reloading and starting services..."
systemctl daemon-reload
systemctl enable personal-ai-assistant
systemctl enable nginx

# Start/restart services
systemctl restart personal-ai-assistant
systemctl restart nginx

# Wait a moment for services to start
sleep 3

# Check service status
echo "📊 Service Status:"
echo "=================="
systemctl is-active personal-ai-assistant || echo "❌ Personal AI Assistant service failed"
systemctl is-active nginx || echo "❌ Nginx service failed"
systemctl is-active ollama || echo "❌ Ollama service failed"

echo ""
echo "✅ Deployment Complete!"
echo "======================"
echo "🌐 Your API is now available at: http://$(curl -s ifconfig.me)/"
echo "🔗 Chat interface: http://$(curl -s ifconfig.me)/chat"
echo "📊 Health check: http://$(curl -s ifconfig.me)/health"
echo ""
echo "📝 Commands to monitor:"
echo "  sudo systemctl status personal-ai-assistant"
echo "  sudo systemctl status nginx"
echo "  sudo journalctl -u personal-ai-assistant -f"
echo "  sudo journalctl -u nginx -f"
echo ""
echo "🔧 To test locally:"
echo "  curl http://localhost/"
echo "  curl http://localhost/health"
