#!/bin/bash

# Zoho SalesIQ Webhook Test Script
# This script tests your AI assistant webhook integration

echo "🧪 Testing Zoho SalesIQ Webhook Integration..."
echo "================================================"

# Configuration - UPDATE THESE VALUES
VM_IP="localhost"  # Replace with your actual VM IP (e.g., "34.123.45.67")
PORT="5000"
WEBHOOK_URL="http://$VM_IP:$PORT/webhook/zoho"

echo "📡 Testing webhook endpoint: $WEBHOOK_URL"
echo ""

# Test 1: Basic webhook connectivity
echo "🔍 Test 1: Basic webhook connectivity..."
response1=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"test": true}')

if [ "$response1" = "200" ]; then
    echo "✅ Webhook endpoint is accessible (HTTP $response1)"
else
    echo "❌ Webhook endpoint failed (HTTP $response1)"
    echo "   Check if your API server is running on port $PORT"
    exit 1
fi

echo ""

# Test 2: Zoho SalesIQ message format test
echo "🔍 Test 2: Zoho SalesIQ message format..."
echo "Sending test message: 'Hello AI!'"

response2=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "conversation.visitors.replied",
    "conversation": {
      "id": "test_conv_12345",
      "visitor_id": "test_visitor_789"
    },
    "message": {
      "text": "Hello AI!",
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    },
    "visitor": {
      "id": "test_visitor_789",
      "name": "Test User"
    }
  }')

if echo "$response2" | grep -q "response"; then
    echo "✅ AI responded successfully!"
    echo "🤖 AI Response: $(echo "$response2" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ AI did not respond properly"
    echo "   Response: $response2"
fi

echo ""

# Test 3: API health check
echo "🔍 Test 3: API health check..."
health_response=$(curl -s "$VM_IP:$PORT/health")

if echo "$health_response" | grep -q "healthy"; then
    echo "✅ API is healthy"
    echo "📊 API Status: $(echo "$health_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ API health check failed"
    echo "   Response: $health_response"
fi

echo ""

# Test 4: Chat interface test
echo "🔍 Test 4: Chat interface accessibility..."
interface_response=$(curl -s -o /dev/null -w "%{http_code}" "$VM_IP:$PORT/")

if [ "$interface_response" = "200" ]; then
    echo "✅ Chat interface is accessible"
    echo "🌐 Open in browser: http://$VM_IP:$PORT/"
else
    echo "❌ Chat interface not accessible (HTTP $interface_response)"
fi

echo ""
echo "================================================"
echo "🎯 Integration Test Summary:"
echo "================================================"

# Test Zoho widget presence
echo "🔍 Test 5: Zoho widget integration..."
if curl -s "$VM_IP:$PORT/" | grep -q "salesiq.zohopublic.com"; then
    echo "✅ Zoho SalesIQ widget is integrated in landing page"
else
    echo "❌ Zoho SalesIQ widget not found in landing page"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Open your landing page: http://$VM_IP:$PORT/"
echo "2. Look for Zoho chat widget in bottom-right corner"
echo "3. Send a test message through the widget"
echo "4. Check if AI responds through Zoho chat"
echo ""
echo "🔧 Troubleshooting:"
echo "- If webhook fails: Check your VM firewall (port $PORT)"
echo "- If no AI response: Check your LLM model is running"
echo "- If widget missing: Verify Zoho script is correctly added"
echo ""
echo "✨ Test completed!"
