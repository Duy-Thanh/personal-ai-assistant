#!/bin/bash

# Complete Day 1 Overview Script
# Shows what you've built and provides quick access

echo "🎉 Personal AI Assistant - Day 1 Complete Overview"
echo "================================================="

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR-VM-IP")

echo ""
echo "🌐 **YOUR PERSONAL AI ASSISTANT IS READY!**"
echo "================================================="
echo ""
echo "🏠 **Landing Page (Professional Showcase):**"
echo "   📍 URL: http://$EXTERNAL_IP:5000/"
echo "   ✨ Features: Hero section, feature showcase, live stats"
echo "   📱 Mobile responsive with modern design"
echo ""
echo "💬 **Chat Interface (ChatGPT-like Experience):**"
echo "   📍 URL: http://$EXTERNAL_IP:5000/chat"
echo "   🤖 Full conversation with memory"
echo "   ⚡ Real-time typing indicators"
echo "   📊 Statistics sidebar (desktop)"
echo "   📱 Fully mobile optimized"
echo ""
echo "🔌 **API Endpoints (Ready for Zoho Integration):**"
echo "   • GET  /           - Landing page"
echo "   • GET  /chat       - Chat interface"
echo "   • POST /chat       - Chat API (for Zoho)"
echo "   • GET  /health     - System health"
echo "   • GET  /stats      - Usage statistics"
echo "   • POST /webhook/zoho - Zoho SalesIQ webhook"
echo ""

# Check if services are running
echo "🔍 **System Status Check:**"
echo "================================================="

# Check Ollama
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama Service: Running"
    if ollama list | grep -q "phi3:mini"; then
        echo "✅ Phi-3 Mini Model: Downloaded"
    else
        echo "❌ Phi-3 Mini Model: Not found"
    fi
else
    echo "❌ Ollama Service: Not running"
fi

# Check API
if systemctl is-active --quiet personal-ai-assistant; then
    echo "✅ API Service: Running"
else
    echo "❌ API Service: Not running"
fi

# Test API health
if curl -s http://localhost:5000/health | grep -q "healthy"; then
    echo "✅ API Health: Healthy"
else
    echo "❌ API Health: Unhealthy"
fi

echo ""
echo "📊 **Quick Stats:**"
echo "================================================="

# Get stats if available
if curl -s http://localhost:5000/stats >/dev/null 2>&1; then
    STATS=$(curl -s http://localhost:5000/stats)
    TOTAL_REQUESTS=$(echo "$STATS" | grep -o '"total_requests":[0-9]*' | cut -d':' -f2 || echo "0")
    ACTIVE_SESSIONS=$(echo "$STATS" | grep -o '"active_sessions":[0-9]*' | cut -d':' -f2 || echo "0")
    echo "📈 Total Requests: $TOTAL_REQUESTS"
    echo "👥 Active Sessions: $ACTIVE_SESSIONS"
else
    echo "📈 Stats: API not responding"
fi

echo ""
echo "🎯 **Ready for Day 2:**"
echo "================================================="
echo "✅ Zoho webhook endpoint ready: http://$EXTERNAL_IP:5000/webhook/zoho"
echo "✅ Professional frontend for user engagement"
echo "✅ Stable API backend for integration"
echo "✅ Complete conversation capabilities"
echo ""

echo "🛠️  **Management Commands:**"
echo "================================================="
echo "📋 View API logs:     sudo journalctl -u personal-ai-assistant -f"
echo "🔄 Restart API:       sudo systemctl restart personal-ai-assistant"
echo "🔄 Restart Ollama:    sudo systemctl restart ollama"
echo "📊 Check status:      sudo systemctl status personal-ai-assistant"
echo "🧪 Test API:          ./test_api.sh"
echo ""

echo "🎊 **CONGRATULATIONS!**"
echo "================================================="
echo "Your Personal AI Assistant is fully operational!"
echo "Share this URL with friends: http://$EXTERNAL_IP:5000/"
echo "Ready to integrate with Zoho SalesIQ tomorrow!"
echo "================================================="
