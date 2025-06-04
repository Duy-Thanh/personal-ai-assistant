#!/bin/bash

# Test Timeout Fix for Personal AI Assistant
# Sends a complex query that should take longer to process

set -e

VM_IP="34.66.156.47"
API_URL="http://$VM_IP"

echo "🧪 Testing Timeout Fix for Personal AI Assistant..."
echo "=================================================="

echo ""
echo "1️⃣ Testing API Health..."
curl -s "$API_URL/health" | python3 -m json.tool

echo ""
echo "2️⃣ Testing Configuration..."
echo "Current timeout setting:"
curl -s "$API_URL/stats" | python3 -c "
import sys, json
data = json.load(sys.stdin)
config = data.get('api_configuration', {})
print(f'  Timeout: {config.get(\"timeout_seconds\", \"N/A\")} seconds')
print(f'  Model: {config.get(\"model_name\", \"N/A\")}')
print(f'  Ollama URL: {config.get(\"ollama_url\", \"N/A\")}')
"

echo ""
echo "3️⃣ Testing Complex Query (this should take longer)..."
echo "Sending a request that requires deeper thinking..."

COMPLEX_QUERY="Please write a detailed analysis of the advantages and disadvantages of quantum computing, including its potential applications in cryptography, drug discovery, and financial modeling. Explain the technical challenges that need to be overcome and provide a timeline for when these technologies might become commercially viable."

START_TIME=$(date +%s)

echo "📤 Sending complex query..."
echo "Query: ${COMPLEX_QUERY:0:100}..."

RESPONSE=$(curl -s -X POST "$API_URL/chat" \
    -H "Content-Type: application/json" \
    -H "X-Session-ID: timeout-test-$(date +%s)" \
    -d "{\"message\": \"$COMPLEX_QUERY\"}")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "📊 Test Results:"
echo "=================="
echo "⏱️  Duration: ${DURATION} seconds"

if echo "$RESPONSE" | grep -q '"success": true'; then
    echo "✅ SUCCESS: Complex query handled successfully!"
    echo ""
    echo "📝 Response excerpt:"
    echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    response = data.get('response', 'No response')
    print(response[:200] + '...' if len(response) > 200 else response)
except:
    print('Could not parse response')
"
else
    echo "❌ FAILED: Query was not handled successfully"
    echo ""
    echo "🔍 Error details:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
fi

echo ""
echo "4️⃣ Testing Memory Management..."
MEMORY_INFO=$(curl -s "$API_URL/stats" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Active Sessions: {data.get(\"active_sessions\", 0)}')
print(f'Total Messages in Memory: {data.get(\"total_messages_in_memory\", 0)}')
print(f'Memory Conservation: {data.get(\"memory_conservation\", {})}')
")

echo "$MEMORY_INFO"

echo ""
echo "🎉 Timeout Fix Test Complete!"
echo "============================="

if [ $DURATION -gt 30 ]; then
    echo "✅ SUCCESS: Query processed beyond 30-second limit!"
    echo "   The timeout fix is working correctly."
else
    echo "ℹ️  INFO: Query completed in under 30 seconds."
    echo "   This doesn't test the timeout fix, but the API is working."
fi

echo ""
echo "💡 Next Steps:"
echo "   • Try more complex queries to test longer processing times"
echo "   • Monitor the logs: sudo journalctl -u personal-ai-assistant -f"
echo "   • Users will now see helpful progress messages during long waits"
