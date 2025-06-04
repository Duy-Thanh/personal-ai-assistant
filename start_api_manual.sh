#!/bin/bash
# Simple Manual Start Script
# Use this to start the API manually while we fix the systemd service

echo "🚀 Manual API Start"
echo "==================="

# Stop any systemd service first
sudo systemctl stop personal-ai-assistant 2>/dev/null || true

# Find project directory
if [ -f "/home/$USER/personal-ai-assistant/fast_chatbot_api.py" ]; then
    PROJECT_DIR="/home/$USER/personal-ai-assistant"
elif [ -f "/home/$USER/fast_chatbot_api.py" ]; then
    PROJECT_DIR="/home/$USER"
else
    echo "❌ Cannot find project files"
    exit 1
fi

cd "$PROJECT_DIR"
echo "📍 Working in: $(pwd)"

# Copy files if needed
if [ "$PROJECT_DIR" = "/home/$USER/personal-ai-assistant" ]; then
    if [ -f "/home/$USER/fast_chatbot_api.py" ]; then
        echo "📋 Copying files to project directory..."
        cp "/home/$USER/fast_chatbot_api.py" . 2>/dev/null || true
        cp "/home/$USER/index.html" . 2>/dev/null || true
        cp "/home/$USER/landing.html" . 2>/dev/null || true
    fi
fi

# Check if files exist
if [ ! -f "fast_chatbot_api.py" ]; then
    echo "❌ fast_chatbot_api.py not found in $(pwd)"
    exit 1
fi

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "❌ Virtual environment not found"
    exit 1
fi

echo ""
echo "🚀 Starting API manually..."
echo "=========================="
echo "🌐 Your API will be available at:"
echo "   http://$(curl -s ifconfig.me):5000/"
echo "   http://$(curl -s ifconfig.me):5000/chat"
echo ""
echo "⚠️  Press Ctrl+C to stop the API"
echo ""

# Start the API
python fast_chatbot_api.py
