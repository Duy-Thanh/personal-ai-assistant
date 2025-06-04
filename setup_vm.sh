#!/bin/bash

# Personal AI Assistant - VM Setup Script
# Day 1: Backend Foundation Setup

set -e  # Exit on any error

echo "🚀 Starting Personal AI Assistant VM Setup..."
echo "================================================"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y curl wget git python3 python3-pip python3-venv nginx ufw

# Configure firewall
echo "🔒 Configuring firewall..."
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 5000  # For our Flask API
sudo ufw allow 11434  # For Ollama API

# Install Ollama
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
echo "🎯 Starting Ollama service..."
sudo systemctl enable ollama
sudo systemctl start ollama

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
sleep 10

# Download Phi-3 Mini model
echo "📥 Downloading Phi-3 Mini model (this may take a few minutes)..."
ollama pull phi3:mini

# Alternative models (commented out - uncomment if you prefer)
# ollama pull mistral:7b
# ollama pull llama3.1:8b

# Test Ollama installation
echo "🧪 Testing Ollama installation..."
if ollama list | grep -q "phi3:mini"; then
    echo "✅ Phi-3 Mini model downloaded successfully!"
else
    echo "❌ Failed to download Phi-3 Mini model"
    exit 1
fi

# Create project directory
echo "📁 Creating project directory..."
mkdir -p /home/$USER/personal-ai-assistant
cd /home/$USER/personal-ai-assistant

# Create Python virtual environment
echo "🐍 Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install flask flask-cors requests ollama python-dotenv gunicorn

echo "✅ VM Setup Complete!"
echo "================================================"
echo "Next steps:"
echo "1. Deploy the Flask API (fast_chatbot_api.py)"
echo "2. Test the endpoints"
echo "3. Verify conversation memory"
echo "================================================"

# Test Ollama with a simple query
echo "🔍 Testing Ollama with a simple query..."
ollama run phi3:mini "Hello, introduce yourself briefly" || echo "⚠️  Manual test needed"

echo "🎉 Day 1 Morning Setup Complete!"
echo "Your LLM is ready at: http://$(curl -s ifconfig.me):11434"
