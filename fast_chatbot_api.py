from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import requests
import json
import time
import logging
from datetime import datetime
import os
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
OLLAMA_BASE_URL = "http://localhost:11434"
MODEL_NAME = "phi3:mini"  # Change to "mistral:7b" if you prefer
MAX_CONVERSATION_LENGTH = 10  # Maximum number of exchanges to keep in memory

# In-memory conversation storage (replace with Redis/DB for production)
conversations: Dict[str, List[Dict]] = {}

# Statistics tracking
stats = {
    "total_requests": 0,
    "successful_requests": 0,
    "failed_requests": 0,
    "start_time": datetime.now().isoformat()
}

def get_session_id(request) -> str:
    """Generate or retrieve session ID"""
    return request.headers.get('X-Session-ID', 
           request.remote_addr + "_" + str(int(time.time())))

def get_conversation_history(session_id: str) -> List[Dict]:
    """Get conversation history for a session"""
    if session_id not in conversations:
        conversations[session_id] = []
    return conversations[session_id]

def add_to_conversation(session_id: str, user_message: str, ai_response: str):
    """Add exchange to conversation history"""
    if session_id not in conversations:
        conversations[session_id] = []
    
    conversations[session_id].append({
        "user": user_message,
        "assistant": ai_response,
        "timestamp": datetime.now().isoformat()
    })
    
    # Keep only recent exchanges
    if len(conversations[session_id]) > MAX_CONVERSATION_LENGTH:
        conversations[session_id] = conversations[session_id][-MAX_CONVERSATION_LENGTH:]

def build_context_prompt(session_id: str, current_message: str) -> str:
    """Build prompt with conversation context"""
    history = get_conversation_history(session_id)
    
    if not history:
        return f"User: {current_message}\nAssistant:"
    
    # Build context from recent conversation
    context_parts = []
    for exchange in history[-3:]:  # Last 3 exchanges for context
        context_parts.append(f"User: {exchange['user']}")
        context_parts.append(f"Assistant: {exchange['assistant']}")
    
    context_parts.append(f"User: {current_message}")
    context_parts.append("Assistant:")
    
    return "\n".join(context_parts)

def query_ollama(prompt: str) -> tuple[str, bool]:
    """Query Ollama API with error handling"""
    try:
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": MODEL_NAME,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "max_tokens": 500
                }
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            return result.get("response", "Sorry, I couldn't generate a response."), True
        else:
            logger.error(f"Ollama API error: {response.status_code}")
            return "Sorry, I'm experiencing technical difficulties.", False
            
    except requests.RequestException as e:
        logger.error(f"Request to Ollama failed: {e}")
        return "Sorry, I'm currently unavailable. Please try again later.", False

