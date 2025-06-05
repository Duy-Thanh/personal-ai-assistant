#!/bin/bash

# Day 2: Zoho Webhook Testing Script
# This script helps test your Zoho SalesIQ webhook integration

echo "🧪 Testing Zoho SalesIQ Webhook Integration"
echo "========================================"

# Configuration
VM_IP=${1:-"YOUR_VM_IP_HERE"}
API_PORT="5000"
WEBHOOK_ENDPOINT="/webhook/zoho"

if [ "$VM_IP" = "YOUR_VM_IP_HERE" ]; then
    echo "❌ Please provide your VM IP address as first argument"
    echo "Usage: ./test_zoho_webhook.sh YOUR_VM_IP"
    exit 1
fi

API_URL="http://${VM_IP}:${API_PORT}"
WEBHOOK_URL="${API_URL}${WEBHOOK_ENDPOINT}"

echo "📍 Testing API at: $API_URL"
echo "🔗 Webhook URL: $WEBHOOK_URL"
echo ""

# Test 1: Health Check
echo "Test 1: Health Check"
echo "-------------------"
echo "🔍 Checking if API is running..."
health_response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "${API_URL}/health" 2>/dev/null)
health_code=${health_response: -3}

if [ "$health_code" = "200" ]; then
    echo "✅ API is healthy"
    cat /tmp/health_response.json | jq '.' 2>/dev/null || cat /tmp/health_response.json
else
    echo "❌ API health check failed (HTTP $health_code)"
    echo "Please ensure your API is running on port $API_PORT"
    exit 1
fi

echo -e "\n"

# Test 2: Direct Chat Test
echo "Test 2: Direct Chat Test"
echo "------------------------"
echo "🤖 Testing direct chat endpoint..."
chat_response=$(curl -s -w "%{http_code}" -o /tmp/chat_response.json \
    -X POST "${API_URL}/chat" \
    -H "Content-Type: application/json" \
    -d '{"message": "Hello! This is a test message."}' 2>/dev/null)
chat_code=${chat_response: -3}

if [ "$chat_code" = "200" ]; then
    echo "✅ Direct chat working"
    cat /tmp/chat_response.json | jq '.response' 2>/dev/null || cat /tmp/chat_response.json
else
    echo "❌ Direct chat failed (HTTP $chat_code)"
    cat /tmp/chat_response.json 2>/dev/null
fi

echo -e "\n"

# Test 3: Zoho Webhook Test
echo "Test 3: Zoho Webhook Test"
echo "-------------------------"
echo "🔗 Testing Zoho webhook endpoint..."

# Simulate Zoho webhook payload
webhook_payload='{
  "message": {
    "text": "Hello AI! This is a test from Zoho webhook.",
    "time": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"
  },
  "visitor": {
    "id": "test_visitor_123",
    "name": "Test User",
    "email": "test@example.com"
  },
  "department": {
    "id": "test_dept",
    "name": "Support"
  },
  "chat": {
    "id": "test_chat_session"
  }
}'

webhook_response=$(curl -s -w "%{http_code}" -o /tmp/webhook_response.json \
    -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$webhook_payload" 2>/dev/null)
webhook_code=${webhook_response: -3}

if [ "$webhook_code" = "200" ]; then
    echo "✅ Zoho webhook working"
    echo "Response:"
    cat /tmp/webhook_response.json | jq '.' 2>/dev/null || cat /tmp/webhook_response.json
else
    echo "❌ Zoho webhook failed (HTTP $webhook_code)"
    echo "Error response:"
    cat /tmp/webhook_response.json 2>/dev/null
fi

echo -e "\n"

# Test 4: Check Stats
echo "Test 4: API Statistics"
echo "---------------------"
echo "📊 Checking API usage stats..."
stats_response=$(curl -s "${API_URL}/stats" 2>/dev/null)
echo "$stats_response" | jq '.' 2>/dev/null || echo "$stats_response"

echo -e "\n"

# Summary
echo "🎯 Test Summary"
echo "==============="
echo "Health Check: $([ "$health_code" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Direct Chat:  $([ "$chat_code" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "Zoho Webhook: $([ "$webhook_code" = "200" ] && echo "✅ PASS" || echo "❌ FAIL")"

echo -e "\n"

if [ "$health_code" = "200" ] && [ "$chat_code" = "200" ] && [ "$webhook_code" = "200" ]; then
    echo "🎉 All tests passed! Your API is ready for Zoho integration."
    echo ""
    echo "Next steps:"
    echo "1. Set up your Zoho SalesIQ account"
    echo "2. Configure webhook URL: $WEBHOOK_URL"
    echo "3. Test with the chat widget"
else
    echo "⚠️  Some tests failed. Please check your API configuration."
fi

# Cleanup
rm -f /tmp/health_response.json /tmp/chat_response.json /tmp/webhook_response.json 2>/dev/null

echo ""
echo "🔍 For detailed logs, check your API server output"
echo "📝 Webhook URL to configure in Zoho: $WEBHOOK_URL"
