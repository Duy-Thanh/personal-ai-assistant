# Zoho SalesIQ Configuration Guide

## 🎯 Quick Setup Checklist

### Prerequisites
- [ ] Your API is running on Google Cloud VM
- [ ] Port 5000 is open in VM firewall
- [ ] Webhook endpoint `/webhook/zoho` is working
- [ ] You have your VM's external IP address

### Zoho Account Setup
- [ ] Created free Zoho SalesIQ account
- [ ] Verified email and logged in
- [ ] Portal ID and Department ID noted

### Bot Configuration
- [ ] Created Answer Bot named "Personal AI Assistant"
- [ ] Configured webhook integration
- [ ] Set webhook URL to your API
- [ ] Enabled visitor message forwarding

### Testing
- [ ] Webhook connection tested
- [ ] Chat widget deployed on test page
- [ ] End-to-end conversation working

---

## 📋 Detailed Configuration Steps

### Step 1: Zoho SalesIQ Account
1. **Sign up**: https://www.zoho.com/salesiq/
2. **Choose Free Plan**: 100 conversations/month
3. **Portal Setup**: Note your portal details

### Step 2: Answer Bot Creation
1. Navigate to **Automation → Answer Bot**
2. Click **Create Bot**
3. **Bot Name**: "Personal AI Assistant"
4. **Description**: "AI-powered assistant using custom LLM"

### Step 3: Webhook Configuration
```
Webhook URL: http://YOUR_VM_IP:5000/webhook/zoho
Method: POST
Content-Type: application/json
Timeout: 30 seconds (recommended)
```

### Step 4: Bot Flow Setup
1. **Trigger**: Any visitor message
2. **Condition**: Always (no specific conditions)
3. **Action**: Send to webhook
4. **Response**: Use webhook response as bot reply

### Step 5: Widget Installation
```html
<!-- Add this code to your website -->
<script type="text/javascript">
var $zoho=$zoho || {};$zoho.salesiq = $zoho.salesiq || 
{widgetcode:"YOUR_WIDGET_CODE_HERE", values:{},ready:function(){}};
var d=document;s=d.createElement("script");s.type="text/javascript";
s.id="zsiqscript";s.defer=true;
s.src="https://salesiq.zoho.com/widget";t=d.getElementsByTagName("script")[0];
t.parentNode.insertBefore(s,t);d.write("<div id='zsiqwidget'></div>");
</script>
```

---

## 🔧 Webhook Payload Format

### What Zoho Sends to Your API:
```json
{
  "message": {
    "text": "User's message here",
    "time": "2025-06-05T10:30:00.000Z",
    "type": "text"
  },
  "visitor": {
    "id": "unique_visitor_id",
    "name": "Visitor Name",
    "email": "visitor@example.com",
    "phone": "+1234567890"
  },
  "department": {
    "id": "dept_id",
    "name": "Department Name"
  },
  "chat": {
    "id": "chat_session_id",
    "feedback": null
  }
}
```

### What Your API Should Return:
```json
{
  "response": "AI's response to the user",
  "success": true
}
```

---

## 🧪 Testing Commands

### Test Webhook (PowerShell):
```powershell
.\test_zoho_webhook.ps1 YOUR_VM_IP
```

### Test Webhook (Bash):
```bash
./test_zoho_webhook.sh YOUR_VM_IP
```

### Manual cURL Test:
```bash
curl -X POST http://YOUR_VM_IP:5000/webhook/zoho \
  -H "Content-Type: application/json" \
  -d '{
    "message": {"text": "Hello AI!"},
    "visitor": {"id": "test_user"}
  }'
```

---

## 🔍 Troubleshooting

### Common Issues & Solutions:

#### 1. Webhook Not Receiving Requests
**Symptoms**: Bot doesn't respond, no logs in API
**Solutions**:
- Verify VM firewall allows port 5000
- Check webhook URL in Zoho settings
- Test API health endpoint directly

#### 2. Bot Responds with Error
**Symptoms**: Bot says "something went wrong"
**Solutions**:
- Check API logs for errors
- Verify Ollama is running
- Test direct chat endpoint

#### 3. Widget Not Loading
**Symptoms**: Chat widget doesn't appear
**Solutions**:
- Verify widget code is correct
- Check browser console for errors
- Test on different browsers

#### 4. Slow Responses
**Symptoms**: Long delays before bot responds
**Solutions**:
- Increase webhook timeout in Zoho
- Optimize LLM model if needed
- Check VM performance

---

## 📊 Expected Performance

### Response Times:
- Simple queries: 2-5 seconds
- Complex queries: 5-15 seconds
- Maximum timeout: 30 seconds

### Conversation Features:
- ✅ Context memory within session
- ✅ Visitor ID-based sessions
- ✅ Multiple concurrent users
- ✅ Error handling and fallbacks

---

## 🎉 Success Criteria

Your Day 2 setup is complete when:
- [ ] Chat widget loads on your test page
- [ ] Typing a message gets AI response
- [ ] Conversation context is maintained
- [ ] Multiple test conversations work
- [ ] API logs show successful webhook calls

---

## 🚀 Ready for Day 3?

Once Day 2 is working:
1. **Polish**: Professional landing page
2. **Performance**: Nginx reverse proxy
3. **Deploy**: Domain setup and final optimizations

Your Personal AI Assistant is almost ready for the world! 🌟
