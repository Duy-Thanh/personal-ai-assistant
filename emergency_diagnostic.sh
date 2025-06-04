#!/bin/bash
# Emergency Diagnostic Script
# Run this to find out why the service won't start

echo "🚨 Emergency Service Diagnostic"
echo "==============================="

# Check current directory and files
echo "📍 Current location: $(pwd)"
echo "📂 Files in current directory:"
ls -la

echo ""
echo "🔍 Looking for project directory..."
PROJECT_DIRS=(
    "/home/$USER/personal-ai-assistant"
    "/home/$USER"
    "$(pwd)"
)

for dir in "${PROJECT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "📂 Checking: $dir"
        if [ -f "$dir/fast_chatbot_api.py" ]; then
            echo "✅ Found API file in: $dir"
            PROJECT_DIR="$dir"
            break
        fi
    fi
done

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Project directory not found!"
    echo "🔍 Searching for fast_chatbot_api.py..."
    find /home/$USER -name "fast_chatbot_api.py" 2>/dev/null || echo "❌ fast_chatbot_api.py not found anywhere"
    exit 1
fi

cd "$PROJECT_DIR"
echo "📍 Working in: $(pwd)"

echo ""
echo "🐍 Python Environment Check:"
echo "============================="

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "✅ Virtual environment found"
    
    # Check if gunicorn is installed
    if [ -f "venv/bin/gunicorn" ]; then
        echo "✅ Gunicorn binary exists: venv/bin/gunicorn"
    else
        echo "❌ Gunicorn binary missing"
        echo "📦 Installing gunicorn..."
        source venv/bin/activate
        pip install gunicorn
    fi
    
    # Test activation
    echo "🧪 Testing virtual environment..."
    source venv/bin/activate
    echo "✅ Virtual environment activated"
    echo "🐍 Python version: $(python --version)"
    echo "📦 Gunicorn version: $(gunicorn --version 2>/dev/null || echo 'Not installed')"
    
else
    echo "❌ Virtual environment not found"
    echo "🔧 Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install flask flask-cors requests ollama python-dotenv gunicorn
fi

echo ""
echo "🔧 Service Configuration Check:"
echo "==============================="

echo "📋 Current systemd service:"
sudo cat /etc/systemd/system/personal-ai-assistant.service 2>/dev/null || echo "❌ Service file not found"

echo ""
echo "📊 Service Status:"
sudo systemctl status personal-ai-assistant --no-pager -l

echo ""
echo "📝 Recent Service Logs:"
sudo journalctl -u personal-ai-assistant --no-pager -n 20

echo ""
echo "🧪 Manual Test:"
echo "==============="

# Test if we can run the API manually
echo "🚀 Testing manual API start..."
source venv/bin/activate

# First try direct Python
echo "🐍 Testing direct Python execution..."
timeout 10s python fast_chatbot_api.py &
PYTHON_PID=$!
sleep 3

if curl -s http://localhost:5000/health >/dev/null 2>&1; then
    echo "✅ Direct Python execution works!"
    kill $PYTHON_PID 2>/dev/null
else
    echo "❌ Direct Python execution failed"
    kill $PYTHON_PID 2>/dev/null
fi

# Then try gunicorn
echo "🦄 Testing gunicorn execution..."
timeout 10s gunicorn --workers 1 --bind 127.0.0.1:5000 fast_chatbot_api:app &
GUNICORN_PID=$!
sleep 3

if curl -s http://localhost:5000/health >/dev/null 2>&1; then
    echo "✅ Gunicorn execution works!"
    kill $GUNICORN_PID 2>/dev/null
else
    echo "❌ Gunicorn execution failed"
    kill $GUNICORN_PID 2>/dev/null
fi

echo ""
echo "🔧 Quick Fixes:"
echo "==============="
echo ""
echo "If virtual environment was missing:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl restart personal-ai-assistant"
echo ""
echo "If service file is wrong:"
echo "  sudo ./fix_service.sh  # (will create this script)"
echo ""
echo "If you want to run manually for now:"
echo "  cd $PROJECT_DIR"
echo "  source venv/bin/activate" 
echo "  python fast_chatbot_api.py"
