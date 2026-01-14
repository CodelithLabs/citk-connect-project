## 🔧 CITK Connect Setup & Build Guide

### ⚠️ SECURITY NOTICE

This guide addresses critical security issues found in the audit. **DO NOT** commit API keys to version control.

---

## 1️⃣ Get Your API Keys

### Gemini API Key
1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy the key (keep it secret!)

### Google Maps API Key
1. Go to Google Cloud Console
2. Create a new project or use existing one
3. Enable Maps SDK
4. Create API key with Android/iOS/Web restrictions
5. Copy the key

---

## 2️⃣ Build with API Keys

### For Development (Local Testing)

```bash
# Using Gemini API Key
flutter run --dart-define=GEMINI_API_KEY=your_gemini_key_here

# Or with all keys
flutter run \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_maps_key
```

### For Release Build (Android)

```bash
# APK (testing device)
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key

# AAB (Google Play)
flutter build appbundle --release \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

### For Release Build (iOS)

```bash
# iOS
flutter build ios --release \
  --dart-define=GEMINI_API_KEY=your_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

---

## 3️⃣ Environment Variables (Production)

For CI/CD pipelines (GitHub Actions, Firebase Cloud Build):

```yaml
# .github/workflows/build.yml
env:
  GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}

- name: Build APK
  run: |
    flutter build apk --release \
      --dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }} \
      --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}
```

---

## 4️⃣ Firebase Remote Config (Recommended for Production)

For secure key rotation without rebuilding:

1. Go to Firebase Console → Remote Config
2. Add parameters:
   ```
   GEMINI_API_KEY: (your key)
   GOOGLE_MAPS_API_KEY: (your key)
   WEATHER_API_KEY: (optional)
   ```
3. Deploy configuration

The app will automatically fetch keys from Firebase Remote Config at startup.

---

## 5️⃣ Common Issues

### Error: "GEMINI_API_KEY is not configured"
**Solution:** Make sure to pass `--dart-define=GEMINI_API_KEY=your_key` when running/building

### Error: "Invalid API Key"
**Solution:** Double-check the key is copied correctly (no extra spaces)

### Error: "Maps API not enabled"
**Solution:** Enable Maps SDK in Google Cloud Console for your API key

---

## 6️⃣ Deployment Checklist

- [ ] API keys added to CI/CD secrets (GitHub/Firebase)
- [ ] Firebase Remote Config updated with keys
- [ ] No hardcoded keys in source code
- [ ] `.env` file in `.gitignore`
- [ ] Build tested with real API keys locally
- [ ] Release build signed correctly
