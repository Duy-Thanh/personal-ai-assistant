from flask import Flask, request, jsonify, render_template_string, Response
from flask_cors import CORS
import requests
import json
import time
import logging
from datetime import datetime
import os
from typing import Dict, List, Optional
import threading
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
OLLAMA_BASE_URL = "http://localhost:11434"
MODEL_NAME = "phi3:mini"  # Change to "mistral:7b" if you prefer
MAX_CONVERSATION_LENGTH = 25  # Maximum number of exchanges to keep in memory
MAX_CONTEXT_MESSAGES = 50  # Maximum messages to include in context
OLLAMA_TIMEOUT = int(os.getenv('OLLAMA_TIMEOUT', '600'))  # Default 10 minutes for complex queries

# In-memory conversation storage (replace with Redis/DB for production)
conversations: Dict[str, List[Dict]] = {}
session_metadata: Dict[str, Dict] = {}  # Track session info

# Statistics tracking
stats = {
    "total_requests": 0,
    "successful_requests": 0,
    "failed_requests": 0,
    "active_sessions": 0,
    "start_time": datetime.now().isoformat(),
    "last_cleanup": datetime.now().isoformat()
}

def get_session_id(request) -> str:
    """Generate or retrieve session ID"""
    session_id = request.headers.get('X-Session-ID',
                 request.remote_addr + "_" + str(int(time.time())))

    # Track session metadata
    if session_id not in session_metadata:
        session_metadata[session_id] = {
            "created_at": datetime.now().isoformat(),
            "last_activity": datetime.now().isoformat(),
            "message_count": 0,
            "ip_address": request.remote_addr
        }
    else:
        session_metadata[session_id]["last_activity"] = datetime.now().isoformat()

    return session_id

def get_conversation_history(session_id: str) -> List[Dict]:
    """Get conversation history for a session with memory conservation"""
    if session_id not in conversations:
        conversations[session_id] = []

    # Keep only last MAX_CONTEXT_MESSAGES for memory efficiency
    if len(conversations[session_id]) > MAX_CONTEXT_MESSAGES:
        conversations[session_id] = conversations[session_id][-MAX_CONTEXT_MESSAGES:]

    return conversations[session_id]

def add_to_conversation(session_id: str, user_message: str, ai_response: str):
    """Add exchange to conversation history with automatic cleanup"""
    if session_id not in conversations:
        conversations[session_id] = []

    conversations[session_id].append({
        "user": user_message,
        "assistant": ai_response,
        "timestamp": datetime.now().isoformat()
    })

    # Update session metadata
    if session_id in session_metadata:
        session_metadata[session_id]["message_count"] += 1
        session_metadata[session_id]["last_activity"] = datetime.now().isoformat()

    # Keep only recent exchanges to prevent memory bloat
    if len(conversations[session_id]) > MAX_CONVERSATION_LENGTH:
        conversations[session_id] = conversations[session_id][-MAX_CONVERSATION_LENGTH:]

    logger.info(f"Session {session_id[:8]}... now has {len(conversations[session_id])} exchanges")

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
    """Query Ollama API with enhanced timeout handling and error recovery"""
    try:
        # Use configurable timeout for AI responses
        # AI models can take time to think, especially for complex queries
        timeout_duration = OLLAMA_TIMEOUT

        logger.info(f"Sending request to Ollama (timeout: {timeout_duration}s)")

        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                "model": MODEL_NAME,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "max_tokens": 500,
                    "num_predict": 500,  # Limit response length for faster processing
                    "stop": ["\n\nUser:", "\n\nHuman:"]  # Stop tokens to prevent runaway generation
                }
            },
            timeout=timeout_duration
        )

        if response.status_code == 200:
            result = response.json()
            ai_response = result.get("response", "").strip()

            if ai_response:
                logger.info(f"Ollama response received successfully ({len(ai_response)} chars)")
                return ai_response, True
            else:
                logger.warning("Ollama returned empty response")
                return "I apologize, but I couldn't generate a proper response. Please try rephrasing your question.", False
        else:
            logger.error(f"Ollama API error: {response.status_code} - {response.text}")
            return "Sorry, I'm experiencing technical difficulties. Please try again in a moment.", False

    except requests.exceptions.Timeout as e:
        logger.error(f"Ollama request timed out after {timeout_duration}s: {e}")
        return "I'm taking longer than usual to process your request. The AI model is working hard on your question - please try again or simplify your request.", False
    except requests.exceptions.ConnectionError as e:
        logger.error(f"Connection error to Ollama: {e}")
        return "I'm having trouble connecting to the AI service. Please check that the AI model is running and try again.", False
    except requests.RequestException as e:
        logger.error(f"Request to Ollama failed: {e}")
        return "Sorry, I'm currently unavailable. Please try again later.", False
    except Exception as e:
        logger.error(f"Unexpected error in query_ollama: {e}")
        return "An unexpected error occurred. Please try again.", False

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

        # Query Ollama with extended timeout
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

