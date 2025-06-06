#!/usr/bin/env python3
"""
Nginx Configuration Diagnostic Script
Checks nginx status, configuration, and proxy setup for the Personal AI Assistant
"""

import os
import sys
import subprocess
import requests
import time
from pathlib import Path

def print_header(title):
    """Print a formatted header"""
    print("\n" + "="*60)
    print(f"🔧 {title}")
    print("="*60)

def run_command(command, description):
    """Run a shell command and return the result"""
    print(f"\n📋 {description}")
    print(f"Command: {command}")
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ Success")
            if result.stdout.strip():
                print(f"Output:\n{result.stdout}")
            return True, result.stdout
        else:
            print("❌ Failed")
            if result.stderr.strip():
                print(f"Error:\n{result.stderr}")
            return False, result.stderr
    except subprocess.TimeoutExpired:
        print("⏰ Command timed out")
        return False, "Timeout"
    except Exception as e:
        print(f"💥 Exception: {e}")
        return False, str(e)

def check_nginx_status():
    """Check if nginx is running and configured correctly"""
    print_header("NGINX STATUS CHECK")

    # Check if nginx is installed
    success, output = run_command("nginx -v", "Checking nginx version")
    if not success:
        print("❌ Nginx is not installed or not in PATH")
        print("💡 Install nginx: sudo apt update && sudo apt install nginx")
        return False

    # Check nginx status
    run_command("sudo systemctl status nginx --no-pager -l", "Checking nginx service status")

    # Check if nginx is listening on port 80
    run_command("sudo netstat -tlnp | grep :80", "Checking if port 80 is in use")

    # Test nginx configuration
    run_command("sudo nginx -t", "Testing nginx configuration syntax")

    return True

def check_nginx_config():
    """Check nginx configuration files"""
    print_header("NGINX CONFIGURATION CHECK")

    config_paths = [
        "/etc/nginx/sites-available/personal-ai-assistant",
        "/etc/nginx/sites-enabled/personal-ai-assistant",
        "/etc/nginx/nginx.conf"
    ]

    for config_path in config_paths:
        if os.path.exists(config_path):
            print(f"\n✅ Found: {config_path}")
            try:
                with open(config_path, 'r') as f:
                    content = f.read()
                    print(f"Content preview (first 500 chars):")
                    print("-" * 40)
                    print(content[:500])
                    if len(content) > 500:
                        print("... (truncated)")
                    print("-" * 40)
            except PermissionError:
                print("❌ Permission denied reading config file")
                print("💡 Try: sudo cat", config_path)
        else:
            print(f"❌ Missing: {config_path}")

    # Check if site is enabled
    sites_enabled = "/etc/nginx/sites-enabled/personal-ai-assistant"
    sites_available = "/etc/nginx/sites-available/personal-ai-assistant"

    if os.path.exists(sites_available) and not os.path.exists(sites_enabled):
        print(f"\n⚠️ Site exists but not enabled")
        print(f"💡 Enable with: sudo ln -s {sites_available} {sites_enabled}")
    elif os.path.exists(sites_enabled):
        print(f"\n✅ Site is enabled")

def check_backend_server():
    """Check if the Flask backend is running on port 5000"""
    print_header("BACKEND SERVER CHECK")

    # Check if port 5000 is in use
    success, output = run_command("netstat -tlnp | grep :5000", "Checking if port 5000 is in use")

    if not success or "5000" not in output:
        print("❌ No service running on port 5000")
        print("💡 Start the backend server first:")
        print("   cd /path/to/your/project")
        print("   python fast_chatbot_api.py")
        return False

    # Test backend endpoints
    endpoints = [
        "/health",
        "/stats",
        "/webhook/zoho"
    ]

    for endpoint in endpoints:
        url = f"http://localhost:5000{endpoint}"
        try:
            print(f"\n🧪 Testing: {url}")
            if endpoint == "/webhook/zoho":
                # POST request for webhook
                response = requests.post(url, json={
                    "message": {"text": "test"},
                    "visitor": {"id": "test"},
                    "chat": {"sessionId": "test", "messageCount": 1}
                }, timeout=5)
            else:
                # GET request for others
                response = requests.get(url, timeout=5)

            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print("   ✅ Endpoint is working")
            else:
                print(f"   ⚠️ Unexpected status: {response.status_code}")

        except requests.RequestException as e:
            print(f"   ❌ Failed to connect: {e}")

    return True

