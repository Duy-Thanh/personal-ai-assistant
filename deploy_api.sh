#!/bin/bash

# Deploy API Script
# Run this after VM setup is complete

set -e

echo "🚀 Deploying Personal AI Assistant API..."
echo "========================================"

# Navigate to project directory
cd /home/$USER/personal-ai-assistant

# Activate virtual environment
source venv/bin/activate

# # Copy the API file (assuming it's uploaded)
# if [ -f "../fast_chatbot_api.py" ]; then
#     cp ../fast_chatbot_api.py .
#     echo "✅ API file copied"
# else
#     echo "❌ fast_chatbot_api.py not found. Please upload it first."
#     exit 1
# fi

# Create requirements.txt
cat > requirements.txt << EOF
flask==2.3.3
flask-cors==4.0.0
requests==2.31.0
ollama==0.1.8
python-dotenv==1.0.0
gunicorn==21.2.0
EOF

# Install dependencies
echo "📚 Installing Python dependencies..."
pip install -r requirements.txt

# Create systemd service for production
sudo tee /etc/systemd/system/personal-ai-assistant.service > /dev/null << EOF
[Unit]
Description=Personal AI Assistant API
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/personal-ai-assistant
Environment=PATH=/home/$USER/personal-ai-assistant/venv/bin
ExecStart=/home/$USER/personal-ai-assistant/venv/bin/gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 120 fast_chatbot_api:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "🔧 Setting up systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable personal-ai-assistant
sudo systemctl start personal-ai-assistant

# Wait for service to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ API service started successfully!"
else
    echo "❌ API service failed to start. Checking logs..."
    sudo systemctl status personal-ai-assistant
    exit 1
fi

# Test the API
echo "🧪 Testing API endpoints..."

# Test health endpoint
echo "Testing /health endpoint..."
if curl -s http://localhost:5000/health | grep -q "healthy"; then
    echo "✅ Health endpoint working"
else
    echo "⚠️  Health endpoint test failed"
fi

# Test stats endpoint
echo "Testing /stats endpoint..."
if curl -s http://localhost:5000/stats | grep -q "total_requests"; then
    echo "✅ Stats endpoint working"
else
    echo "⚠️  Stats endpoint test failed"
fi

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me)

echo "========================================"
echo "🎉 API Deployment Complete!"
echo "========================================"
echo "🌐 Test Interface: http://$EXTERNAL_IP:5000/"
echo "📡 API Endpoints:"
echo "   • Health: http://$EXTERNAL_IP:5000/health"
echo "   • Stats:  http://$EXTERNAL_IP:5000/stats"
echo "   • Chat:   http://$EXTERNAL_IP:5000/chat (POST)"
echo "========================================"
echo "📋 Service Management:"
echo "   • Status: sudo systemctl status personal-ai-assistant"
echo "   • Logs:   sudo journalctl -u personal-ai-assistant -f"
echo "   • Restart: sudo systemctl restart personal-ai-assistant"
echo "========================================"
