#!/usr/bin/env python3
"""
FastAPI Server Startup Script
Handles proper server configuration, health checks, and debugging
"""

import os
import sys
import time
import subprocess
import requests
import threading
from pathlib import Path

def check_python_version():
    """Ensure we're running Python 3.7+"""
    if sys.version_info < (3, 7):
        print("❌ Python 3.7+ is required")
        sys.exit(1)
    print(f"✅ Python {sys.version.split()[0]} detected")

def check_dependencies():
    """Check if required packages are installed"""
    required_packages = [
        'flask',
        'flask_cors',
        'requests'
    ]

    missing_packages = []

    for package in required_packages:
        try:
            __import__(package)
            print(f"✅ {package} is installed")
        except ImportError:
            missing_packages.append(package)
            print(f"❌ {package} is missing")

    if missing_packages:
        print(f"\n📦 Installing missing packages: {', '.join(missing_packages)}")
        try:
            subprocess.check_call([
                sys.executable, '-m', 'pip', 'install'
            ] + missing_packages)
            print("✅ Dependencies installed successfully")
        except subprocess.CalledProcessError:
            print("❌ Failed to install dependencies")
            print("Please run: pip install flask flask-cors requests")
            sys.exit(1)

def check_ollama():
    """Check if Ollama is running and accessible"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get('models', [])
            print(f"✅ Ollama is running with {len(models)} models")

            # Check for required model
            model_names = [m['name'] for m in models]
            if 'phi3:mini' in model_names:
                print("✅ phi3:mini model is available")
            elif any('phi' in name for name in model_names):
                print("⚠️ phi3:mini not found, but other phi models available")
            else:
                print("⚠️ No phi models found, you may need to run: ollama pull phi3:mini")

        else:
            print("⚠️ Ollama responded but with non-200 status")
    except requests.RequestException:
        print("❌ Ollama is not running or not accessible at localhost:11434")
        print("Please start Ollama first: ollama serve")
        return False

    return True

def test_port_availability(port=5000):
    """Test if the port is available"""
    import socket

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.bind(('localhost', port))
        sock.close()
        print(f"✅ Port {port} is available")
        return True
    except socket.error:
        print(f"❌ Port {port} is already in use")
        return False

def start_server():
    """Start the FastAPI server"""
    script_dir = Path(__file__).parent
    api_file = script_dir / "fast_chatbot_api.py"

    if not api_file.exists():
        print(f"❌ API file not found: {api_file}")
        sys.exit(1)

    print(f"🚀 Starting server from: {api_file}")

    # Change to the script directory
    os.chdir(script_dir)

    # Set environment variables
    os.environ['FLASK_APP'] = 'fast_chatbot_api.py'
    os.environ['FLASK_ENV'] = 'development'
    os.environ['FLASK_DEBUG'] = '1'

    try:
        # Start the Flask server
        subprocess.run([
            sys.executable,
            'fast_chatbot_api.py'
        ], check=True)
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"❌ Server failed to start: {e}")
        sys.exit(1)

def health_check():
    """Perform health check on the running server"""
    max_attempts = 30
    attempt = 0

    print("🔍 Waiting for server to start...")

    while attempt < max_attempts:
        try:
            response = requests.get("http://localhost:5000/health", timeout=2)
            if response.status_code == 200:
                print("✅ Server is healthy and responding")
                data = response.json()
                print(f"   Status: {data.get('status')}")
                print(f"   Uptime: {data.get('uptime', 'unknown')}")
                return True
        except requests.RequestException:
            pass

        attempt += 1
        time.sleep(1)
        print(f"   Attempt {attempt}/{max_attempts}...")

    print("❌ Server health check failed")
    return False

def test_webhook():
    """Test the Zoho webhook endpoint"""
    test_payload = {
        "message": {
            "text": "Hello from startup test",
            "timestamp": int(time.time() * 1000)
        },
        "visitor": {
            "id": "test-startup-user",
            "name": "Test User",
            "email": "test@startup.com"
        },
        "chat": {
            "sessionId": "test-startup-session",
            "messageCount": 1
        },
        "test": True
    }

    try:
        print("🧪 Testing webhook endpoint...")
        response = requests.post(
            "http://localhost:5000/webhook/zoho",
            json=test_payload,
            timeout=30
        )

        if response.status_code == 200:
            data = response.json()
            print("✅ Webhook test successful")
            print(f"   Response: {data.get('response', 'No response')[:100]}...")
            return True
        else:
            print(f"❌ Webhook test failed with status {response.status_code}")
            print(f"   Error: {response.text[:200]}")
            return False

    except requests.RequestException as e:
        print(f"❌ Webhook test error: {e}")
        return False

def run_startup_tests():
    """Run all startup tests in background after server starts"""
    time.sleep(3)  # Give server time to start

    print("\n" + "="*50)
    print("🧪 RUNNING STARTUP TESTS")
    print("="*50)

    if health_check():
        test_webhook()

    print("="*50)
    print("✅ Server is ready!")
    print("📊 Access the chat interface at: http://localhost:5000")
    print("🔧 Health check: http://localhost:5000/health")
    print("📈 Stats: http://localhost:5000/stats")
    print("🔗 Webhook: http://localhost:5000/webhook/zoho")

    if os.name == 'nt':  # Windows
        print("\n💡 To access from other devices on your network:")
        print("   Replace 'localhost' with your machine's IP address")

    print("\n🛑 Press Ctrl+C to stop the server")
    print("="*50)

def main():
    """Main startup function"""
    print("🚀 PERSONAL AI ASSISTANT - SERVER STARTUP")
    print("="*50)

    # Pre-flight checks
    check_python_version()
    check_dependencies()

    if not test_port_availability():
        print("⚠️ Port 5000 is in use. Attempting to continue anyway...")

    if not check_ollama():
        print("⚠️ Ollama issues detected. Server will start but AI responses may fail.")
        response = input("Continue anyway? (y/N): ")
        if response.lower() != 'y':
            sys.exit(1)

    print("\n" + "="*50)
    print("🎯 STARTING SERVER")
    print("="*50)

    # Start health check in background
    test_thread = threading.Thread(target=run_startup_tests, daemon=True)
    test_thread.start()

    # Start the server (this will block)
    start_server()

if __name__ == "__main__":
    main()
