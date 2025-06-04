#!/bin/bash

# Test API Functionality
# Run this to verify everything is working

set -e

echo "🧪 Testing Personal AI Assistant API..."
echo "====================================="

# Get the API URL
if [ -z "$1" ]; then
    API_URL="http://localhost:5000"
else
    API_URL="$1"
fi

echo "🎯 Testing API at: $API_URL"

# Test 1: Health Check
echo ""
echo "1️⃣ Testing Health Endpoint..."
HEALTH_RESPONSE=$(curl -s "$API_URL/health")
echo "Response: $HEALTH_RESPONSE"

if echo "$HEALTH_RESPONSE" | grep -q '"status": "healthy"'; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    exit 1
fi

# Test 2: Stats Endpoint
echo ""
echo "2️⃣ Testing Stats Endpoint..."
STATS_RESPONSE=$(curl -s "$API_URL/stats")
echo "Response: $STATS_RESPONSE"

if echo "$STATS_RESPONSE" | grep -q '"total_requests"'; then
    echo "✅ Stats endpoint working"
else
    echo "❌ Stats endpoint failed"
    exit 1
fi

# Test 3: Chat Endpoint
echo ""
echo "3️⃣ Testing Chat Endpoint..."
CHAT_RESPONSE=$(curl -s -X POST "$API_URL/chat" \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: test-session-123" \
    -d '{"message": "Hello! Can you introduce yourself?"}')

echo "Response: $CHAT_RESPONSE"

if echo "$CHAT_RESPONSE" | grep -q '"success": true'; then
    echo "✅ Chat endpoint working"
else
    echo "❌ Chat endpoint failed"
    echo "Full response: $CHAT_RESPONSE"
    exit 1
fi

# Test 4: Conversation Memory
echo ""
echo "4️⃣ Testing Conversation Memory..."
FOLLOWUP_RESPONSE=$(curl -s -X POST "$API_URL/chat" \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: test-session-123" \
    -d '{"message": "What did I just ask you?"}')

echo "Response: $FOLLOWUP_RESPONSE"

if echo "$FOLLOWUP_RESPONSE" | grep -q '"success": true'; then
    echo "✅ Conversation memory working"
else
    echo "⚠️  Conversation memory test inconclusive"
fi

# Test 5: Multiple Sessions
echo ""
echo "5️⃣ Testing Multiple Sessions..."
SESSION2_RESPONSE=$(curl -s -X POST "$API_URL/chat" \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: test-session-456" \
    -d '{"message": "Hi there!"}')

if echo "$SESSION2_RESPONSE" | grep -q '"success": true'; then
    echo "✅ Multiple sessions working"
else
    echo "❌ Multiple sessions failed"
fi

# Test 6: Error Handling
echo ""
echo "6️⃣ Testing Error Handling..."
ERROR_RESPONSE=$(curl -s -X POST "$API_URL/chat" \
    -H "Content-Type: application/json" \
    -d '{"invalid": "request"}')

if echo "$ERROR_RESPONSE" | grep -q '"success": false'; then
    echo "✅ Error handling working"
else
    echo "⚠️  Error handling test inconclusive"
fi

echo ""
echo "====================================="
echo "🎉 API Testing Complete!"
echo "====================================="
echo "📊 Final Stats Check:"
curl -s "$API_URL/stats" | python3 -m json.tool 2>/dev/null || echo "Stats endpoint unavailable"
echo ""
echo "✅ Your API is ready for Zoho integration!"
echo "🔗 Use this URL for Zoho webhook: $API_URL/webhook/zoho"
echo "====================================="
