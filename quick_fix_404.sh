#!/bin/bash
# Quick Fix for 404 Error
# This script will get your API working on both port 5000 and port 80

set -e

echo "🚨 Quick Fix for 404 Error"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "fast_chatbot_api.py" ]; then
    echo "❌ Not in correct directory. Looking for project files..."
    cd /home/$USER/personal-ai-assistant 2>/dev/null || {
        echo "❌ Project directory not found. Please ensure setup was completed."
        exit 1
    }
fi

echo "📍 Working in: $(pwd)"

# First, ensure basic Flask API is running on port 5000
echo ""
echo "🔧 Step 1: Starting Flask API on Port 5000"
echo "============================================"

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "❌ Virtual environment not found. Creating one..."
    python3 -m venv venv
    source venv/bin/activate
    pip install flask flask-cors requests ollama python-dotenv gunicorn
fi

# Stop any existing services
sudo systemctl stop personal-ai-assistant 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true

# Start Flask API directly for testing
echo "🚀 Starting Flask API on port 5000..."
nohup python fast_chatbot_api.py > api.log 2>&1 &
API_PID=$!

# Wait a moment for startup
sleep 5

# Test port 5000
echo "🧪 Testing port 5000..."
if curl -s http://localhost:5000/health >/dev/null; then
    echo "✅ Port 5000 is working!"
    EXTERNAL_IP=$(curl -s ifconfig.me)
    echo "🌐 Try: http://$EXTERNAL_IP:5000/"
else
    echo "❌ Port 5000 still not working. Check logs:"
    tail -20 api.log
    exit 1
fi

echo ""
echo "🔧 Step 2: Setting up Port 80 (Optional)"
echo "========================================"

read -p "Do you want to set up port 80 with nginx? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Kill the direct Flask process
    kill $API_PID 2>/dev/null || true
    
    # Install and configure nginx
    sudo apt update
    sudo apt install -y nginx
    
    # Create nginx config
    sudo tee /etc/nginx/sites-available/personal-ai-assistant > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable site
    sudo ln -sf /etc/nginx/sites-available/personal-ai-assistant /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Update systemd service
    sudo tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << EOF
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
ExecStart=$(pwd)/venv/bin/python fast_chatbot_api.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Start services
    sudo systemctl daemon-reload
    sudo systemctl enable personal-ai-assistant
    sudo systemctl start personal-ai-assistant
    sudo systemctl restart nginx
    
    # Test port 80
    sleep 3
    if curl -s http://localhost/ >/dev/null; then
        echo "✅ Port 80 is working!"
        echo "🌐 Try: http://$EXTERNAL_IP/"
    else
        echo "❌ Port 80 setup failed. Checking logs..."
        sudo journalctl -u personal-ai-assistant --no-pager -n 10
    fi
else
    echo "✅ Port 5000 is working. You can continue with that."
fi

echo ""
echo "✅ Quick Fix Complete!"
echo "====================="
echo ""
echo "🌐 Your URLs:"
echo "  Port 5000: http://$EXTERNAL_IP:5000/"
echo "  Port 80:   http://$EXTERNAL_IP/ (if configured)"
echo ""
echo "🔍 To monitor:"
echo "  tail -f api.log  # Direct Flask logs"
echo "  sudo journalctl -u personal-ai-assistant -f  # Service logs"
