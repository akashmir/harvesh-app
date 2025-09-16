import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crop/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully!');

  // Test Firestore connection
  print('📊 Testing Firestore connection...');
  try {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('test').doc('connection').set({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Firebase integration test successful!'
    });
    print('✅ Firestore connection successful!');

    // Clean up test document
    await firestore.collection('test').doc('connection').delete();
    print('🧹 Test document cleaned up');
  } catch (e) {
    print('❌ Firestore connection failed: $e');
  }

  // Test Firebase Auth
  print('🔐 Testing Firebase Auth...');
  try {
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth initialized successfully!');
    print('Current user: ${auth.currentUser?.uid ?? 'No user signed in'}');
  } catch (e) {
    print('❌ Firebase Auth initialization failed: $e');
  }

  print('🎉 Firebase integration test completed!');
}
