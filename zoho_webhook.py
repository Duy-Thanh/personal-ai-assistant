#!/usr/bin/env python3
"""
Zoho SalesIQ Webhook Handler
Handles incoming webhook requests from Zoho SalesIQ and routes them to the LLM API
"""

from flask import Flask, request, jsonify
import requests
import json
import logging
from datetime import datetime
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
OLLAMA_API_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "phi3"  # or "mistral" depending on your setup
MAX_CONTEXT_LENGTH = 4000
CONVERSATION_MEMORY = {}  # Store conversation history by visitor ID

def get_conversation_context(visitor_id):
    """Get conversation history for a visitor"""
    return CONVERSATION_MEMORY.get(visitor_id, [])

def update_conversation_context(visitor_id, user_message, ai_response):
    """Update conversation history for a visitor"""
    if visitor_id not in CONVERSATION_MEMORY:
        CONVERSATION_MEMORY[visitor_id] = []

    # Add new messages
    CONVERSATION_MEMORY[visitor_id].append({
        "role": "user",
        "content": user_message,
        "timestamp": datetime.now().isoformat()
    })
    CONVERSATION_MEMORY[visitor_id].append({
        "role": "assistant",
        "content": ai_response,
        "timestamp": datetime.now().isoformat()
    })

    # Keep only last 10 exchanges to prevent memory overflow
    if len(CONVERSATION_MEMORY[visitor_id]) > 20:
        CONVERSATION_MEMORY[visitor_id] = CONVERSATION_MEMORY[visitor_id][-20:]

def build_prompt_with_context(visitor_id, current_message):
    """Build prompt with conversation context"""
    context = get_conversation_context(visitor_id)

    # System prompt
    system_prompt = """You are a helpful AI assistant. You provide clear, concise, and helpful responses.
You remember the conversation context and can refer to previous messages when relevant.
Keep your responses conversational and engaging."""

    # Build conversation history
    conversation_text = f"{system_prompt}\n\n"

    # Add previous context
    for msg in context[-10:]:  # Last 5 exchanges
        if msg["role"] == "user":
            conversation_text += f"Human: {msg['content']}\n"
        else:
            conversation_text += f"Assistant: {msg['content']}\n"

    # Add current message
    conversation_text += f"Human: {current_message}\nAssistant: "

    return conversation_text

def call_ollama_api(prompt):
    """Call Ollama API with the prompt"""
    try:
        payload = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.7,
                "max_tokens": 500,
                "top_p": 0.9
            }
        }

        response = requests.post(
            OLLAMA_API_URL,
            json=payload,
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            return result.
