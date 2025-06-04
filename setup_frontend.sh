#!/bin/bash

# Setup Web Frontend Script
# Run this after deploying the API to add the professional frontend

set -e

echo "🎨 Setting up Professional Web Frontend..."
echo "========================================"

# Navigate to project directory
cd /home/$USER/personal-ai-assistant

# Check if at least one frontend file exists
if [ ! -f "index.html" ] && [ ! -f "landing.html" ]; then
    echo "⚠️  No frontend files found. The API will use fallback interfaces."
fi

# Create static assets directory
mkdir -p static/css static/js static/images

# Create favicon
cat > static/images/favicon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <circle cx="50" cy="50" r="45" fill="#0066cc"/>
  <text x="50" y="70" font-family="Arial" font-size="60" text-anchor="middle" fill="white">🤖</text>
</svg>
EOF

# Create robots.txt for SEO
cat > robots.txt << 'EOF'
User-agent: *
Allow: /
Sitemap: /sitemap.xml
EOF

# Create basic nginx configuration (optional)
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (future enhancement)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Static files (if needed)
    location /static/ {
        alias /home/USER_PLACEHOLDER/personal-ai-assistant/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Replace USER_PLACEHOLDER with actual username
sed -i "s/USER_PLACEHOLDER/$USER/g" nginx.conf

# Restart the API service to pick up the new frontend
echo "🔄 Restarting API service..."
sudo systemctl restart personal-ai-assistant

# Wait for service to start
sleep 3

# Test the service
if sudo systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ API service restarted successfully!"
else
    echo "❌ API service failed to restart. Checking logs..."
    sudo systemctl status personal-ai-assistant
    exit 1
fi

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me)

echo "========================================"
echo "🎉 Professional Web Frontend Ready!"
echo "========================================"
echo "🏠 Landing Page: http://$EXTERNAL_IP:5000/"
echo "💬 Chat Interface: http://$EXTERNAL_IP:5000/chat"
echo "📱 Mobile-friendly responsive design"
echo "✨ Features:"
echo "   • Professional landing page with stats"
echo "   • Modern ChatGPT-like chat interface"
echo "   • Real-time conversation with memory"
echo "   • Session management & statistics"
echo "   • Typing indicators & auto-resize input"
echo "   • Fully mobile responsive"
echo "========================================"
echo "📋 Optional: Setup nginx reverse proxy"
echo "   • Configuration ready in: nginx.conf"
echo "   • Install: sudo apt install nginx"
echo "   • Copy config to: /etc/nginx/sites-available/"
echo "========================================"
