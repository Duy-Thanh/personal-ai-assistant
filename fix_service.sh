#!/bin/bash
# Fix Service Configuration
# This will recreate the systemd service with correct paths

set -e

echo "🔧 Fixing Personal AI Assistant Service"
echo "======================================"

# Find the project directory
PROJECT_DIR=""
if [ -f "/home/$USER/personal-ai-assistant/fast_chatbot_api.py" ]; then
    PROJECT_DIR="/home/$USER/personal-ai-assistant"
elif [ -f "/home/$USER/fast_chatbot_api.py" ]; then
    PROJECT_DIR="/home/$USER"
elif [ -f "$(pwd)/fast_chatbot_api.py" ]; then
    PROJECT_DIR="$(pwd)"
else
    echo "❌ Cannot find fast_chatbot_api.py. Please run from project directory."
    exit 1
fi

# Copy API file to the correct location if needed
if [ "$PROJECT_DIR" = "/home/$USER/personal-ai-assistant" ] && [ -f "/home/$USER/fast_chatbot_api.py" ]; then
    echo "📋 Copying API file to project directory..."
    cp "/home/$USER/fast_chatbot_api.py" "$PROJECT_DIR/"
    cp "/home/$USER/index.html" "$PROJECT_DIR/" 2>/dev/null || true
    cp "/home/$USER/landing.html" "$PROJECT_DIR/" 2>/dev/null || true
fi

echo "📍 Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Ensure virtual environment exists
if [ ! -d "venv" ]; then
    echo "🔧 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate and install dependencies
source venv/bin/activate
echo "📦 Installing/updating dependencies..."
pip install flask flask-cors requests ollama python-dotenv gunicorn

# Verify gunicorn installation
if [ ! -f "venv/bin/gunicorn" ]; then
    echo "❌ Gunicorn installation failed"
    exit 1
fi

echo "✅ Gunicorn found at: $PROJECT_DIR/venv/bin/gunicorn"

# Stop existing service
sudo systemctl stop personal-ai-assistant 2>/dev/null || true

# Create new service file with correct paths
echo "📝 Creating corrected systemd service..."
sudo tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << EOF
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 2 --bind 127.0.0.1:5000 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 fast_chatbot_api:app
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$PROJECT_DIR

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created"

# Test the service configuration
echo "🧪 Testing service configuration..."

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable personal-ai-assistant

# Try to start the service
echo "🚀 Starting service..."
sudo systemctl start personal-ai-assistant

# Wait a moment
sleep 5

# Check if it's running
if sudo systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ Service is running!"
    
    # Test the API
    if curl -s http://localhost:5000/health >/dev/null; then
        echo "✅ API is responding!"
        echo "🌐 Your API should work at: http://$(curl -s ifconfig.me):5000/"
    else
        echo "❌ Service running but API not responding"
        echo "📋 Checking logs..."
        sudo journalctl -u personal-ai-assistant --no-pager -n 10
    fi
else
    echo "❌ Service failed to start"
    echo "📋 Service status:"
    sudo systemctl status personal-ai-assistant --no-pager -l
    echo ""
    echo "📋 Recent logs:"
    sudo journalctl -u personal-ai-assistant --no-pager -n 20
fi

echo ""
echo "🔧 Manual fallback (if service still fails):"
echo "============================================"
echo "cd $PROJECT_DIR"
echo "source venv/bin/activate"
echo "python fast_chatbot_api.py"
echo ""
echo "📊 Monitor service:"
echo "sudo journalctl -u personal-ai-assistant -f"
