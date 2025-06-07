# Let's Encrypt SSL Setup Instructions

## Overview

This guide will help you set up HTTPS for your Personal AI Assistant using Let's Encrypt SSL certificates. This will resolve browser automatic redirects from HTTP to HTTPS and secure your application.

## Prerequisites

Before starting, ensure you have:

1. **A domain name** pointing to your server (e.g., `myassistant.example.com`)
2. **NGINX installed and running**
3. **Port 80 and 443 accessible** from the internet
4. **DNS configured** - your domain should resolve to your server's IP address
5. **Personal AI Assistant running** on port 5000

## Quick Setup

### Option 1: Automated Setup Script

1. **Make the setup script executable:**
   ```bash
   chmod +x setup_ssl.sh
   ```

2. **Run the setup script:**
   ```bash
   ./setup_ssl.sh
   ```

3. **Enter your domain** when prompted (e.g., `myassistant.example.com`)

4. **Wait for completion** - the script will:
   - Install certbot
   - Generate SSL certificate
   - Update NGINX configuration
   - Enable automatic renewal
   - Configure security headers

### Option 2: Manual Setup

If you prefer manual setup or need to troubleshoot:

#### Step 1: Install Certbot

```bash
# Update packages
sudo apt update

# Install snapd
sudo apt install -y snapd

# Install certbot
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
```

#### Step 2: Stop NGINX temporarily

```bash
sudo systemctl stop nginx
```

#### Step 3: Generate SSL Certificate

Replace `yourdomain.com` with your actual domain:

```bash
sudo certbot certonly --standalone -d yourdomain.com --non-interactive --agree-tos --email admin@yourdomain.com
```

#### Step 4: Update NGINX Configuration

