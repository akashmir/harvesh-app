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

  runApp(const PhoneAuthDebugApp());
}

class PhoneAuthDebugApp extends StatelessWidget {
  const PhoneAuthDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Auth Debug',
      home: const PhoneAuthDebugScreen(),
    );
  }
}

class PhoneAuthDebugScreen extends StatefulWidget {
  const PhoneAuthDebugScreen({super.key});

  @override
  State<PhoneAuthDebugScreen> createState() => _PhoneAuthDebugScreenState();
}

class _PhoneAuthDebugScreenState extends State<PhoneAuthDebugScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _status = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Sending verification code...';
    });

    try {
      String phoneNumber = _phoneController.text.trim();

      // Ensure phone number has +91 prefix
      if (!phoneNumber.startsWith('+91')) {
        if (phoneNumber.length == 10) {
          phoneNumber = '+91$phoneNumber';
        } else {
          setState(() {
            _status =
                'Invalid phone number format. Use 10 digits or +91XXXXXXXXXX';
            _isLoading = false;
          });
          return;
        }
      }

      print('📱 Attempting to send OTP to: $phoneNumber');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('✅ Verification completed automatically');
          setState(() {
            _status = 'Verification completed automatically';
            _isLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          setState(() {
            _status = 'Verification failed: ${e.code} - ${e.message}';
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📱 Code sent successfully');
          setState(() {
            _verificationId = verificationId;
            _status = 'Code sent successfully! Check your phone for SMS.';
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Code auto-retrieval timeout');
          setState(() {
            _verificationId = verificationId;
            _status = 'Code auto-retrieval timeout';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _codeController.text.isEmpty) {
      setState(() {
        _status = 'Please enter verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Verifying code...';
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );

      UserCredential result =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print('✅ Phone authentication successful: ${result.user?.uid}');
      setState(() {
        _status =
            'Phone authentication successful! User ID: ${result.user?.uid}';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Verification error: $e');
      setState(() {
        _status = 'Verification error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Auth Debug'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Phone Authentication Debug Tool',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '9876543210 or +919876543210',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Verification Code'),
            ),
            const SizedBox(height: 20),
            if (_verificationId != null) ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Code'),
              ),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_status),
                  const SizedBox(height: 8),
                  const Text(
                    'Check console for detailed logs',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
                '1. Enter your phone number (10 digits or +91XXXXXXXXXX)'),
            const Text('2. Tap "Send Verification Code"'),
            const Text('3. Check your phone for SMS'),
            const Text('4. Enter the 6-digit code'),
            const Text('5. Tap "Verify Code"'),
            const Text('6. Check console logs for detailed error messages'),
          ],
        ),
      ),
    );
  }
}
