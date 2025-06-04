#!/bin/bash

# Quick Start Script - Run this first!
# Combines setup and deployment for faster execution

echo "🚀 Personal AI Assistant - Quick Start"
echo "====================================="

# Check if we're on Ubuntu
if ! command -v apt &> /dev/null; then
    echo "❌ This script requires Ubuntu/Debian. Please run setup_vm.sh manually."
    exit 1
fi

# Update and install essentials
echo "📦 Installing essentials..."
sudo apt update
sudo apt install -y curl wget python3 python3-pip python3-venv

# Install Ollama
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama
sudo systemctl start ollama
sleep 10

# Download model
echo "📥 Downloading Phi-3 Mini..."
ollama pull phi3:mini

# Create project directory
mkdir -p ~/personal-ai-assistant
cd ~/personal-ai-assistant

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install flask flask-cors requests ollama gunicorn

# Copy API file (if exists in parent directory)
if [ -f "../fast_chatbot_api.py" ]; then
    cp ../fast_chatbot_api.py .
fi

echo "✅ Quick setup complete!"
echo "🌐 External IP: $(curl -s ifconfig.me)"
echo "📝 Next: Run the API with 'python3 fast_chatbot_api.py'"
echo "🔗 Then visit: http://$(curl -s ifconfig.me):5000"