def check_proxy_connection():
    """Test the nginx proxy connection"""
    print_header("PROXY CONNECTION TEST")

    # Test direct connection to backend
    print("\n🧪 Testing direct backend connection...")
    try:
        response = requests.get("http://localhost:5000/health", timeout=5)
        print(f"Direct backend: {response.status_code} - {response.json().get('status', 'Unknown')}")
    except Exception as e:
        print(f"Direct backend failed: {e}")

    # Test nginx proxy connection
    print("\n🧪 Testing nginx proxy connection...")
    try:
        response = requests.get("http://localhost/health", timeout=5)
        print(f"Nginx proxy: {response.status_code} - {response.json().get('status', 'Unknown')}")
    except Exception as e:
        print(f"Nginx proxy failed: {e}")

    # Test from external IP if available
    try:
        # Get external IP
        import socket
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)

        print(f"\n🧪 Testing from local IP: {local_ip}")
        response = requests.get(f"http://{local_ip}/health", timeout=5)
        print(f"Local IP access: {response.status_code} - {response.json().get('status', 'Unknown')}")
    except Exception as e:
        print(f"Local IP test failed: {e}")

def check_firewall():
    """Check firewall settings"""
    print_header("FIREWALL CHECK")

    # Check ufw status
    run_command("sudo ufw status", "Checking UFW firewall status")

    # Check iptables
    run_command("sudo iptables -L INPUT -n | grep -E '(80|443|5000)'", "Checking iptables for relevant ports")

def provide_solutions():
    """Provide common solutions for nginx issues"""
    print_header("COMMON SOLUTIONS")

    print("""
🔧 COMMON NGINX ISSUES AND SOLUTIONS:

1. ❌ Nginx not installed:
   sudo apt update && sudo apt install nginx

2. ❌ Service not running:
   sudo systemctl start nginx
   sudo systemctl enable nginx

3. ❌ Configuration errors:
   sudo nginx -t
   sudo systemctl reload nginx

4. ❌ Site not enabled:
   sudo ln -s /etc/nginx/sites-available/personal-ai-assistant /etc/nginx/sites-enabled/
   sudo systemctl reload nginx

5. ❌ Permission issues:
   sudo chown -R www-data:www-data /var/www/
   sudo chmod -R 755 /var/www/

6. ❌ Backend not running:
   cd /path/to/your/project
   python fast_chatbot_api.py

7. ❌ Port conflicts:
   sudo netstat -tlnp | grep :80
   sudo fuser -k 80/tcp  # Kill processes using port 80

8. ❌ Firewall blocking:
   sudo ufw allow 80
   sudo ufw allow 443

9. ❌ SELinux issues (CentOS/RHEL):
   sudo setsebool -P httpd_can_network_connect 1

10. 🔄 Complete restart:
    sudo systemctl restart nginx
    sudo systemctl restart your-backend-service
    """)

def create_nginx_config():
    """Generate the correct nginx configuration"""
    print_header("NGINX CONFIGURATION GENERATOR")

    config = """server {
    listen 80;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Handle static files (if any)
    location /static/ {
        alias /home/$USER/personal-ai-assistant/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:5000/health;
        access_log off;
    }

    # Error pages
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
        internal;
    }
}"""

    print("📝 Recommended nginx configuration:")
    print("-" * 60)
    print(config)
    print("-" * 60)

    print("\n💡 To apply this configuration:")
    print("1. sudo nano /etc/nginx/sites-available/personal-ai-assistant")
    print("2. Copy and paste the configuration above")
    print("3. sudo ln -s /etc/nginx/sites-available/personal-ai-assistant /etc/nginx/sites-enabled/")
    print("4. sudo nginx -t")
    print("5. sudo systemctl reload nginx")

def main():
    """Main diagnostic function"""
    print("🔍 NGINX CONFIGURATION DIAGNOSTICS")
    print("=" * 60)
    print("This script will help diagnose nginx configuration issues")
    print("for the Personal AI Assistant application.")

    # Check if running as root/sudo for some commands
    if os.geteuid() != 0:
        print("\n⚠️ Some checks require sudo privileges")
        print("💡 Run with: sudo python check_nginx.py")

    # Run all checks
    check_nginx_status()
    check_nginx_config()
    check_backend_server()
    check_proxy_connection()
    check_firewall()
    provide_solutions()
    create_nginx_config()

    print("\n" + "="*60)
    print("✅ DIAGNOSTICS COMPLETE")
    print("="*60)
    print("Review the output above to identify and fix any issues.")

if __name__ == "__main__":
    main()
