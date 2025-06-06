# 🚀 Quick Setup Reference - Zoho Widgets

## 📋 Setup Checklist

### 📅 Zoho Bookings (5 minutes)
1. Go to https://bookings.zoho.com → Sign up
2. Create service (name, duration, availability)
3. Get portal URL: Workspaces → Share → Embed
4. Update code: Replace `javalorant` with your portal name

### 🛠️ Zoho Assist (3 minutes)
1. Go to https://assist.zoho.com → Sign up
2. Set organization name and subdomain
3. Enable customer portal in settings
4. Use default URL or update with custom subdomain

### 💬 Zoho SalesIQ (Already Done ✅)
- Already configured and working
- Widget ID: `siq6cc792edbb3d3978c24391c98f41f9fbe11a88aae55bbe42061308737dc62af5`

---

## 🔧 Code Updates Required

### File Locations
- `Zoho/index.html` (lines ~4436)
- `Zoho/personal-ai-assistant/index.html` (lines ~4436)

### Zoho Bookings URL
```javascript
// CHANGE THIS:
src="https://bookings.zoho.com/portal/javalorant"

// TO YOUR PORTAL:
src="https://bookings.zoho.com/portal/YOUR-PORTAL-NAME"
```

### Zoho Assist URL (Optional)
```javascript
// DEFAULT (works for everyone):
src="https://assist.zoho.com/customer/join"

// CUSTOM (if you set up subdomain):
src="https://yourname.assist.zoho.com/customer"
```

---

## 🎯 Quick Test Steps

1. **Save code changes**
2. **Refresh browser**
3. **Test Bookings**: Click "Book Meeting" → Should show your services
4. **Test Assist**: Click "Remote Support" → Should show join form
5. **Test SalesIQ**: Chat widget should appear (already working)

---

## 📞 Free Plan Limits

| Service | Free Features |
|---------|---------------|
| **SalesIQ** | Unlimited chats, 1 operator, basic analytics |
| **Bookings** | 1 event type, calendar sync, email notifications |
| **Assist** | Unlimited sessions, screen sharing, basic features |

---

## 🆘 Quick Fixes

**Widget not loading?**
- Check portal URL spelling
- Verify account is active
- Clear browser cache

**Need help?**
- Check main setup guide: `ZOHO_WIDGET_SETUP_GUIDE.md`
- Visit https://help.zoho.com
- Test with "About" buttons in sidebar

---

## ⚡ 2-Minute Setup Summary

1. **Bookings**: Sign up → Create service → Copy portal URL → Update code
2. **Assist**: Sign up → Set organization → Use default or custom URL
3. **SalesIQ**: Already done! ✅
4. **Test**: Refresh browser → Click widget buttons → Verify functionality

**Total time: ~8 minutes** ⏱️