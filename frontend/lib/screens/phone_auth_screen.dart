import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as auth_provider;

class _IndianPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 10 digits
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Format as XXXX-XXXX-XX
    String formatted = '';
    if (digitsOnly.isNotEmpty) {
      if (digitsOnly.length <= 4) {
        formatted = digitsOnly;
      } else if (digitsOnly.length <= 8) {
        formatted = '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
      } else {
        formatted =
            '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4, 8)}-${digitsOnly.substring(8)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCodeSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider =
        Provider.of<auth_provider.AuthProvider>(context, listen: false);

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
          content: Text(
              'Failed to send verification code: ${authProvider.errorMessage ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _codeController.text.isEmpty) return;

    final authProvider =
        Provider.of<auth_provider.AuthProvider>(context, listen: false);

    final success = await authProvider.verifyPhoneNumberWithCode(
      verificationId: _verificationId!,
      smsCode: _codeController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Invalid verification code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    final authProvider =
        Provider.of<auth_provider.AuthProvider>(context, listen: false);

    final success = await authProvider.verifyPhoneNumberWithCode(
      verificationId: _verificationId!,
      smsCode: credential.smsCode ?? '',
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    print('❌ Verification failed: ${e.code} - ${e.message}');
    if (mounted) {
      String errorMessage = 'Verification failed: ${e.message}';

      // Provide more specific error messages
      switch (e.code) {
        case 'invalid-phone-number':
          errorMessage =
              'Invalid phone number format. Please check and try again.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'quota-exceeded':
          errorMessage = 'SMS quota exceeded. Please try again later.';
          break;
        case 'app-not-authorized':
          errorMessage = 'App not authorized for phone authentication.';
          break;
        case 'missing-phone-number':
          errorMessage = 'Phone number is required.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    setState(() {
      _isCodeSent = true;
      _verificationId = verificationId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your phone'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    _verificationId = verificationId;
  }

  void _resendCode() {
    setState(() {
      _isCodeSent = false;
      _codeController.clear();
    });
    _sendVerificationCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // Phone Number Input
                  if (!_isCodeSent) _buildPhoneInput(),

                  // Verification Code Input
                  if (_isCodeSent) _buildCodeInput(),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // Resend Code
                  if (_isCodeSent) _buildResendCode(),

                  const SizedBox(height: 32),

                  // Back to Login
                  _buildBackToLogin(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.phone,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isCodeSent ? 'Verify Phone Number' : 'Enter Phone Number',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isCodeSent
              ? 'Enter the verification code sent to +91 ${_phoneController.text.replaceAll(RegExp(r'[^\d]'), '')}'
              : 'We\'ll send you a verification code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your 10-digit mobile number',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _IndianPhoneNumberFormatter(),
          ],
          onChanged: (value) {
            // Auto-format the phone number
            if (value.length == 10 && !value.startsWith('+91')) {
              _phoneController.text = '+91$value';
              _phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _phoneController.text.length),
              );
            }
          },
          decoration: InputDecoration(
            hintText: '9876543210',
            prefixText: '+91 ',
            prefixIcon: const Icon(Icons.phone, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            // Remove formatting and check if it's exactly 10 digits
            String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digitsOnly.length != 10) {
              return 'Please enter a valid 10-digit phone number';
            }
            // Check if it starts with valid Indian mobile prefixes
            if (!digitsOnly.startsWith(RegExp(r'[6-9]'))) {
              return 'Phone numbers must start with 6, 7, 8, or 9';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: 'Enter 6-digit code',
            prefixIcon: const Icon(Icons.security, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.length != 6) {
              return 'Please enter a valid 6-digit code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : (_isCodeSent ? _verifyCode : _sendVerificationCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isCodeSent ? 'Verify Code' : 'Send Code',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResendCode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: _resendCode,
          child: const Text(
            'Resend',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Want to use email instead? ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Email Login',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
