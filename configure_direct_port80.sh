#!/bin/bash
# Alternative: Update existing API to run on port 80 directly
# This modifies the Flask app to run on port 80 (requires sudo)

set -e

echo "⚙️ Configuring API for Direct Port 80 Access..."
echo "=============================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run with sudo for port 80 access:"
    echo "   sudo ./configure_direct_port80.sh"
    exit 1
fi

# Get the actual user
ACTUAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
PROJECT_DIR="/home/$ACTUAL_USER/personal-ai-assistant"

cd $PROJECT_DIR

# Create a production version that runs on port 80
cat > fast_chatbot_api_port80.py << 'EOF'
#!/usr/bin/env python3
"""
Personal AI Assistant API - Port 80 Production Version
Direct port 80 binding (requires root privileges)
"""

import os
import sys
import logging
import requests
import json
from datetime import datetime
from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
OLLAMA_BASE_URL = os.getenv('OLLAMA_BASE_URL', 'http://localhost:11434')
MAX_CONTEXT_LENGTH = int(os.getenv('MAX_CONTEXT_LENGTH', '2000'))

# Global storage for conversation history
conversations = {}
stats = {
    'total_requests': 0,
    'start_time': datetime.now()
}

def get_conversation_history(session_id):
    """Get conversation history for a session"""
    if session_id not in conversations:
        conversations[session_id] = []
    return conversations[session_id]

def add_to_conversation(session_id, user_message, assistant_response):
    """Add exchange to conversation history"""
    history = get_conversation_history(session_id)
    history.append({
        'user': user_message,
        'assistant': assistant_response,
        'timestamp': datetime.now().isoformat()
    })
    
    # Keep only recent conversations to manage memory
    if len(history) > 20:
        history.pop(0)

def build_context(session_id, current_message):
    """Build context string from conversation history"""
    history = get_conversation_history(session_id)
    
    context_parts = []
    total_length = 0
    
    # Add current message
    current_length = len(current_message)
    if current_length > MAX_CONTEXT_LENGTH:
        return current_message[:MAX_CONTEXT_LENGTH]
    
    context_parts.append(f"Human: {current_message}")
    total_length += current_length
    
    # Add recent history (most recent first)
    for entry in reversed(history):
        user_msg = f"Human: {entry['user']}"
        assistant_msg = f"Assistant: {entry['assistant']}"
        
        entry_length = len(user_msg) + len(assistant_msg) + 2
        
        if total_length + entry_length > MAX_CONTEXT_LENGTH:
            break
            
        context_parts.insert(0, assistant_msg)
        context_parts.insert(0, user_msg)
        total_length += entry_length
    
    return "\n".join(context_parts)

def chat_with_ollama(message, session_id="default"):
    """Send message to Ollama and get response"""
    try:
        # Build context with conversation history
        context = build_context(session_id, message)
        
        # Prepare the prompt
        system_prompt = """You are a helpful, friendly, and knowledgeable AI assistant. You provide accurate, helpful responses while maintaining a conversational and approachable tone. If you don't know something, you admit it honestly. Keep your responses concise but comprehensive."""
        
        full_prompt = f"{system_prompt}\n\nConversation:\n{context}\n\nAssistant:"
        
        # Make request to Ollama
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": "phi3:mini",
                "prompt": full_prompt,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "top_k": 40,
                    "num_predict": 500
                }
            },
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            assistant_response = result.get('response', '').strip()
            
            if assistant_response:
                # Add to conversation history
                add_to_conversation(session_id, message, assistant_response)
                return assistant_response, True
            else:
                return "I apologize, but I couldn't generate a proper response. Please try again.", False
        else:
            logger.error(f"Ollama request failed with status {response.status_code}")
            return "Sorry, I'm experiencing technical difficulties.", False
            
    except requests.RequestException as e:
        logger.error(f"Request to Ollama failed: {e}")
        return "Sorry, I'm currently unavailable. Please try again later.", False

