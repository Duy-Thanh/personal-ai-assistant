#!/bin/bash
# Diagnose 404 Error on Port 80
# Run this script to identify and fix the port 80 issue

echo "🔍 Diagnosing Port 80 Issue..."
echo "=============================="

# Check what's running on port 80
echo "📊 Port 80 Status:"
sudo lsof -i :80 2>/dev/null || echo "❌ Nothing listening on port 80"

echo ""
echo "📊 Port 5000 Status:"
sudo lsof -i :5000 2>/dev/null || echo "❌ Nothing listening on port 5000"

echo ""
echo "🔍 Service Status:"
echo "=================="

# Check nginx status
echo "📦 Nginx:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
    sudo systemctl status nginx --no-pager -l
else
    echo "❌ Nginx is not running"
fi

echo ""
echo "🤖 Personal AI Assistant:"
if systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ API service is running"
    sudo systemctl status personal-ai-assistant --no-pager -l
else
    echo "❌ API service is not running"
fi

echo ""
echo "🔗 Ollama:"
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama is running"
else
    echo "❌ Ollama is not running"
fi

echo ""
echo "🌐 Testing Endpoints:"
echo "===================="

# Test localhost endpoints
echo "🔍 Testing localhost:5000..."
curl -s http://localhost:5000/health 2>/dev/null && echo "✅ Flask API responding on port 5000" || echo "❌ Flask API not responding on port 5000"

echo ""
echo "🔍 Testing localhost:80..."
curl -s http://localhost:80/ 2>/dev/null && echo "✅ Port 80 responding" || echo "❌ Port 80 not responding"

echo ""
echo "📋 Recent Logs:"
echo "==============="

echo "🤖 API Logs (last 10 lines):"
sudo journalctl -u personal-ai-assistant --no-pager -n 10 || echo "No API logs found"

echo ""
echo "📦 Nginx Logs (last 5 lines):"
sudo journalctl -u nginx --no-pager -n 5 || echo "No nginx logs found"

echo ""
echo "🔧 Quick Fixes:"
echo "==============="
echo ""
echo "If Flask API is not running:"
echo "  sudo systemctl start personal-ai-assistant"
echo "  sudo systemctl enable personal-ai-assistant"
echo ""
echo "If nginx is not running:"
echo "  sudo systemctl start nginx"
echo "  sudo systemctl enable nginx"
echo ""
echo "If port 80 setup was never done:"
echo "  ./switch_to_port80.sh"
echo ""
echo "If you need to start from port 5000:"
echo "  cd /home/\$USER/personal-ai-assistant"
echo "  source venv/bin/activate"
echo "  python fast_chatbot_api.py"
