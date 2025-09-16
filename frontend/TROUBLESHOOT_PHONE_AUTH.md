# 🔧 Troubleshooting "App Not Authorized" Error

## ✅ Good News: SHA-1 Fingerprint is Added!
I can see your `google-services.json` file has the correct SHA-1 fingerprint:
- **Certificate Hash**: `49490c237f44c1d724bc0ad1f28ea3c1ff63257a` ✅
- **Matches your SHA-1**: `49:49:0C:23:7F:44:C1:D7:24:BC:0A:D1:F2:8E:A3:C1:FF:63:25:7A` ✅

## 🚨 Possible Issues & Solutions

### Issue 1: App Cache/State
The app might be using cached authentication state.

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue 2: Firebase Console Phone Auth Not Enabled
Phone authentication might not be enabled in Firebase Console.

**Check:**
1. Go to Firebase Console → Authentication → Sign-in method
2. Make sure "Phone" is **ENABLED** ✅
3. If not enabled, enable it and save

### Issue 3: Package Name Mismatch
The package name in Firebase might not match your app.

**Verify:**
- **Firebase Console**: `com.example.crop`
- **Your app**: `com.example.crop`
- **Should match exactly** ✅

### Issue 4: Firebase Project Configuration
The project might not be properly configured for phone auth.

**Check:**
1. Go to Firebase Console → Project Settings
2. Make sure your Android app is listed
3. Verify the package name matches

### Issue 5: Billing/Quota Issues
Even with billing enabled, there might be quota issues.

**Check:**
1. Go to Firebase Console → Authentication → Users
2. Check if there are any quota warnings
3. Verify billing is active

## 🧪 Step-by-Step Debug Process

### Step 1: Verify Firebase Console Settings
1. **Go to**: https://console.firebase.google.com/
2. **Select project**: `agrismart-app-1930c`
3. **Authentication** → **Sign-in method**
4. **Phone provider** should be **ENABLED** ✅
5. **Save** if you made changes

### Step 2: Check Project Settings
1. **Project Settings** (gear icon)
2. **General tab**
3. **Your apps** section
4. **Android app** should show:
   - Package name: `com.example.crop`
   - SHA-1: `49:49:0C:23:7F:44:C1:D7:24:BC:0A:D1:F2:8E:A3:C1:FF:63:25:7A`

### Step 3: Clean and Rebuild
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Step 4: Test with Debug Logs
Look for these debug messages in the console:
```
🔍 AuthProvider initialized - User: null
📱 Code sent successfully
❌ Verification failed: [error message]
```

## 🔍 Alternative Solutions

### Solution 1: Try Different Phone Number Format
- **Try**: `+919876543210` (with +91)
- **Instead of**: `9876543210` (without +91)

### Solution 2: Check Phone Number Validation
Make sure the phone number is:
- **10 digits** after country code
- **Valid Indian number**
- **Not blocked** by carrier

### Solution 3: Test with Different Phone Number
Try with a different phone number to see if it's number-specific.

### Solution 4: Check Firebase Console Logs
1. Go to Firebase Console → Authentication
2. Check the "Users" tab
3. Look for any error messages or failed attempts

## 🚨 If Still Not Working

### Check These Specific Things:
1. **Are you using the correct Firebase project?** (`agrismart-app-1930c`)
2. **Is phone authentication enabled in Firebase Console?**
3. **Are you testing on a real device or emulator?**
4. **Is the app properly signed with the debug keystore?**

### Debug Information Needed:
Please share:
1. **Exact error message** you're seeing
2. **Phone number format** you're using
3. **Device type** (real device or emulator)
4. **Firebase Console status** (phone auth enabled?)

## 🎯 Expected Behavior After Fix

Once resolved, you should see:
- ✅ **No "app not authorized" error**
- ✅ **SMS sent to real phone numbers**
- ✅ **Real OTP verification works**
- ✅ **User successfully authenticated**

Let me know what you find in the Firebase Console and I'll help you resolve the specific issue!
