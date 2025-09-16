# 🔧 Fix Play Integrity API Error

## 🚨 The Problem
Firebase is trying to use Google's Play Integrity API but your app isn't configured for it. This causes the "app not authorized" error.

## ✅ Solution: Enable Play Integrity API

### Step 1: Enable Play Integrity API in Google Cloud Console

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project**: `agrismart-app-1930c`
3. **Go to APIs & Services** → **Library**
4. **Search for "Play Integrity API"**
5. **Click on "Play Integrity API"**
6. **Click "Enable"**

### Step 2: Configure Play Integrity API

1. **Go to APIs & Services** → **Credentials**
2. **Find your Android OAuth 2.0 client ID**
3. **Click on it to edit**
4. **Add your SHA-1 fingerprint** (if not already there):
   - `49:49:0C:23:7F:44:C1:D7:24:BC:0A:D1:F2:8E:A3:C1:FF:63:25:7A`
5. **Save**

### Step 3: Alternative Solution - Disable Play Integrity

If the above doesn't work, we can disable Play Integrity and use the old reCAPTCHA system:

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select project**: `agrismart-app-1930c`
3. **Go to Authentication** → **Settings**
4. **Scroll to "Phone authentication"**
5. **Disable "Use device verification"**
6. **Save**

### Step 4: Wait for Rate Limit Reset

The "too-many-requests" error means Firebase has temporarily blocked your device. Wait 1-2 hours before testing again.

## 🧪 Test After Fix

1. **Wait 1-2 hours** (for rate limit reset)
2. **Try the debug app again**:
   ```bash
   flutter run test_phone_auth_debug.dart
   ```
3. **Use a different phone number** if possible

## 🎯 Expected Result

After enabling Play Integrity API or disabling device verification:
- ✅ No more "Invalid app info in play_integrity_token" error
- ✅ No more "app not authorized" error
- ✅ Real SMS sent to phone numbers
- ✅ Phone authentication works properly

## 🆘 If Still Not Working

Try this alternative approach:
1. **Use a different device/emulator**
2. **Use a different phone number**
3. **Wait longer for rate limit reset**
4. **Check if your Google account has proper permissions**

The Play Integrity API is Google's new security system that replaced reCAPTCHA for phone authentication. Once properly configured, it will work seamlessly!