@app.route('/')
def landing():
    """Serve the landing page"""
    try:
        with open('landing.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return chat_interface()

@app.route('/chat')
def chat_interface():
    """Serve the chat interface"""
    try:
        with open('index.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return "<h1>Chat interface not found. Please upload index.html</h1>"

@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint"""
    try:
        # Get request data
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({
                'success': False,
                'error': 'No message provided'
            }), 400
        
        user_message = data['message'].strip()
        if not user_message:
            return jsonify({
                'success': False,
                'error': 'Empty message'
            }), 400
        
        # Get session ID
        session_id = request.headers.get('X-Session-ID', 'default')
        
        # Update stats
        stats['total_requests'] += 1
        
        # Get AI response
        response_text, success = chat_with_ollama(user_message, session_id)
        
        if success:
            return jsonify({
                'success': True,
                'response': response_text,
                'session_id': session_id,
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'success': False,
                'error': response_text
            }), 500
            
    except Exception as e:
        logger.error(f"Chat endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        # Test Ollama connection
        response = requests.get(f"{OLLAMA_BASE_URL}/api/version", timeout=5)
        ollama_status = "healthy" if response.status_code == 200 else "unhealthy"
    except:
        ollama_status = "unhealthy"
    
    return jsonify({
        'status': 'healthy' if ollama_status == 'healthy' else 'degraded',
        'timestamp': datetime.now().isoformat(),
        'ollama': ollama_status,
        'model': 'phi3:mini',
        'uptime_seconds': (datetime.now() - stats['start_time']).total_seconds()
    })

@app.route('/stats')
def get_stats():
    """Get usage statistics"""
    uptime = datetime.now() - stats['start_time']
    return jsonify({
        'total_requests': stats['total_requests'],
        'active_sessions': len(conversations),
        'uptime_seconds': uptime.total_seconds(),
        'uptime_human': str(uptime).split('.')[0],
        'start_time': stats['start_time'].isoformat()
    })

@app.route('/webhook/zoho', methods=['POST'])
def zoho_webhook():
    """Webhook endpoint for Zoho SalesIQ integration"""
    try:
        data = request.get_json()
        logger.info(f"Zoho webhook received: {data}")
        
        # Extract message from Zoho payload
        message = data.get('message', {}).get('text', '')
        session_id = data.get('visitor', {}).get('id', 'zoho_default')
        
        if not message:
            return jsonify({'error': 'No message found'}), 400
        
        # Get AI response
        response_text, success = chat_with_ollama(message, f"zoho_{session_id}")
        
        if success:
            return jsonify({
                'success': True,
                'response': response_text
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to generate response'
            }), 500
            
    except Exception as e:
        logger.error(f"Zoho webhook error: {e}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    print("🤖 Personal AI Assistant API Starting...")
    print(f"🔗 Ollama URL: {OLLAMA_BASE_URL}")
    print("🌐 Access the interface at: http://your-ip/")
    print("📡 API endpoints available at: /chat, /health, /stats")
    
    # Run on port 80 (requires root)
    app.run(host='0.0.0.0', port=80, debug=False)
EOF

# Update systemd service for direct port 80
tee /etc/systemd/system/personal-ai-assistant-port80.service > /dev/null << EOF
[Unit]
Description=Personal AI Assistant API (Port 80)
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$PROJECT_DIR/venv/bin
ExecStart=$PROJECT_DIR/venv/bin/python fast_chatbot_api_port80.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Update firewall
ufw allow 80/tcp
ufw --force enable

echo "✅ Direct Port 80 configuration complete!"
echo ""
echo "⚠️  CHOOSE ONE OPTION:"
echo "1️⃣  Use nginx reverse proxy (recommended): sudo systemctl start nginx && sudo systemctl start personal-ai-assistant"
echo "2️⃣  Use direct port 80: sudo systemctl start personal-ai-assistant-port80"
echo ""
echo "🔗 Your API will be available at: http://$(curl -s ifconfig.me)/"
