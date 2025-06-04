#!/bin/bash

# Deploy Timeout Fix for Personal AI Assistant
# Fixes the 30-second timeout issue with enhanced error handling

set -e

echo "🔧 Deploying Timeout Fix for Personal AI Assistant..."
echo "=================================================="

# Get VM IP
VM_IP="34.66.156.47"

# Function to upload file
upload_file() {
    local file=$1
    local target=$2
    echo "📤 Uploading $file..."
    scp -o StrictHostKeyChecking=no "$file" "$VM_IP:$target"
}

# Upload enhanced API file
upload_file "fast_chatbot_api.py" "/home/\$USER/personal-ai-assistant/fast_chatbot_api.py"

# Upload enhanced chat interface
upload_file "index.html" "/home/\$USER/personal-ai-assistant/index.html"

# Connect and restart services
echo "🔄 Restarting services on VM..."
ssh -o StrictHostKeyChecking=no "$VM_IP" << 'EOF'
    cd /home/$USER/personal-ai-assistant
    
    echo "🛑 Stopping current service..."
    sudo systemctl stop personal-ai-assistant || true
    
    echo "⚙️  Setting timeout environment variable..."
    sudo tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << SYSTEMD_EOF
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/personal-ai-assistant
Environment=PYTHONPATH=/home/$USER/personal-ai-assistant
Environment=OLLAMA_TIMEOUT=180
ExecStart=/home/$USER/personal-ai-assistant/venv/bin/python fast_chatbot_api.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF
    
    echo "🔄 Reloading systemd..."
    sudo systemctl daemon-reload
    
    echo "🚀 Starting enhanced service..."
    sudo systemctl start personal-ai-assistant
    sudo systemctl enable personal-ai-assistant
    
    echo "⏳ Waiting for service to start..."
    sleep 5
    
    echo "📊 Service status:"
    sudo systemctl status personal-ai-assistant --no-pager
    
    echo ""
    echo "🧪 Testing API health..."
    curl -s http://localhost:5000/health | python3 -m json.tool || echo "Health check failed"
    
    echo ""
    echo "📈 Testing stats endpoint..."
    curl -s http://localhost:5000/stats | python3 -m json.tool | head -20 || echo "Stats check failed"
EOF

echo ""
echo "✅ Timeout Fix Deployment Complete!"
echo "=================================================="
echo "🌐 Your enhanced AI assistant is now available at:"
echo "   Landing Page: http://$VM_IP/"
echo "   Chat Interface: http://$VM_IP/chat"
echo "   Health Check: http://$VM_IP/health"
echo "   Statistics: http://$VM_IP/stats"
echo ""
echo "🔧 Changes Made:"
echo "   ✅ Increased Ollama timeout from 30s to 180s (3 minutes)"
echo "   ✅ Enhanced error handling for timeout scenarios"
echo "   ✅ Progressive user feedback during long waits"
echo "   ✅ Better error messages for timeout situations"
echo "   ✅ Configurable timeout via OLLAMA_TIMEOUT environment variable"
echo ""
echo "💡 The AI can now handle complex queries that take longer to process!"
echo "   Users will see helpful messages during processing"
echo "   No more unexpected 30-second timeouts"
