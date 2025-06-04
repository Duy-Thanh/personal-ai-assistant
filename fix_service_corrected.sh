#!/bin/bash
# Fix Service Configuration - CORRECTED VERSION
# This will recreate the systemd service with correct paths

set -e

echo "🔧 Fixing Personal AI Assistant Service (CORRECTED)"
echo "=================================================="

# Step 1: Find where the API file actually exists
API_LOCATION=""
if [ -f "/home/$USER/personal-ai-assistant/fast_chatbot_api.py" ]; then
    API_LOCATION="/home/$USER/personal-ai-assistant/fast_chatbot_api.py"
    PROJECT_DIR="/home/$USER/personal-ai-assistant"
elif [ -f "/home/$USER/fast_chatbot_api.py" ]; then
    API_LOCATION="/home/$USER/fast_chatbot_api.py"
    PROJECT_DIR="/home/$USER"
else
    echo "❌ Cannot find fast_chatbot_api.py in expected locations"
    echo "Searching current directory..."
    if [ -f "$(pwd)/fast_chatbot_api.py" ]; then
        API_LOCATION="$(pwd)/fast_chatbot_api.py"
        PROJECT_DIR="$(pwd)"
    else
        echo "❌ Cannot find fast_chatbot_api.py anywhere. Exiting."
        exit 1
    fi
fi

echo "📍 Found API at: $API_LOCATION"
echo "📁 Project directory: $PROJECT_DIR"

# Step 2: Ensure we're working in the correct project directory
cd "$PROJECT_DIR"

# Step 3: Ensure all required files are in the project directory
echo "🔧 Ensuring all files are in project directory..."
if [ ! -f "$PROJECT_DIR/fast_chatbot_api.py" ]; then
    echo "❌ API file missing from project directory!"
    exit 1
fi

# Copy additional files if they exist elsewhere
for file in index.html landing.html requirements.txt .env; do
    if [ ! -f "$PROJECT_DIR/$file" ] && [ -f "/home/$USER/$file" ]; then
        echo "📋 Copying $file to project directory..."
        cp "/home/$USER/$file" "$PROJECT_DIR/"
    fi
done

# Step 4: Create/update virtual environment
echo "🐍 Setting up virtual environment..."
if [ -d "venv" ]; then
    echo "🗑️ Removing old virtual environment..."
    rm -rf venv
fi

echo "🔧 Creating fresh virtual environment..."
python3 -m venv venv

# Activate and install dependencies
source venv/bin/activate
echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install flask flask-cors requests ollama python-dotenv gunicorn

# Verify gunicorn installation
GUNICORN_PATH="$PROJECT_DIR/venv/bin/gunicorn"
if [ ! -f "$GUNICORN_PATH" ]; then
    echo "❌ Gunicorn installation failed"
    exit 1
fi

echo "✅ Gunicorn installed at: $GUNICORN_PATH"

# Step 5: Test gunicorn manually first
echo "🧪 Testing gunicorn manually..."
timeout 10s $GUNICORN_PATH --bind 127.0.0.1:5001 --timeout 30 fast_chatbot_api:app &
GUNICORN_PID=$!
sleep 3

if kill -0 $GUNICORN_PID 2>/dev/null; then
    echo "✅ Gunicorn test successful"
    kill $GUNICORN_PID 2>/dev/null || true
else
    echo "❌ Gunicorn test failed"
    exit 1
fi

# Step 6: Stop existing service
echo "🛑 Stopping existing service..."
sudo systemctl stop personal-ai-assistant 2>/dev/null || true

# Step 7: Create wrapper script for reliable systemd execution
echo "📝 Creating service wrapper script..."
cat > "$PROJECT_DIR/start_service.sh" << 'EOF'
#!/bin/bash
set -e
cd /home/btldtdm1005/personal-ai-assistant
source venv/bin/activate
exec gunicorn --workers 2 --bind 127.0.0.1:5000 --timeout 650 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 fast_chatbot_api:app
EOF

chmod +x "$PROJECT_DIR/start_service.sh"
echo "✅ Wrapper script created at: $PROJECT_DIR/start_service.sh"

# Verify the wrapper script content and permissions
echo "🔍 Verifying wrapper script..."
ls -la "$PROJECT_DIR/start_service.sh"
echo "📄 Wrapper script content:"
cat "$PROJECT_DIR/start_service.sh"

# Step 8: Test the wrapper script
echo "🧪 Testing wrapper script..."
timeout 10s "$PROJECT_DIR/start_service.sh" &
WRAPPER_PID=$!
sleep 3

if kill -0 $WRAPPER_PID 2>/dev/null; then
    echo "✅ Wrapper script test successful"
    kill $WRAPPER_PID 2>/dev/null || true
else
    echo "❌ Wrapper script test failed"
    exit 1
fi

# Step 9: Create new service file using wrapper script approach
echo "📝 Creating corrected systemd service..."
sudo tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << 'EOF'
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=btldtdm1005
Group=btldtdm1005
WorkingDirectory=/home/btldtdm1005/personal-ai-assistant
ExecStart=/bin/bash /home/btldtdm1005/personal-ai-assistant/start_service.sh
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

# Security settings (relaxed for troubleshooting)
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Service file created with wrapper script approach:"
echo "   WorkingDirectory: /home/btldtdm1005/personal-ai-assistant"
echo "   ExecStart: /bin/bash /home/btldtdm1005/personal-ai-assistant/start_service.sh"

# Step 10: Reload and start service
echo "🔄 Reloading systemd configuration..."
sudo systemctl daemon-reload
sudo systemctl enable personal-ai-assistant

echo "🚀 Starting service..."
sudo systemctl start personal-ai-assistant

# Wait for startup
sleep 5

# Step 11: Verify service status
if sudo systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ Service is running!"
    
    # Test the API
    sleep 2
    if curl -s http://localhost:5000/health >/dev/null; then
        echo "✅ API is responding!"
        echo ""
        echo "🌐 Success! Your API is running at:"
        echo "   Local: http://localhost:5000/"
        echo "   Public: http://$(curl -s ifconfig.me):5000/"
        echo ""
        echo "📱 Test endpoints:"
        echo "   Landing: http://$(curl -s ifconfig.me):5000/"
        echo "   Chat: http://$(curl -s ifconfig.me):5000/chat"
    else
        echo "⚠️ Service running but API not responding yet..."
        echo "📋 Recent logs:"
        sudo journalctl -u personal-ai-assistant --no-pager -n 10
    fi
else
    echo "❌ Service failed to start"
    echo "📋 Service status:"
    sudo systemctl status personal-ai-assistant --no-pager -l
    echo ""
    echo "📋 Recent logs:"
    sudo journalctl -u personal-ai-assistant --no-pager -n 20
    echo ""
    echo "🔧 Manual troubleshooting:"
    echo "   cd $PROJECT_DIR"
    echo "   source venv/bin/activate"
    echo "   python fast_chatbot_api.py"
fi

echo ""
echo "📊 Monitor service logs:"
echo "sudo journalctl -u personal-ai-assistant -f"
