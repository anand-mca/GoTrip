# 🔐 Environment Setup - API Keys Configuration

This document explains how to configure API keys for local development.

## 📋 Required API Keys

### 1. **Groq API Key** (for GoBuddy AI descriptions)

**Required for:** GoBuddy travel guide AI feature

**How to get:**
1. Visit: [https://console.groq.com/keys](https://console.groq.com/keys)
2. Create a free account
3. Click "Create API Key"
4. Copy your key (starts with `gsk_`)

**Where to add:**
Edit: [`lib/services/groq_service.dart`](lib/services/groq_service.dart)

Replace line 6:
```dart
// Before:
static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';

// After:
static const String _apiKey = 'gsk_your_actual_key_here';
```

**⚠️ Important:** 
- Do NOT commit your actual API key to GitHub
- The placeholder value `YOUR_GROQ_API_KEY_HERE` is in `.gitignore`
- Each developer keeps their own local copy with their API key
- If you accidentally commit a key, immediately regenerate it at Groq console

### 2. **Supabase (Optional)**

If using Supabase backend for data:
- Edit: `lib/services/supabase_service.dart`
- Add your Supabase URL and Anonymous Key

### 3. **Google Maps/Routes API (Optional)**

If implementing Google Maps features:
- Edit: `lib/services/routing_service.dart`
- Add your API key

---

## 🔒 Best Practices

✅ **DO:**
- Keep API keys in local code only
- Regenerate keys if accidentally exposed
- Use environment-specific keys (dev/staging/prod)
- Never commit actual keys to GitHub

❌ **DON'T:**
- Hardcode production keys in the repo
- Share keys in Slack/Discord
- Use the same key for dev and production
- Commit `.env` files with real keys

---

## 🚀 Quick Start

1. Clone the repository
2. Copy and paste your API keys into the designated files
3. Run `flutter run`
4. GoBuddy AI will work with your keys

If you see "API key not configured" messages:
- Double-check the key is added correctly (no extra spaces)
- Verify it's the right format (starts with `gsk_` for Groq)
- Check internet connection

---

## 📝 For Contributors

If you're submitting a PR:
1. Never include real API keys
2. Use placeholder values like `YOUR_API_KEY_HERE`
3. Add a comment if a new API integration is needed
4. Update this file with setup instructions

---

## 🔄 GitHub Workflow

When pulling from GitHub:
```bash
git clone <repo>
cd gotrip_mobile
# Add your API keys to the relevant files
flutter pub get
flutter run
```

The `.gitignore` ensures sensitive files are never pushed to GitHub. ✅

---

**Questions?** Check the service files for comments or update logs.
