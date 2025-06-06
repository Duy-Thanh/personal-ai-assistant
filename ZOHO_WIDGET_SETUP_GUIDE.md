# 🔧 Zoho Widget Integration Setup Guide

This guide will help you set up three Zoho services as embedded widgets in your AI assistant application:
- 💬 **Zoho SalesIQ** (Live Chat)
- 📅 **Zoho Bookings** (Appointment Scheduling)
- 🛠️ **Zoho Assist** (Remote Support)

## 🚀 Quick Start Overview

All three services offer generous free tiers and can be set up in under 30 minutes. Each service embeds as a widget directly in your application's sidebar.

---

## 💬 Zoho SalesIQ Setup (Already Configured)

✅ **Status: Already integrated in your application**

Your SalesIQ widget is already configured with:
- Widget ID: `siq6cc792edbb3d3978c24391c98f41f9fbe11a88aae55bbe42061308737dc62af5`
- Live chat functionality
- Visitor tracking
- Mobile responsive

**No additional setup required** - SalesIQ is working!

---

## 📅 Zoho Bookings Setup

### Step 1: Create Your Account
1. Visit **https://bookings.zoho.com**
2. Click **"Sign Up for Free"**
3. Use your existing Zoho account or create new one
4. Complete the onboarding wizard

### Step 2: Configure Your First Service
1. **Create Event Type:**
   - Click **"Create Service"** or **"Add Event Type"**
   - Name: e.g., "Consultation Call", "Demo Meeting", "Support Session"
   - Duration: 15, 30, 45, or 60 minutes
   - Description: Brief description of the meeting purpose

2. **Set Your Availability:**
   - Working days: Monday-Friday (or your preference)
   - Working hours: e.g., 9:00 AM - 5:00 PM
   - Time zone: Select your local time zone
   - Buffer time: 5-15 minutes between meetings

3. **Customize Form Fields:**
   - Name (required)
   - Email (required)
   - Phone (optional)
   - Message/Notes (optional)
   - Add custom fields if needed

### Step 3: Customize Your Booking Page
1. Go to **Workspaces** → **Settings** → **Booking Page**
2. **Branding:**
   - Upload your logo
   - Choose color scheme
   - Add company information
3. **URL Setup:**
   - Choose your booking page URL: `https://bookings.zoho.com/portal/YOUR-NAME`
   - Make it memorable and professional

### Step 4: Get Your Widget URL
1. Navigate to **Workspaces** → **Share** → **Embed**
2. Copy the booking page URL (e.g., `https://bookings.zoho.com/portal/yourname`)
3. **Update your code:**

**In both `index.html` and `personal-ai-assistant/index.html`:**
```javascript
// Find this line (around line 4436):
src="https://bookings.zoho.com/portal/javalorant"

// Replace with your actual portal:
src="https://bookings.zoho.com/portal/YOUR-PORTAL-NAME"
```

### Step 5: Test Your Integration
1. Save the code changes
2. Refresh your application
3. Click **"Book Meeting"** in the sidebar
4. Verify the booking widget loads with your services

### Free Plan Limitations
- ✅ 1 event type
- ✅ 1 calendar integration
- ✅ Email notifications
- ✅ Custom booking page
- ✅ Mobile responsive

---

## 🛠️ Zoho Assist Setup

### Step 1: Create Your Account
1. Visit **https://assist.zoho.com**
2. Click **"Sign Up For Free"**
3. Create account or use existing Zoho credentials
4. Complete the setup process

### Step 2: Configure Your Organization
1. **Organization Setup:**
   - Organization name: Your company/brand name
   - Choose your subdomain: `yourname.assist.zoho.com`
   - Select your region (US, EU, etc.)

2. **Security Settings:**
   - Two-factor authentication (recommended)
   - Session security settings
   - Access permissions

### Step 3: Set Up Customer Portal
1. Go to **Settings** → **Customer Portal**
2. **Customize:**
   - Portal name and description
   - Company logo and branding
   - Welcome message
   - Contact information

3. **Get Portal URL:**
   - Your customer portal URL: `https://assist.zoho.com/customer/join`
   - Or custom URL if configured: `https://yourname.assist.zoho.com/customer`

### Step 4: Update Widget Configuration
**In both `index.html` and `personal-ai-assistant/index.html`:**
```javascript
// Find this line (around line 4496):
src="https://assist.zoho.com/customer/join"

// Replace with your custom URL if you have one:
src="https://yourname.assist.zoho.com/customer"
// OR keep the generic one for basic functionality
```

