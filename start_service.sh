#!/bin/bash
set -e
cd /home/btldtdm1005/personal-ai-assistant
source venv/bin/activate
exec gunicorn --workers 2 --bind 127.0.0.1:5000 --timeout 120 --keep-alive 2 --max-requests 1000 --max-requests-jitter 50 fast_chatbot_api:app