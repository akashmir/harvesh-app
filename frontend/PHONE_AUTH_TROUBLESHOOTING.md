# Phone Authentication Troubleshooting Guide

## Issue: "Verification failed internal error"

This error typically occurs due to Firebase configuration issues. Here's how to fix it:

## Step 1: Firebase Console Configuration

### 1.1 Enable Phone Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `agrismart-app-1930c`
3. Go to **Authentication** → **Sign-in method**
4. Click on **Phone** provider
5. **Enable** phone authentication
6. Click **Save**

### 1.2 Add Test Phone Numbers (for development)
1. In the **Phone** provider settings
2. Scroll down to **Phone numbers for testing**
3. Add test numbers:
   - Phone number: `+919876543210`
   - Verification code: `123456`
4. Click **Add** for each test number
5. Click **Save**

## Step 2: Check Firebase Project Configuration

### 2.1 Verify Project Settings
1. Go to **Project Settings** (gear icon)
2. Go to **General** tab
3. Check that your Android app is listed
4. Verify the package name matches: `com.example.crop`

### 2.2 Download Updated google-services.json
1. In **Project Settings** → **General**
2. Find your Android app
3. Click **Download google-services.json**
4. Replace the existing file in `Flutter/android/app/`

## Step 3: Update Firebase Rules

### 3.1 Firestore Rules
Go to **Firestore Database** → **Rules** and ensure:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 3.2 Authentication Rules
Go to **Authentication** → **Settings** → **Authorized domains**:
- Add your domain if testing on web
- For mobile, this is usually not needed

## Step 4: Fix Phone Number Format

The issue might be with how we're formatting the phone number. Let me update the code:

### 4.1 Update Phone Number Processing

The phone number should be sent in E.164 format: `+919876543210`

### 4.2 Test with Console Logs

Add debug logging to see what's happening:

```dart
print('Sending verification to: $phoneNumber');
```

## Step 5: Common Issues and Solutions

### Issue 1: "Invalid phone number format"
**Solution**: Ensure phone number is in E.164 format (+91XXXXXXXXXX)

### Issue 2: "Quota exceeded"
**Solution**: 
- Use test phone numbers during development
- Check Firebase Console for quota limits
- Wait for quota reset (usually 24 hours)

### Issue 3: "App not authorized"
**Solution**:
- Verify SHA-1 fingerprint is added to Firebase Console
- Check that google-services.json is correct
- Ensure app is properly registered

### Issue 4: "Network error"
**Solution**:
- Check internet connection
- Verify Firebase project is active
- Check if there are any regional restrictions

## Step 6: Testing Steps

### 6.1 Test with Console Logs
1. Add debug prints in the phone auth code
2. Check what phone number is being sent
3. Verify the format is correct

### 6.2 Test with Firebase Console
1. Check Authentication → Users tab
2. See if any verification attempts are logged
3. Check for error messages

### 6.3 Test with Test Numbers
1. Use the test phone numbers you added
2. Use the verification code: `123456`
3. This bypasses SMS sending

## Step 7: Code Updates Needed

Let me update the phone authentication code to add better error handling and logging:

```dart
// Add this to phone_auth_screen.dart
Future<void> _sendVerificationCode() async {
  if (!_formKey.currentState!.validate()) return;

  final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
  
  // Ensure phone number has +91 prefix
  String phoneNumber = _phoneController.text.trim();
  String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  if (digitsOnly.length == 10) {
    phoneNumber = '+91$digitsOnly';
  }
  
  print('🔍 Debug: Sending verification to: $phoneNumber');
  
  final success = await authProvider.signInWithPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (credential) {
      print('✅ Verification completed automatically');
      _onVerificationCompleted(credential);
    },
    verificationFailed: (error) {
      print('❌ Verification failed: ${error.message}');
      _onVerificationFailed(error);
    },
    codeSent: (verificationId, resendToken) {
      print('📱 Code sent successfully');
      _onCodeSent(verificationId, resendToken);
    },
    codeAutoRetrievalTimeout: (verificationId) {
      print('⏰ Code auto-retrieval timeout');
      _onCodeAutoRetrievalTimeout(verificationId);
    },
  );

  if (!success && mounted) {
    print('❌ Failed to initiate phone verification');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to send verification code: ${authProvider.errorMessage}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Step 8: Firebase Console Verification

### 8.1 Check Authentication Logs
1. Go to Firebase Console
2. **Authentication** → **Users**
3. Look for any failed verification attempts
4. Check the error messages

### 8.2 Check Project Status
1. Ensure project is not suspended
2. Check billing status (if applicable)
3. Verify all services are enabled

## Step 9: Alternative Testing Method

### 9.1 Use Email Authentication First
1. Test email/password authentication first
2. Ensure Firebase is working properly
3. Then test phone authentication

### 9.2 Use Test Phone Numbers
1. Add test numbers in Firebase Console
2. Use verification code: `123456`
3. This bypasses actual SMS sending

## Step 10: Debug Information

When testing, check the console for these messages:
- `🔍 Debug: Sending verification to: +919876543210`
- `📱 Code sent successfully`
- `❌ Verification failed: [error message]`

## Quick Fix Checklist

- [ ] Phone authentication enabled in Firebase Console
- [ ] Test phone numbers added
- [ ] google-services.json updated
- [ ] SHA-1 fingerprint added
- [ ] Phone number format is +91XXXXXXXXXX
- [ ] Debug logs added
- [ ] Test with test numbers first

## Next Steps

1. **Follow the Firebase Console setup** (Steps 1-3)
2. **Update the code** with debug logging
3. **Test with test phone numbers** first
4. **Check console logs** for error details
5. **Verify Firebase project** is properly configured

Let me know what error messages you see in the console, and I'll help you fix the specific issue!
