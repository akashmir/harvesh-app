# Firebase Setup Guide for AgriSmart Flutter App

This guide will help you set up Firebase for the AgriSmart Flutter app with authentication and Firestore database.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio or VS Code with Flutter extensions

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `agrismart-app` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

## Step 2: Add Android App to Firebase

1. In the Firebase Console, click "Add app" and select Android
2. Enter package name: `com.example.crop` (or your package name)
3. Enter app nickname: `AgriSmart Android`
4. Enter SHA-1 fingerprint (optional for now)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place the file in `Flutter/android/app/` directory

## Step 3: Add iOS App to Firebase (if needed)

1. Click "Add app" and select iOS
2. Enter iOS bundle ID: `com.example.crop`
3. Enter app nickname: `AgriSmart iOS`
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place the file in `Flutter/ios/Runner/` directory

## Step 4: Enable Authentication

1. In Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable the following sign-in methods:
   - **Email/Password**: Enable this
   - **Phone**: Enable this (for phone authentication)
   - **Google**: Enable this (for Google sign-in)

### For Google Sign-in:
1. Click on "Google" in sign-in methods
2. Enable it and set project support email
3. Save the Web SDK configuration (you'll need this later)

## Step 5: Set up Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database
5. Click "Done"

### Set up Firestore Security Rules

Replace the default rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's subcollections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Step 6: Update Firebase Configuration

1. Open `Flutter/lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-actual-android-api-key',
  appId: 'your-actual-android-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'your-actual-ios-api-key',
  appId: 'your-actual-ios-app-id',
  messagingSenderId: 'your-actual-sender-id',
  projectId: 'your-actual-project-id',
  storageBucket: 'your-actual-project-id.appspot.com',
  iosBundleId: 'com.example.crop',
);
```

You can find these values in:
- Android: `google-services.json` file
- iOS: `GoogleService-Info.plist` file
- Or in Project Settings > General tab

## Step 7: Install Dependencies

Run the following command in the Flutter directory:

```bash
flutter pub get
```

## Step 8: Test the Setup

1. Run the app: `flutter run`
2. Try registering a new account with email/password
3. Try signing in with Google
4. Try phone authentication
5. Check if user data is saved in Firestore

## Step 9: Configure Google Sign-in (Android)

1. In `Flutter/android/app/build.gradle`, add:

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

2. In `Flutter/android/app/src/main/AndroidManifest.xml`, add:

```xml
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

## Step 10: Configure Google Sign-in (iOS)

1. Add the following to `Flutter/ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from `GoogleService-Info.plist`.

## Troubleshooting

### Common Issues:

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Make sure Firebase is initialized in `main.dart`
   - Check that `firebase_options.dart` has correct configuration

2. **"Google Sign-in failed"**
   - Verify SHA-1 fingerprint is added to Firebase Console
   - Check that `google-services.json` is in the correct location

3. **"Permission denied" Firestore errors**
   - Check Firestore security rules
   - Ensure user is authenticated before accessing Firestore

4. **Phone authentication not working**
   - Enable Phone authentication in Firebase Console
   - Add test phone numbers in Firebase Console for testing

### Testing Phone Authentication:

1. Go to Firebase Console > Authentication > Sign-in method
2. Click on "Phone" and add test phone numbers
3. Use these test numbers during development

## Security Considerations

1. **Production Setup:**
   - Change Firestore rules to be more restrictive
   - Enable App Check for additional security
   - Set up proper user roles and permissions

2. **API Keys:**
   - Never commit API keys to version control
   - Use environment variables for sensitive data
   - Consider using Firebase App Check

## Next Steps

1. Test all authentication methods
2. Verify data is being saved to Firestore
3. Test query history functionality
4. Set up production environment
5. Configure proper security rules

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Check Flutter console for error messages
3. Verify all configuration files are in place
4. Ensure all dependencies are installed

For more information, refer to:
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Documentation](https://flutter.dev/docs)
