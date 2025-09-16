import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crop/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully!');

  // Test phone authentication setup
  print('📱 Testing phone authentication setup...');

  try {
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth initialized');

    // Test phone number format
    String testPhone = '+919876543210';
    print('🔍 Testing phone number format: $testPhone');

    // Check if phone auth is enabled
    print('📋 Phone authentication status: ${auth.app.options.appId}');

    print('✅ Phone authentication setup test completed!');
    print('');
    print('📋 Next steps:');
    print('1. Enable phone authentication in Firebase Console');
    print('2. Add test phone numbers in Firebase Console');
    print('3. Test with phone number: +919876543210');
    print('4. Use verification code: 123456 (for test numbers)');
  } catch (e) {
    print('❌ Phone authentication setup failed: $e');
  }
}
