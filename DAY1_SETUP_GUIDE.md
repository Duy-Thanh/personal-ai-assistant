# Day 1: Backend Foundation Setup Guide

## 🚀 Quick Start

### Step 1: Create Google Cloud VM
```bash
# Create VM with these specs:
# - Machine type: e2-standard-2 (2 vCPU, 8GB RAM)
# - OS: Ubuntu 22.04 LTS
# - Disk: 20GB standard persistent disk
# - Firewall: Allow HTTP and HTTPS traffic
```

### Step 2: Upload Files to VM
Upload these files to your VM:
- `setup_vm.sh`
- `fast_chatbot_api.py`
- `deploy_api.sh`
- `test_api.sh`
- `setup_frontend.sh`
- `requirements.txt`
- `.env`
- `index.html` (Professional chat interface)
- `landing.html` (Professional landing page)

### Step 3: Run Setup Script
```bash
# Make scripts executable
chmod +x *.sh

# Run the main setup (Morning task - 2-3 hours)
./setup_vm.sh
```

### Step 4: Deploy API
```bash
# Deploy the Flask API (Afternoon task - 2-3 hours)
./deploy_api.sh
```

### Step 5: Setup Professional Frontend
```bash
# Setup the beautiful web interface
./setup_frontend.sh
```

### Step 6: Switch to Port 80 (Professional URLs)
```bash
# Switch from port 5000 to port 80 for clean URLs
./switch_to_port80.sh
```

### Step 7: Test Everything
```bash
# Test all endpoints and functionality
./test_api.sh

# Or test with external IP (port 80)
./test_api.sh http://YOUR-EXTERNAL-IP
```

## 🧪 Manual Testing Commands

### Test Health Endpoint
```bash
curl http://YOUR-IP:5000/health
```

### Test Chat Endpoint
```bash
curl -X POST http://YOUR-IP:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

### Test with Session ID
```bash
curl -X POST http://YOUR-IP:5000/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: my-session-123" \
  -d '{"message": "Remember this: my favorite color is blue"}'

# Follow up to test memory
curl -X POST http://YOUR-IP:5000/chat \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: my-session-123" \
  -d '{"message": "What is my favorite color?"}'
```

## 📊 Endpoints Available

**Port 5000 (Development):**
- **GET /** - Professional landing page with stats and features
- **GET /chat** - Beautiful ChatGPT-like interface  
- **POST /chat** - Main chat endpoint (API)
- **GET /health** - Health check
- **GET /stats** - Usage statistics
- **POST /webhook/zoho** - Zoho SalesIQ webhook (Day 2)

**Port 80 (Production - Recommended):**
- **GET http://your-ip/** - Professional landing page
- **GET http://your-ip/chat** - Beautiful ChatGPT-like interface  
- **POST http://your-ip/chat** - Main chat endpoint (API)
- **GET http://your-ip/health** - Health check
- **GET http://your-ip/stats** - Usage statistics
- **POST http://your-ip/webhook/zoho** - Zoho SalesIQ webhook

## 🔧 Troubleshooting

### If Ollama fails to start:
```bash
sudo systemctl restart ollama
ollama list
ollama pull phi3:mini
```

### If API fails to start:
```bash
sudo systemctl status personal-ai-assistant
sudo journalctl -u personal-ai-assistant -f
```

### If firewall blocks access:
```bash
sudo ufw allow 5000
sudo ufw status
```

## ✅ Day 1 Success Criteria

By end of Day 1, you should have:
- ✅ Working API at http://YOUR-IP/chat (POST endpoint)
- ✅ Professional landing page at http://YOUR-IP/
- ✅ Beautiful chat interface at http://YOUR-IP/chat
- ✅ Ollama running with Phi-3 Mini model
- ✅ Conversation memory working
- ✅ All endpoints responding correctly
- ✅ Mobile-responsive design
- ✅ Professional port 80 setup (no port numbers in URLs)

## 🎯 Ready for Day 2

Once Day 1 is complete, you'll be ready to:
- Set up Zoho SalesIQ account
- Create webhook integration
- Connect Zoho to your API
- Test end-to-end flow

## 💡 Pro Tips

1. **Save your VM's external IP** - you'll need it for Zoho integration
2. **Use Port 80** - Professional URLs without port numbers: http://YOUR-IP/
3. **Visit the landing page first** - http://YOUR-IP/ shows features and stats
4. **Test the chat interface** - http://YOUR-IP/chat for the full experience
5. **Monitor logs** - use `sudo journalctl -u personal-ai-assistant -f`
6. **Keep terminal open** - for troubleshooting and monitoring