Replace the content of `/etc/nginx/sites-available/personal-ai-assistant` with:

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS configuration
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/yourdomain.com/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: blob: 'unsafe-inline' wss: ws:; connect-src 'self' https: wss: ws: https://*.zoho.com https://*.zohopublic.com;" always;

    # Handle static files
    location /static/ {
        alias /home/$USER/personal-ai-assistant/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
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
```

#### Step 5: Test and Start NGINX

```bash
# Test configuration
sudo nginx -t

# Start NGINX
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Step 6: Set up Automatic Renewal

```bash
# Enable automatic renewal
sudo systemctl enable snap.certbot.renew.timer

# Create renewal hook
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh > /dev/null <<'EOF'
#!/bin/bash
systemctl reload nginx
EOF
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh

# Test renewal
sudo certbot renew --dry-run
```

## Domain Setup Requirements

### DNS Configuration

Your domain must point to your server. Set up an **A record**:

```
Type: A
Name: myassistant (or @)
Value: YOUR_SERVER_IP
TTL: 300
```

### Firewall Configuration

Ensure ports 80 and 443 are open:

```bash
# If using UFW
sudo ufw allow 'Nginx Full'
sudo ufw enable

# If using iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

## Testing Your SSL Setup

### 1. Basic Connectivity Test

```bash
# Test HTTP redirect
curl -I http://yourdomain.com

# Test HTTPS
curl -I https://yourdomain.com
```

### 2. SSL Certificate Test

```bash
# Check certificate details
sudo certbot certificates

# Test SSL with OpenSSL
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

### 3. Online SSL Test

Visit: https://www.ssllabs.com/ssltest/

Enter your domain to get a comprehensive SSL report.

## Troubleshooting

### Common Issues

#### 1. Domain Not Pointing to Server

**Error:** `Failed to generate SSL certificate`

**Solution:**
- Verify DNS propagation: `nslookup yourdomain.com`
- Wait for DNS to propagate (up to 48 hours)
- Use online DNS checker tools

#### 2. Port 80 Blocked

**Error:** `Connection refused on port 80`

**Solution:**
```bash
# Check if port 80 is open
sudo netstat -tlnp | grep :80

# Configure firewall
sudo ufw allow 80
sudo ufw allow 443
```

#### 3. NGINX Configuration Error

**Error:** `nginx: configuration file test failed`

**Solution:**
```bash
# Check syntax
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log

# Restore backup if needed
sudo cp /etc/nginx/sites-available/personal-ai-assistant.backup.* /etc/nginx/sites-available/personal-ai-assistant
```

#### 4. Certificate Not Found

**Error:** `SSL certificate not found`

**Solution:**
```bash
# List certificates
sudo certbot certificates

# Check file permissions
sudo ls -la /etc/letsencrypt/live/yourdomain.com/

# Regenerate if needed
sudo certbot delete --cert-name yourdomain.com
sudo certbot certonly --standalone -d yourdomain.com
```

### Log Files

Check these logs for troubleshooting:

```bash
# NGINX error log
sudo tail -f /var/log/nginx/error.log

# NGINX access log
sudo tail -f /var/log/nginx/access.log

# Certbot log
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# System log
sudo journalctl -u nginx -f
```

## Certificate Management

### Manual Renewal

```bash
# Renew all certificates
sudo certbot renew

# Renew specific certificate
sudo certbot renew --cert-name yourdomain.com

# Force renewal (if not due yet)
sudo certbot renew --force-renewal
```

### Certificate Information

```bash
# View certificate details
sudo certbot certificates

# Check expiration
sudo certbot certificates | grep -A 2 "yourdomain.com"

# View certificate content
sudo openssl x509 -in /etc/letsencrypt/live/yourdomain.com/cert.pem -text -noout
```

### Backup Certificates

```bash
# Backup entire letsencrypt directory
sudo tar -czf letsencrypt-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt

# Backup specific domain
sudo cp -r /etc/letsencrypt/live/yourdomain.com ~/ssl-backup/
```

## Security Enhancements

Your SSL setup includes these security features:

### Security Headers

- **HSTS**: Forces HTTPS for 1 year
- **X-Frame-Options**: Prevents clickjacking
- **X-XSS-Protection**: XSS filtering
- **X-Content-Type-Options**: MIME type sniffing protection
- **Referrer-Policy**: Controls referrer information
- **CSP**: Content Security Policy with Zoho domains allowed

### SSL Configuration

- **TLS 1.2 and 1.3**: Modern encryption protocols
- **Strong Ciphers**: Secure cipher suites
- **OCSP Stapling**: Improved certificate validation
- **Session Caching**: Performance optimization

## After SSL Setup

### Update Application URLs

1. **Update any hardcoded HTTP URLs** in your code to HTTPS
2. **Update Zoho webhook URLs** to use HTTPS endpoints
3. **Test all integrations** to ensure they work with HTTPS

### Performance Monitoring

```bash
# Monitor SSL certificate expiry
sudo certbot certificates

# Check SSL performance
curl -w "%{time_total}\n" -o /dev/null -s https://yourdomain.com

# Monitor NGINX performance
sudo tail -f /var/log/nginx/access.log
```

## Maintenance Schedule

### Weekly
- Check certificate expiry dates
- Review access logs for issues

### Monthly
- Test manual renewal process
- Review security headers
- Check for NGINX updates

### Quarterly
- SSL security scan with online tools
- Review and update CSP headers
- Backup certificates

---

## Quick Reference

### Important Paths
- **Certificate**: `/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
- **Private Key**: `/etc/letsencrypt/live/yourdomain.com/privkey.pem`
- **NGINX Config**: `/etc/nginx/sites-available/personal-ai-assistant`
- **Renewal Hook**: `/etc/letsencrypt/renewal-hooks/deploy/nginx-reload.sh`

### Important Commands
```bash
# Test NGINX config
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx

# Test SSL renewal
sudo certbot renew --dry-run

# Force SSL renewal
sudo certbot renew --force-renewal

# Check certificate status
sudo certbot certificates
```

🔒 **Your Personal AI Assistant is now secured with SSL!**