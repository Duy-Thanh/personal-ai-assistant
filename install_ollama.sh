#!/bin/bash

# Quick Ollama Installation Script
# For manual installation if setup_vm.sh fails

echo "🤖 Quick Ollama Installation..."

# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start service
sudo systemctl start ollama
sudo systemctl enable ollama

# Wait and download model
sleep 10
ollama pull phi3:mini

echo "✅ Ollama installation complete!"
echo "Test with: ollama run phi3:mini 'Hello world'"