@app.route('/chat/stream', methods=['POST'])
def chat_stream():
    """Streaming chat endpoint for long responses"""
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

        def generate_stream():
            response = None
            client_disconnected = False
            try:
                # Build context-aware prompt
                prompt = build_context_prompt(session_id, user_message)

                # Send immediate acknowledgment with flush
                yield f"data: {json.dumps({'status': 'processing', 'message': 'AI is thinking...'})}\n\n"

                # Query Ollama with streaming
                response = requests.post(
                    f"{OLLAMA_BASE_URL}/api/generate",
                    json={
                        "model": MODEL_NAME,
                        "prompt": prompt,
                        "stream": True,  # Enable streaming
                        "options": {
                            "temperature": 0.7,
                            "top_p": 0.9,
                            "num_predict": 1000,  # Allow longer responses
                            "stop": ["\n\nUser:", "\n\nHuman:"]
                        }
                    },
                    stream=True,
                    timeout=OLLAMA_TIMEOUT
                )

                if response.status_code == 200:
                    full_response = ""
                    chunk_count = 0
                    try:
                        for line in response.iter_lines(decode_unicode=True):
                            # Check if client is still connected periodically
                            if chunk_count % 10 == 0:
                                try:
                                    # Test if we can still write to the client
                                    yield ""
                                except GeneratorExit:
                                    client_disconnected = True
                                    logger.info("Client disconnected during streaming")
                                    break

                            if line:
                                try:
                                    chunk_data = json.loads(line)
                                    if 'response' in chunk_data:
                                        chunk_text = chunk_data['response']
                                        full_response += chunk_text
                                        chunk_count += 1

                                        # Send chunk to client with explicit flush
                                        chunk_json = json.dumps({
                                            'status': 'streaming',
                                            'chunk': chunk_text,
                                            'full_response': full_response
                                        })
                                        yield f"data: {chunk_json}\n\n"

                                    if chunk_data.get('done', False):
                                        break
                                except json.JSONDecodeError as e:
                                    logger.warning(f"Failed to parse Ollama response: {e}")
                                    continue
                    except GeneratorExit:
                        client_disconnected = True
                        logger.info("Client disconnected during streaming")
                    finally:
                        # Ensure response is properly closed
                        if response:
                            try:
                                response.close()
                            except:
                                pass

                    # Only save and send completion if client is still connected
                    if not client_disconnected:
                        if full_response.strip():
                            add_to_conversation(session_id, user_message, full_response.strip())
                            stats["successful_requests"] += 1

                            # Send completion signal
                            completion_json = json.dumps({
                                'status': 'complete',
                                'full_response': full_response.strip(),
                                'session_id': session_id
                            })
                            yield f"data: {completion_json}\n\n"
                        else:
                            stats["failed_requests"] += 1
                            yield f"data: {json.dumps({'status': 'error', 'error': 'Empty response from AI'})}\n\n"
                    else:
                        # Client disconnected, but we might have partial response to save
                        if full_response.strip():
                            add_to_conversation(session_id, user_message, full_response.strip())
                            stats["successful_requests"] += 1
                        else:
                            stats["failed_requests"] += 1
                else:
                    stats["failed_requests"] += 1
                    error_msg = f'API error: {response.status_code}'
                    logger.error(f"Ollama API error: {error_msg}")
                    yield f"data: {json.dumps({'status': 'error', 'error': error_msg})}\n\n"

            except requests.exceptions.Timeout:
                stats["failed_requests"] += 1
                logger.error("Request timed out during streaming")
                yield f"data: {json.dumps({'status': 'error', 'error': 'Request timed out - AI model is taking too long'})}\n\n"
            except requests.exceptions.ConnectionError as e:
                stats["failed_requests"] += 1
                logger.error(f"Connection error during streaming: {e}")
                yield f"data: {json.dumps({'status': 'error', 'error': 'Connection lost during streaming'})}\n\n"
            except GeneratorExit:
                # Client disconnected - this is normal
                logger.info("Client disconnected from stream")
                client_disconnected = True
            except Exception as e:
                stats["failed_requests"] += 1
                logger.error(f"Streaming error: {e}")
                if not client_disconnected:
                    yield f"data: {json.dumps({'status': 'error', 'error': str(e)})}\n\n"
            finally:
                # Ensure proper cleanup
                if response:
                    try:
                        response.close()
                    except:
                        pass
                # Send final event to close the stream only if client is still connected
                if not client_disconnected:
                    try:
                        yield f"data: {json.dumps({'status': 'stream_end'})}\n\n"
                    except:
                        pass

        return Response(
            generate_stream(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'X-Accel-Buffering': 'no',  # Disable nginx buffering
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type, X-Session-ID'
            }
        )

    except Exception as e:
        stats["failed_requests"] += 1
        logger.error(f"Chat stream endpoint error: {e}")
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
    """Get usage statistics with enhanced memory info"""
    # Perform cleanup and update active sessions
    cleanup_old_sessions()

    total_messages = sum(len(conv) for conv in conversations.values())

    return jsonify({
        **stats,
        "active_sessions": len(session_metadata),
        "total_conversations": len(conversations),
        "total_messages_in_memory": total_messages,
        "model": MODEL_NAME,
        "ollama_timeout": OLLAMA_TIMEOUT,
        "memory_conservation": {
            "max_conversation_length": MAX_CONVERSATION_LENGTH,
            "max_context_messages": MAX_CONTEXT_MESSAGES,
            "cleanup_enabled": True
        },
        "api_configuration": {
            "timeout_seconds": OLLAMA_TIMEOUT,
            "max_response_tokens": 500,
            "model_name": MODEL_NAME,
            "ollama_url": OLLAMA_BASE_URL
        },
        "timestamp": datetime.now().isoformat()
    })

