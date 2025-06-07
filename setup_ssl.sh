#!/bin/bash

# Let's Encrypt SSL Setup Script for Personal AI Assistant
# This script sets up SSL certificates using Let's Encrypt and configures NGINX

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons."
   print_error "Run it as your regular user. It will prompt for sudo when needed."
   exit 1
fi

echo "=============================================="
echo "   Personal AI Assistant SSL Setup"
echo "   Let's Encrypt + NGINX Configuration"
echo "=============================================="
echo ""

# Get domain name
echo -e "${BLUE}Please enter your domain name (e.g., myassistant.example.com):${NC}"
read -p "Domain: " DOMAIN

if [[ -z "$DOMAIN" ]]; then
    print_error "Domain name is required!"
    exit 1
fi

# Validate domain format
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    print_error "Invalid domain name format!"
    exit 1
fi

print_status "Setting up SSL for domain: $DOMAIN"

# Check if NGINX is running
if ! systemctl is-active --quiet nginx; then
    print_error "NGINX is not running. Please start NGINX first."
    exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update

# Install snapd if not already installed
if ! command -v snap &> /dev/null; then
    print_status "Installing snapd..."
    sudo apt install -y snapd
fi

# Install certbot via snap
print_status "Installing certbot..."
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot

# Create symlink for certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

# Stop NGINX temporarily for standalone authentication
print_status "Stopping NGINX temporarily for certificate generation..."
sudo systemctl stop nginx

# Generate SSL certificate
print_status "Generating SSL certificate for $DOMAIN..."
sudo certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN" || {
    print_error "Failed to generate SSL certificate!"
    print_error "Make sure:"
    print_error "1. Your domain $DOMAIN points to this server's IP"
    print_error "2. Port 80 is accessible from the internet"
    print_error "3. No firewall is blocking the connection"
    sudo systemctl start nginx
    exit 1
}

# Backup original NGINX config
print_status "Backing up original NGINX configuration..."
sudo cp /etc/nginx/sites-available/personal-ai-assistant /etc/nginx/sites-available/personal-ai-assistant.backup.$(date +%Y%m%d_%H%M%S)

# Get the current user for the static files path
ACTUAL_USER=$(whoami)

# Create new NGINX configuration with SSL
print_status "Creating new NGINX configuration with SSL..."
sudo tee /etc/nginx/sites-available/personal-ai-assistant > /dev/null <<EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$DOMAIN/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: blob: 'unsafe-inline' wss: ws:; connect-src 'self' https: wss: ws: https://*.zoho.com https://*.zohopublic.com;" always;

    # Handle static files
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
        
        # WebSocket support
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

    # Security.txt (optional but recommended)
    location /.well-known/security.txt {
        return 200 "Contact: admin@$DOMAIN\nExpires: 2025-12-31T23:59:59.000Z\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Test NGINX configuration
print_status "Testing NGINX configuration..."
if sudo nginx -t; then
    print_success "NGINX configuration is valid!"
else
    print_error "NGINX configuration test failed!"
    print_error "Restoring backup..."
    sudo cp /etc/nginx/sites-available/personal-ai-assistant.backup.* /etc/nginx/sites-available/personal-ai-assistant
    sudo systemctl start nginx
    exit 1
fi

# Start NGINX
print_status "Starting NGINX..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Test SSL certificate
print_status "Testing SSL certificate..."
sleep 5
if curl -sSf https://$DOMAIN/health > /dev/null 2>&1; then
    print_success "SSL certificate is working correctly!"
else
    print_warning "SSL test failed. This might be a temporary DNS propagation issue."
    print_warning "Try accessing https://$DOMAIN in a few minutes."
fi

# Set up automatic renewal
print_status "Setting up automatic certificate renewal..."
sudo systemctl enable snap.certbot.renew.timer

# Create renewal hook to reload NGINX
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh > /dev/null <<EOF
#!/bin/bash
systemctl reload nginx
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh

# Test automatic renewal
print_status "Testing automatic renewal (dry run)..."
if sudo certbot renew --dry-run; then
    print_success "Automatic renewal test passed!"
else
    print_warning "Automatic renewal test failed, but manual renewal should still work."
fi

# Set up firewall rules (if UFW is installed)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall rules..."
    sudo ufw allow 'Nginx Full'
    sudo ufw --force enable
fi

echo ""
echo "=============================================="
print_success "SSL Setup Complete!"
echo "=============================================="
echo ""
print_success "✅ SSL certificate generated for: $DOMAIN"
print_success "✅ NGINX configured with HTTPS"
print_success "✅ HTTP to HTTPS redirect enabled"
print_success "✅ Automatic renewal configured"
print_success "✅ Security headers added"
print_success "✅ Zoho integrations allowed in CSP"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Test your site: https://$DOMAIN"
echo "2. Update any hardcoded HTTP URLs to HTTPS"
echo "3. Update Zoho webhook URLs to use HTTPS"
echo ""
echo -e "${BLUE}Certificate Information:${NC}"
echo "📁 Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "🔑 Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo "⏰ Expires: $(sudo certbot certificates | grep -A 2 "$DOMAIN" | grep "Expiry Date" | awk '{print $3, $4}')"
echo ""
echo -e "${BLUE}Renewal:${NC}"
echo "🔄 Automatic renewal: Enabled (runs twice daily)"
echo "🧪 Test renewal: sudo certbot renew --dry-run"
echo "🔧 Manual renewal: sudo certbot renew"
echo ""
echo -e "${GREEN}Your Personal AI Assistant is now secured with SSL! 🔒${NC}"
echo ""

# Show final status
systemctl status nginx --no-pager -l