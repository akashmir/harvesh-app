# 🔧 Fix "App Not Authorized" Phone Authentication Error

## 🚨 The Problem
You're getting "app not authorized for phone authentication" because Firebase needs your app's SHA-1 fingerprint to authorize phone authentication.

## ✅ Solution Steps

### Step 1: Get Your SHA-1 Fingerprint

#### For Debug Build (Development):
```bash
cd frontend
cd android
./gradlew signingReport
```

#### For Windows (if gradlew doesn't work):
```bash
cd frontend
cd android
gradlew.bat signingReport
```

#### Alternative Method (if above doesn't work):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `agrismart-app-1930c`
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your Android app: `com.example.crop`
6. Click **Add fingerprint**
7. Paste the SHA-1 fingerprint you got from Step 1
8. Click **Save**

### Step 3: Download Updated google-services.json

1. In the same **Project Settings** page
2. Find your Android app
3. Click **Download google-services.json**
4. Replace the existing file in `frontend/android/app/`

### Step 4: Enable Phone Authentication

1. Go to **Authentication** → **Sign-in method**
2. Click on **Phone** provider
3. **Enable** phone authentication
4. Click **Save**

### Step 5: Add Test Phone Numbers (for development)

1. In the **Phone** provider settings
2. Scroll to **"Phone numbers for testing"**
3. Add test numbers:
   - Phone: `+919876543210`
   - Code: `123456`
   - Phone: `+919876543211`
   - Code: `123456`
4. Click **Save**

## 🧪 Test the Fix

After completing all steps:

1. **Clean and rebuild**:
   ```bash
   cd frontend
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test phone authentication**:
   - Use phone number: `9876543210`
   - Use verification code: `123456`

## 🔍 Troubleshooting

### If you still get "app not authorized":

1. **Check SHA-1 fingerprint**:
   - Make sure you copied the correct SHA-1
   - It should look like: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`

2. **Verify google-services.json**:
   - Make sure the file is in `frontend/android/app/`
   - Check that the package name matches: `com.example.crop`

3. **Check Firebase Console**:
   - Verify phone authentication is enabled
   - Check that your app is listed in Project Settings

4. **Restart the app**:
   - Close the app completely
   - Run `flutter clean && flutter run`

## 📱 Expected Result

After fixing, you should see:
- ✅ Phone number input works
- ✅ OTP is sent successfully
- ✅ Verification completes without errors
- ✅ User is authenticated and logged in

## 🆘 Still Having Issues?

If you're still getting errors, please share:
1. The exact error message
2. Your SHA-1 fingerprint (from Step 1)
3. Whether you've completed all Firebase Console steps

The most common issue is missing or incorrect SHA-1 fingerprint in Firebase Console.