def cleanup_old_sessions():
    """Clean up sessions older than 24 hours"""
    cutoff_time = datetime.now().timestamp() - (24 * 60 * 60)  # 24 hours ago
    sessions_to_remove = []

    for session_id, metadata in session_metadata.items():
        last_activity = datetime.fromisoformat(metadata["last_activity"]).timestamp()
        if last_activity < cutoff_time:
            sessions_to_remove.append(session_id)

    for session_id in sessions_to_remove:
        conversations.pop(session_id, None)
        session_metadata.pop(session_id, None)
        logger.info(f"Cleaned up old session: {session_id[:8]}...")

    if sessions_to_remove:
        logger.info(f"Cleaned up {len(sessions_to_remove)} old sessions")

    stats["last_cleanup"] = datetime.now().isoformat()
    stats["active_sessions"] = len(session_metadata)

if __name__ == '__main__':
    print("🚀 Starting Personal AI Assistant API...")
    print(f"📊 Model: {MODEL_NAME}")
    print(f"🔗 Ollama URL: {OLLAMA_BASE_URL}")
    print(f"⏱️  Timeout: {OLLAMA_TIMEOUT} seconds")
    print(f"🧠 Memory: {MAX_CONVERSATION_LENGTH} conversations × {MAX_CONTEXT_MESSAGES} messages")
    print("🌐 Access the test interface at: http://localhost:5000/")
    print("📡 API endpoints available at: /chat, /health, /stats")
    print("💡 Tip: Set OLLAMA_TIMEOUT environment variable to adjust timeout")

    app.run(host='0.0.0.0', port=5000, debug=True)
