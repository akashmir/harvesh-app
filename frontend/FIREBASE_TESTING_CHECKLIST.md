# Firebase Integration Testing Checklist

## Pre-Testing Setup

### 1. Install Dependencies
```bash
cd Flutter
flutter pub get
```

### 2. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

## Testing Steps

### 1. Basic Firebase Connection Test
Run the test script to verify Firebase is properly configured:
```bash
flutter run test_firebase_integration.dart
```

**Expected Output:**
- ✅ Firebase initialized successfully!
- ✅ Firestore connection successful!
- ✅ Firebase Auth initialized successfully!

### 2. App Launch Test
```bash
flutter run
```

**Expected Behavior:**
- App should launch without crashes
- Should show the enhanced login screen
- No Firebase-related error messages in console

### 3. Authentication Testing

#### Email/Password Registration
1. Tap "Sign Up" on login screen
2. Fill in registration form:
   - Full Name: Test User
   - Email: test@example.com
   - Phone: +1234567890 (optional)
   - Password: password123
   - Confirm Password: password123
3. Check "I agree to terms" checkbox
4. Tap "Create Account"

**Expected Result:**
- Account created successfully
- Redirected to home screen
- User data saved in Firestore

#### Email/Password Login
1. Use existing credentials to sign in
2. Tap "Sign In" button

**Expected Result:**
- Login successful
- Redirected to home screen
- User session maintained

#### Google Sign-in
1. Tap "Google" button on login screen
2. Complete Google authentication flow

**Expected Result:**
- Google sign-in successful
- User profile created/updated in Firestore
- Redirected to home screen

#### Phone Authentication
1. Tap "Phone" button on login screen
2. Enter phone number (use test numbers from Firebase Console)
3. Enter verification code

**Expected Result:**
- SMS sent successfully
- Verification code accepted
- Account created/authenticated

### 4. Profile Management Testing

#### View Profile
1. Navigate to Profile screen
2. Check if user data is displayed correctly

**Expected Result:**
- User name, email, phone displayed
- Join date shown
- Statistics displayed (may be 0 initially)

#### Update Profile
1. Tap "Edit Profile" button
2. Modify name or location
3. Tap "Save Changes"

**Expected Result:**
- Changes saved to Firestore
- UI updated with new data
- Success message shown

### 5. Query History Testing

#### Generate Crop Recommendation
1. Navigate to "Manual Crop Recommender"
2. Fill in soil parameters:
   - Nitrogen: 50
   - Phosphorus: 30
   - Potassium: 40
   - Temperature: 25
   - Humidity: 60
   - pH: 6.5
   - Rainfall: 100
3. Tap "Get Recommendation"

**Expected Result:**
- Recommendation generated
- Query saved to Firestore
- No error messages

#### View Query History
1. Navigate to "Query History" from home screen
2. Check "Crop Queries" tab

**Expected Result:**
- Previous queries displayed
- Query details shown (parameters, recommendations)
- Timestamps displayed

### 6. Data Persistence Testing

#### Sign Out and Sign In
1. Sign out from profile screen
2. Sign in again with same credentials

**Expected Result:**
- User data persists
- Query history maintained
- Profile information restored

#### App Restart
1. Close the app completely
2. Reopen the app

**Expected Result:**
- User remains signed in
- Data persists across sessions

## Troubleshooting Common Issues

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution:**
- Check that `firebase_options.dart` has correct configuration
- Verify Firebase is initialized in `main.dart`
- Ensure `google-services.json` is in `android/app/` directory

### Issue: "Google Sign-in failed"
**Solution:**
- Verify SHA-1 fingerprint is added to Firebase Console
- Check that Google Services plugin is applied
- Ensure `google-services.json` is properly configured

### Issue: "Permission denied" Firestore errors
**Solution:**
- Check Firestore security rules
- Ensure user is authenticated before accessing Firestore
- Verify user has proper permissions

### Issue: Phone authentication not working
**Solution:**
- Enable Phone authentication in Firebase Console
- Add test phone numbers in Firebase Console
- Check that phone number format is correct

### Issue: App crashes on startup
**Solution:**
- Check console for error messages
- Verify all dependencies are installed
- Clean and rebuild the project

## Firebase Console Verification

### 1. Authentication Tab
- Check that users are being created
- Verify sign-in methods are enabled
- Check user details and metadata

### 2. Firestore Database Tab
- Verify `users` collection exists
- Check user documents have correct structure
- Verify subcollections (`crop_queries`, etc.) are created

### 3. Project Settings
- Verify app is properly registered
- Check that `google-services.json` matches project
- Verify API keys are correct

## Performance Testing

### 1. Load Testing
- Create multiple test accounts
- Generate multiple queries
- Check app performance with data

### 2. Network Testing
- Test with poor network connection
- Verify offline behavior
- Check data synchronization

## Security Testing

### 1. Data Access
- Verify users can only access their own data
- Test with different user accounts
- Check Firestore security rules

### 2. Authentication Security
- Test with invalid credentials
- Verify session management
- Check token expiration

## Success Criteria

✅ **All authentication methods work**
✅ **User data is saved to Firestore**
✅ **Query history is displayed correctly**
✅ **Profile management works**
✅ **Data persists across sessions**
✅ **No crashes or errors**
✅ **Firebase Console shows correct data**

## Next Steps After Testing

1. **Fix any issues found during testing**
2. **Optimize performance if needed**
3. **Add additional error handling**
4. **Set up production environment**
5. **Configure proper security rules**
6. **Add monitoring and analytics**

## Support

If you encounter issues not covered in this checklist:
1. Check Firebase Console for error logs
2. Check Flutter console for error messages
3. Verify all configuration files are correct
4. Ensure all dependencies are up to date
5. Try clean rebuild: `flutter clean && flutter pub get`
