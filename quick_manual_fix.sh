#!/bin/bash
# Quick Manual Fix for Systemd Service
echo "🔧 Quick Manual Fix for 203/EXEC Error"
echo "======================================"

# Stop the service
sudo systemctl stop personal-ai-assistant

# Create a new wrapper script with absolute paths and proper permissions
echo "📝 Creating corrected wrapper script..."
cat > /home/btldtdm1005/personal-ai-assistant/start_service.sh << 'EOF'
#!/bin/bash
set -e
cd /home/btldtdm1005/personal-ai-assistant
source venv/bin/activate
exec gunicorn --workers 2 --bind 127.0.0.1:5000 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 fast_chatbot_api:app
EOF

# Set proper permissions
chmod +x /home/btldtdm1005/personal-ai-assistant/start_service.sh

# Verify the script
echo "🔍 Verifying wrapper script..."
ls -la /home/btldtdm1005/personal-ai-assistant/start_service.sh
echo "📄 Script content:"
cat /home/btldtdm1005/personal-ai-assistant/start_service.sh

# Create simpler systemd service
echo "📝 Creating simplified systemd service..."
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

[Install]
WantedBy=multi-user.target
EOF

# Reload and start
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

echo "🚀 Starting service..."
sudo systemctl start personal-ai-assistant

sleep 3

# Check status
echo "📊 Service status:"
sudo systemctl status personal-ai-assistant --no-pager -l

if sudo systemctl is-active --quiet personal-ai-assistant; then
    echo ""
    echo "✅ SUCCESS! Service is running!"
    echo "🌐 Your API is available at:"
    echo "   http://34.66.156.47/"
    echo "   http://34.66.156.47/chat"
else
    echo ""
    echo "❌ Service still failing. Let's check logs:"
    sudo journalctl -u personal-ai-assistant --no-pager -n 10
fi