### Step 5: Test Remote Support
1. Save your changes
2. Refresh the application
3. Click **"Remote Support"** in sidebar
4. Test the session joining process

### Free Plan Features
- ✅ Unlimited remote support sessions
- ✅ Screen sharing and remote control
- ✅ Cross-platform support (Windows, Mac, Linux, mobile)
- ✅ File transfer capabilities
- ✅ Session recording (limited)
- ✅ Basic reporting

---

## 🔄 Integration Testing Checklist

### Before Going Live
- [ ] **SalesIQ**: Chat widget appears and responds
- [ ] **Bookings**: Widget loads with your services
- [ ] **Assist**: Customer portal loads correctly
- [ ] **Mobile**: All widgets work on mobile devices
- [ ] **Responsive**: Widgets fit properly in sidebar
- [ ] **Branding**: All services show your company info

### Test Scenarios
1. **Book an appointment** through the Bookings widget
2. **Start a remote support session** through Assist
3. **Send a chat message** through SalesIQ
4. **Toggle widgets** on/off multiple times
5. **Test on different devices** (desktop, tablet, mobile)

---

## 🎨 Customization Options

### Branding Consistency
All three services can be customized to match your brand:

1. **Colors**: Use your brand colors across all services
2. **Logos**: Upload your logo to each service
3. **Messages**: Customize welcome and confirmation messages
4. **Domains**: Set up custom subdomains for professional URLs

### Advanced Integrations
- **Calendar Sync**: Connect Google Calendar, Outlook, or Zoho Calendar
- **CRM Integration**: Link with Zoho CRM or other CRM systems
- **Email Templates**: Customize notification emails
- **Webhooks**: Set up automated workflows
- **API Access**: For custom integrations

---

## 🆘 Troubleshooting

### Common Issues

**Bookings Widget Not Loading:**
- Check if your portal URL is correct
- Verify your Zoho Bookings account is active
- Ensure the service is published and available

**Assist Widget Issues:**
- Confirm your organization is set up properly
- Check if customer portal is enabled
- Verify URL in the iframe src

**SalesIQ Problems:**
- Widget ID might be incorrect
- Check if SalesIQ account is active
- Verify script loading properly

### Getting Help
- **Zoho Support**: Each service has dedicated support channels
- **Documentation**: Comprehensive docs at help.zoho.com
- **Community**: Zoho community forums for user discussions
- **Contact**: Each service has live chat support

---

## 📊 Monitoring & Analytics

### Track Usage
- **SalesIQ**: Chat volume, response times, visitor analytics
- **Bookings**: Appointment rates, popular time slots, no-shows
- **Assist**: Session frequency, resolution times, customer satisfaction

### Optimization Tips
1. **Monitor conversion rates** from each widget
2. **A/B test** different booking time slots
3. **Track** which services are used most
4. **Optimize** widget placement and messaging
5. **Collect feedback** from users about widget experience

---

## 🚀 Next Steps

### Phase 1: Basic Setup (This Guide)
- [x] Configure all three Zoho services
- [x] Embed widgets in application
- [x] Test basic functionality

### Phase 2: Enhancement
- [ ] Set up custom domains
- [ ] Configure advanced integrations
- [ ] Implement webhooks and automation
- [ ] Add analytics tracking

### Phase 3: Scale
- [ ] Upgrade to paid plans as needed
- [ ] Add team members and permissions
- [ ] Implement advanced workflows
- [ ] Monitor and optimize performance

---

## 💡 Pro Tips

1. **Start Simple**: Use free plans to test everything first
2. **Brand Consistency**: Keep colors and messaging consistent across all widgets
3. **Mobile First**: Test on mobile devices - many users will access from phones
4. **Monitor Usage**: Track which widgets are used most to prioritize improvements
5. **User Feedback**: Ask users about their experience with the widgets
6. **Regular Updates**: Keep your Zoho services updated and configured properly

---

## 📞 Support Contacts

- **General Zoho Support**: https://help.zoho.com
- **SalesIQ Support**: https://help.zoho.com/portal/en/community/topic/salesiq
- **Bookings Support**: https://help.zoho.com/portal/en/community/topic/bookings
- **Assist Support**: https://help.zoho.com/portal/en/community/topic/assist

---

**🎉 Congratulations!** You now have three powerful Zoho services integrated as widgets in your AI assistant application. Users can seamlessly chat, book appointments, and get remote support without leaving your platform!