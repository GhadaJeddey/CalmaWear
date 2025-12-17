# 🔐 API Configuration Setup

This project requires several API keys to function properly. Follow these steps to configure them securely.

## 📋 Required API Keys

### 1. **Gemini AI API Key** (for AI Chatbot)
- **Get it from:** https://makersuite.google.com/app/apikey
- **Used for:** AI-powered chat assistant for autism support

### 2. **Cloudinary** (for Image Uploads)
- **Get it from:** https://console.cloudinary.com/
- **Used for:** Profile pictures and image storage
- **You need:**
  - Cloud Name
  - API Key
  - API Secret

### 3. **Twilio** (for SMS Alerts)
- **Get it from:** https://console.twilio.com/
- **Used for:** Sending stress alerts to teachers via SMS
- **You need:**
  - Account SID (starts with `AC`)
  - Auth Token
  - Twilio Phone Number (e.g., `+21658414453`)

## 🚀 Setup Instructions

### Step 1: Copy the Template File

```bash
cd lib/config
cp env.dart.template env.dart
```

### Step 2: Add Your API Keys

Open `lib/config/env.dart` and replace the empty strings with your actual keys:

```dart
class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE', // ← Add your key
  );

  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'your_cloud_name', // ← Add your cloud name
  );

  // ... etc
}
```

### Step 3: Verify Configuration

The file is already in `.gitignore`, so it won't be committed to Git. ✅

## ⚠️ Important Security Notes

- **NEVER commit `env.dart`** to Git (it's protected by `.gitignore`)
- **NEVER share your API keys** publicly
- **Use environment variables** in production
- Keep `env.dart.template` as a reference (safe to commit)

## 🧪 Testing Without API Keys

The app will still work with empty keys, but some features will be disabled:

- ❌ AI Chatbot won't respond
- ❌ Image uploads won't work
- ❌ SMS alerts won't be sent

## 🔄 For Team Members

When cloning this repository:

1. Copy `env.dart.template` to `env.dart`
2. Ask the project owner for the API keys
3. Fill in your local `env.dart` file
4. Never commit this file

## 📝 Alternative: Environment Variables

For production or CI/CD, use environment variables:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

---

**Need help?** Contact the project maintainer for API credentials.
