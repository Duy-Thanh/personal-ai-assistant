# Day 2: Zoho SalesIQ Integration Setup Guide

## 🎯 Objective
Connect your Personal AI Assistant API to Zoho SalesIQ for a professional chat interface.

## ⏰ Time Estimate: 2-3 hours

## 📋 Prerequisites
- ✅ Day 1 completed: API running on your Google Cloud VM
- ✅ API accessible at `http://your-vm-ip:5000`
- ✅ VM firewall configured to allow port 5000

## 🔧 Step-by-Step Setup

### Part 1: Zoho SalesIQ Account Setup (30 minutes)

#### 1.1 Create Zoho SalesIQ Account
1. Go to https://www.zoho.com/salesiq/
2. Click "Sign Up Free"
3. Create account with your email
4. Verify email and complete setup
5. Choose the **Free Plan** (100 conversations/month)

#### 1.2 Initial SalesIQ Configuration
1. Log into your SalesIQ dashboard
2. Go to **Settings** → **Installation**
3. Copy your **Website Tracking Code** (we'll use this later)
4. Note your **Portal ID** and **Department ID**

### Part 2: Create Custom Bot (45 minutes)

#### 2.1 Create Answer Bot
1. In SalesIQ dashboard, go to **Automation** → **Answer Bot**
2. Click **Create Bot**
3. Name: "Personal AI Assistant"
4. Description: "AI-powered assistant using custom LLM"

#### 2.2 Configure Webhook Integration
1. In your bot settings, go to **Webhook**
2. Enable **Webhook Integration**
3. Set Webhook URL: `http://YOUR_VM_IP:5000/webhook/zoho`
4. Method: **POST**
5. Enable **Send visitor messages to webhook**

#### 2.3 Bot Flow Configuration
1. Create a simple flow:
   - **Trigger**: When visitor sends message
   - **Action**: Send to webhook
   - **Response**: Use webhook response

### Part 3: Test Integration (30 minutes)

#### 3.1 Test Webhook Connection
1. Use the webhook tester in SalesIQ
2. Send a test message
3. Verify your API receives the request
4. Check API logs for webhook activity

#### 3.2 Deploy Chat Widget
1. Go to **Settings** → **Installation**
2. Copy the chat widget code
3. Test on a simple HTML page

## 🧪 Testing Your Setup

### Test 1: Direct API Test
```bash
curl -X POST http://YOUR_VM_IP:5000/webhook/zoho \
  -H "Content-Type: application/json" \
  -d '{
    "message": {"text": "Hello AI!"},
    "visitor": {"id": "test_user_123"}
  }'
```

### Test 2: Chat Widget Test
Create a test page with the Zoho chat widget and verify:
- Widget loads correctly
- Messages send to your API
- AI responses appear in chat

## 🔍 Troubleshooting

### Common Issues:
1. **Webhook not receiving requests**
   - Check VM firewall (port 5000 open)
   - Verify webhook URL is correct
   - Check API logs for errors

2. **Bot not responding**
   - Verify webhook returns proper JSON format
   - Check Zoho bot flow configuration
   - Test API endpoint directly

3. **Connection timeouts**
   - Increase webhook timeout in Zoho
   - Optimize API response time
   - Check VM performance

## 📊 Expected Results

By end of Day 2, you should have:
- ✅ Zoho SalesIQ account configured
- ✅ Custom bot connected to your API
- ✅ Chat widget responding with AI
- ✅ End-to-end conversation flow working

## 🚀 Next Steps
Once Day 2 is complete, you'll be ready for Day 3: Polish & Deploy!

---

## 📝 Configuration Notes

### Your API Webhook Endpoint
Your API already includes a `/webhook/zoho` endpoint that:
- Accepts POST requests from Zoho
- Extracts user messages
- Sends to your LLM
- Returns properly formatted responses

### Zoho Response Format
Your API returns responses in the format Zoho expects:
```json
{
  "response": "AI response text",
  "success": true
}
```

### Session Management
The webhook uses Zoho visitor IDs to maintain conversation context across messages.