@app.route('/')
def landing():
    """Serve the landing page"""
    try:
        # Try to serve the professional landing page
        with open('landing.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        # Fallback to chat interface
        return chat_interface()

@app.route('/chat')
def chat_interface():
    """Serve the chat interface"""
    try:
        # Try to serve the professional chat interface
        with open('index.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        # Fallback to embedded test interface
        return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Personal AI Assistant - Test Interface</title>
        <style>
            body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
            .chat-container { border: 1px solid #ddd; height: 400px; overflow-y: auto; padding: 10px; margin: 10px 0; }
            .message { margin: 10px 0; padding: 10px; border-radius: 5px; }
            .user { background-color: #e3f2fd; text-align: right; }
            .assistant { background-color: #f5f5f5; }
            input[type="text"] { width: 70%; padding: 10px; }
            button { padding: 10px 20px; background-color: #2196F3; color: white; border: none; cursor: pointer; }
            button:hover { background-color: #1976D2; }
            .stats { background-color: #f9f9f9; padding: 10px; margin: 10px 0; border-radius: 5px; }
        </style>
    </head>
    <body>
        <h1>🤖 Personal AI Assistant - Test Interface</h1>
        <div class="stats">
            <strong>Status:</strong> <span id="status">Checking...</span> | 
            <strong>Model:</strong> {{ model_name }} | 
            <strong>API:</strong> /chat
        </div>
        
        <div class="chat-container" id="chatContainer"></div>
        
        <div>
            <input type="text" id="messageInput" placeholder="Type your message here..." onkeypress="handleKeyPress(event)">
            <button onclick="sendMessage()">Send</button>
            <button onclick="clearChat()">Clear</button>
        </div>
        
        <div class="stats">
            <h3>API Endpoints:</h3>
            <ul>
                <li><strong>POST /chat</strong> - Send message to AI</li>
                <li><strong>GET /health</strong> - Check system health</li>
                <li><strong>GET /stats</strong> - View usage statistics</li>
            </ul>
        </div>

        <script>
            let sessionId = 'test_' + Date.now();
            
            async function checkStatus() {
                try {
                    const response = await fetch('/health');
                    const data = await response.json();
                    document.getElementById('status').textContent = data.status === 'healthy' ? '✅ Online' : '❌ Offline';
                } catch (error) {
                    document.getElementById('status').textContent = '❌ Offline';
                }
            }
            
            async function sendMessage() {
                const input = document.getElementById('messageInput');
                const message = input.value.trim();
                if (!message) return;
                
                addMessage('user', message);
                input.value = '';
                
                try {
                    const response = await fetch('/chat', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-Session-ID': sessionId
                        },
                        body: JSON.stringify({ message: message })
                    });
                    
                    const data = await response.json();
                    if (data.success) {
                        addMessage('assistant', data.response);
                    } else {
                        addMessage('assistant', 'Error: ' + data.error);
                    }
                } catch (error) {
                    addMessage('assistant', 'Connection error: ' + error.message);
                }
            }
            
            function addMessage(sender, text) {
                const container = document.getElementById('chatContainer');
                const messageDiv = document.createElement('div');
                messageDiv.className = 'message ' + sender;
                messageDiv.innerHTML = '<strong>' + (sender === 'user' ? 'You' : 'AI') + ':</strong><br>' + text;
                container.appendChild(messageDiv);
                container.scrollTop = container.scrollHeight;
            }
            
            function clearChat() {
                document.getElementById('chatContainer').innerHTML = '';
                sessionId = 'test_' + Date.now();
            }
            
            function handleKeyPress(event) {
                if (event.key === 'Enter') {
                    sendMessage();
                }
            }
            
            // Check status on load
            checkStatus();
            setInterval(checkStatus, 30000); // Check every 30 seconds
        </script>
    </body>
    </html>
    ''', model_name=MODEL_NAME)

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint"""
    stats["total_requests"] += 1
    
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            stats["failed_requests"] += 1
            return jsonify({
                "success": False,
                "error": "Missing 'message' in request body"
            }), 400
        
        user_message = data['message'].strip()
        if not user_message:
            stats["failed_requests"] += 1
            return jsonify({
                "success": False,
                "error": "Empty message"
            }), 400
        
        session_id = get_session_id(request)
        
        # Build context-aware prompt
        prompt = build_context_prompt(session_id, user_message)
        
        # Query Ollama
        ai_response, success = query_ollama(prompt)
        
        if success:
            # Add to conversation history
            add_to_conversation(session_id, user_message, ai_response)
            stats["successful_requests"] += 1
            
            return jsonify({
                "success": True,
                "response": ai_response,
                "session_id": session_id,
                "timestamp": datetime.now().isoformat()
            })
        else:
            stats["failed_requests"] += 1
            return jsonify({
                "success": False,
                "error": "Failed to get response from AI model",
                "response": ai_response  # Fallback message
            }), 500
            
    except Exception as e:
        stats["failed_requests"] += 1
        logger.error(f"Chat endpoint error: {e}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        # Test Ollama connection
        response = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
        ollama_healthy = response.status_code == 200
        
        return jsonify({
            "status": "healthy" if ollama_healthy else "unhealthy",
            "ollama_status": "connected" if ollama_healthy else "disconnected",
            "model": MODEL_NAME,
            "timestamp": datetime.now().isoformat(),
            "uptime_seconds": (datetime.now() - datetime.fromisoformat(stats["start_time"])).total_seconds()
        })
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get usage statistics"""
    return jsonify({
        **stats,
        "active_sessions": len(conversations),
        "model": MODEL_NAME,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/webhook/zoho', methods=['POST'])
def zoho_webhook():
    """Webhook endpoint for Zoho SalesIQ (Day 2)"""
    try:
        data = request.get_json()
        
        # Extract message from Zoho webhook
        user_message = data.get('message', {}).get('text', '')
        visitor_id = data.get('visitor', {}).get('id', 'unknown')
        
        if not user_message:
            return jsonify({"error": "No message found"}), 400
        
        # Use visitor ID as session ID
        session_id = f"zoho_{visitor_id}"
        
        # Build context-aware prompt
        prompt = build_context_prompt(session_id, user_message)
        
        # Query Ollama
        ai_response, success = query_ollama(prompt)
        
        if success:
            add_to_conversation(session_id, user_message, ai_response)
            
            # Return response in Zoho format
            return jsonify({
                "response": ai_response,
                "success": True
            })
        else:
            return jsonify({
                "response": "I'm sorry, I'm experiencing technical difficulties right now.",
                "success": False
            }), 500
            
    except Exception as e:
        logger.error(f"Zoho webhook error: {e}")
        return jsonify({
            "response": "Sorry, something went wrong.",
            "success": False
        }), 500

if __name__ == '__main__':
    print("🚀 Starting Personal AI Assistant API...")
    print(f"📊 Model: {MODEL_NAME}")
    print(f"🔗 Ollama URL: {OLLAMA_BASE_URL}")
    print("🌐 Access the test interface at: http://localhost:5000/")
    print("📡 API endpoints available at: /chat, /health, /stats")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
