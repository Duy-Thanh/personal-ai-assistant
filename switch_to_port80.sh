#!/bin/bash
# Quick Switch from Port 5000 to Port 80
# Run this on your existing VM to switch to port 80

set -e

echo "🔄 Switching from Port 5000 to Port 80..."
echo "======================================="

# Check if we're on the VM and have the required files
if [ ! -f "fast_chatbot_api.py" ]; then
    echo "❌ Not in the correct directory. Please run from where your files are uploaded."
    exit 1
fi

# Make the new deployment script executable
chmod +x deploy_port80.sh

# Run the port 80 deployment
echo "🚀 Running port 80 deployment..."
sudo ./deploy_port80.sh

echo ""
echo "✅ Successfully switched to Port 80!"
echo "=================================="
echo ""
echo "🌐 NEW URLs:"
echo "  Landing Page: http://$(curl -s ifconfig.me)/"
echo "  Chat Interface: http://$(curl -s ifconfig.me)/chat"
echo "  Health Check: http://$(curl -s ifconfig.me)/health"
echo ""
echo "📝 Your old port 5000 URLs will redirect automatically!"
echo "🔗 Update your Zoho webhook to: http://$(curl -s ifconfig.me)/webhook/zoho"
