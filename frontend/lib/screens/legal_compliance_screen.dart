import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common/app_bar_widget.dart';
import '../widgets/common/card_widget.dart';
import '../widgets/common/button_widget.dart';

/// Legal compliance screen showing privacy policy and terms of service
class LegalComplianceScreen extends StatefulWidget {
  const LegalComplianceScreen({super.key});

  @override
  State<LegalComplianceScreen> createState() => _LegalComplianceScreenState();
}

class _LegalComplianceScreenState extends State<LegalComplianceScreen> {
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _dataProcessingAccepted = false;
  bool _marketingAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const CommonAppBar(
        title: 'Legal & Privacy',
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 24),
            _buildTermsSection(),
            const SizedBox(height: 24),
            _buildDataProcessingSection(),
            const SizedBox(height: 24),
            _buildMarketingSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Legal Compliance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Please review and accept our legal terms and privacy policy to continue using Harvest.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.privacy_tip,
                color: Color(0xFF1976D2),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              TextButton(
                onPressed: _showPrivacyPolicy,
                child: const Text('View Full Policy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'We collect and use your data to provide crop recommendations and improve our services. Your data is protected and never sold to third parties.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _privacyAccepted,
                onChanged: (value) {
                  setState(() {
                    _privacyAccepted = value ?? false;
                  });
                },
                activeColor: const Color(0xFF1976D2),
              ),
              const Expanded(
                child: Text(
                  'I have read and accept the Privacy Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              TextButton(
                onPressed: _showTermsOfService,
                child: const Text('View Full Terms'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'By using AgriSmart, you agree to our terms of service. Please read them carefully as they contain important information about your rights and obligations.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
                activeColor: const Color(0xFF2E7D32),
              ),
              const Expanded(
                child: Text(
                  'I have read and accept the Terms of Service',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataProcessingSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.data_usage,
                color: Color(0xFFE65100),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Data Processing Consent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'We process your agricultural data to provide personalized crop recommendations. This includes soil parameters, weather data, and location information.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _dataProcessingAccepted,
                onChanged: (value) {
                  setState(() {
                    _dataProcessingAccepted = value ?? false;
                  });
                },
                activeColor: const Color(0xFFE65100),
              ),
              const Expanded(
                child: Text(
                  'I consent to the processing of my agricultural data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingSection() {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign,
                color: Color(0xFF7B1FA2),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Marketing Communications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Receive updates about new features, agricultural tips, and relevant farming information. You can unsubscribe at any time.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _marketingAccepted,
                onChanged: (value) {
                  setState(() {
                    _marketingAccepted = value ?? false;
                  });
                },
                activeColor: const Color(0xFF7B1FA2),
              ),
              const Expanded(
                child: Text(
                  'I would like to receive marketing communications (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final allRequiredAccepted =
        _privacyAccepted && _termsAccepted && _dataProcessingAccepted;

    return Column(
      children: [
        CommonButton(
          text: 'Accept All & Continue',
          onPressed: allRequiredAccepted ? _acceptAll : null,
          type: ButtonType.primary,
          size: ButtonSize.large,
          width: double.infinity,
          icon: Icons.check_circle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CommonButton(
                text: 'Save Preferences',
                onPressed: _savePreferences,
                type: ButtonType.secondary,
                size: ButtonSize.medium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommonButton(
                text: 'Decline',
                onPressed: _decline,
                type: ButtonType.outline,
                size: ButtonSize.medium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• You can update your preferences at any time in Settings\n'
            '• Your data is protected and never sold to third parties\n'
            '• You have the right to request data deletion\n'
            '• Contact us at privacy@agrismart.com for any questions',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showLegalDocument(
      'Privacy Policy',
      'assets/docs/privacy_policy.md',
    );
  }

  void _showTermsOfService() {
    _showLegalDocument(
      'Terms of Service',
      'assets/docs/terms_of_service.md',
    );
  }

  void _showLegalDocument(String title, String assetPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<String>(
            future: _loadLegalDocument(assetPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading document'),
                );
              }

              return SingleChildScrollView(
                child: Text(
                  snapshot.data ?? 'Document not available',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String> _loadLegalDocument(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      return 'Document not available. Please contact support.';
    }
  }

  void _acceptAll() {
    if (_privacyAccepted && _termsAccepted && _dataProcessingAccepted) {
      _saveUserPreferences();
      _showSuccessDialog();
    }
  }

  void _savePreferences() {
    _saveUserPreferences();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved successfully'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _decline() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Terms'),
        content: const Text(
          'You must accept the Privacy Policy and Terms of Service to use AgriSmart. Would you like to exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }

  void _saveUserPreferences() {
    // Save user preferences to SharedPreferences or Firebase
    // This is a placeholder implementation
    print('Saving preferences:');
    print('Privacy Accepted: $_privacyAccepted');
    print('Terms Accepted: $_termsAccepted');
    print('Data Processing Accepted: $_dataProcessingAccepted');
    print('Marketing Accepted: $_marketingAccepted');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF2E7D32),
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Success'),
          ],
        ),
        content: const Text(
          'Thank you for accepting our terms and privacy policy. You can now use all features of Harvest.',
        ),
        actions: [
          CommonButton(
            text: 'Continue',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }
}
