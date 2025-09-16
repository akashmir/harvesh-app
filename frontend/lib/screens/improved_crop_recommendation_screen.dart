import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/error_handler.dart';
import '../services/network_service.dart';
import '../services/offline_service.dart';
import '../config/app_config.dart';

class ImprovedCropRecommendationScreen extends StatefulWidget {
  const ImprovedCropRecommendationScreen({super.key});

  @override
  State<ImprovedCropRecommendationScreen> createState() =>
      _ImprovedCropRecommendationScreenState();
}

class _ImprovedCropRecommendationScreenState
    extends State<ImprovedCropRecommendationScreen>
    with TickerProviderStateMixin {
  final nitrogenController = TextEditingController();
  final phosphorusController = TextEditingController();
  final potassiumController = TextEditingController();
  final temperatureController = TextEditingController();
  final humidityController = TextEditingController();
  final phController = TextEditingController();
  final rainfallController = TextEditingController();

  String recommendation = "";
  String confidence = "";
  List<Map<String, dynamic>> topPredictions = [];
  bool isLoading = false;
  String selectedModel = "rf";
  AppError? currentError;
  bool isOffline = false;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnectivity();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await NetworkService.checkConnectivity();
    setState(() {
      this.isOffline = !isOnline;
    });
  }

  @override
  void dispose() {
    nitrogenController.dispose();
    phosphorusController.dispose();
    potassiumController.dispose();
    temperatureController.dispose();
    humidityController.dispose();
    phController.dispose();
    rainfallController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> getRecommendation() async {
    // Validate input
    final validationError = _validateInput();
    if (validationError != null) {
      setState(() {
        currentError = validationError;
      });
      ErrorHandler.showErrorSnackBar(context, validationError);
      return;
    }

    setState(() {
      isLoading = true;
      recommendation = "";
      confidence = "";
      topPredictions = [];
      currentError = null;
    });

    try {
      // Check API configuration
      if (!AppConfig.isCropApiUrlValid) {
        final configError =
            ErrorHandler.handleConfigurationError('Crop API URL');
        setState(() {
          currentError = configError;
          isLoading = false;
        });
        ErrorHandler.showErrorDialog(context, configError);
        return;
      }

      // Prepare request data
      final requestData = {
        'N': double.parse(nitrogenController.text),
        'P': double.parse(phosphorusController.text),
        'K': double.parse(potassiumController.text),
        'temperature': double.parse(temperatureController.text),
        'humidity': double.parse(humidityController.text),
        'ph': double.parse(phController.text),
        'rainfall': double.parse(rainfallController.text),
        'model_type': selectedModel,
      };

      // Make API request with retry and offline support
      final response = await NetworkService.post(
        AppConfig.cropRecommendationEndpoint,
        body: requestData,
        timeout: AppConfig.apiTimeout,
        saveForOfflineSync: true,
      );

      // Process successful response
      setState(() {
        recommendation = response['recommended_crop'] ?? 'Unknown';
        confidence = ((response['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
        topPredictions = List<Map<String, dynamic>>.from(
            response['top_3_predictions'] ?? []);
        isLoading = false;
      });

      // Cache the recommendation for offline access
      await OfflineService.cacheCropRecommendation(
        inputData: requestData,
        recommendationData: response,
        modelType: selectedModel,
      );

      // Save to Firestore (background operation)
      _saveQueryToFirestore(response);
    } catch (error) {
      AppError appError;

      if (error is AppError) {
        appError = error;
      } else {
        appError = ErrorHandler.handleUnknownError(error);
      }

      setState(() {
        currentError = appError;
        isLoading = false;
      });

      // Show appropriate error message
      if (appError.isRetryable) {
        ErrorHandler.showErrorDialog(
          context,
          appError,
          onRetry: getRecommendation,
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, appError);
      }
    }
  }

  AppError? _validateInput() {
    final fields = [
      ('Nitrogen', nitrogenController.text),
      ('Phosphorus', phosphorusController.text),
      ('Potassium', potassiumController.text),
      ('Temperature', temperatureController.text),
      ('Humidity', humidityController.text),
      ('pH', phController.text),
      ('Rainfall', rainfallController.text),
    ];

    for (final (fieldName, value) in fields) {
      if (value.isEmpty) {
        return ErrorHandler.handleValidationError(
          fieldName,
          'This field is required',
        );
      }

      final numValue = double.tryParse(value);
      if (numValue == null) {
        return ErrorHandler.handleValidationError(
          fieldName,
          'Please enter a valid number',
        );
      }

      // Range validation
      switch (fieldName) {
        case 'Nitrogen':
        case 'Phosphorus':
        case 'Potassium':
          if (numValue < 0 || numValue > 200) {
            return ErrorHandler.handleValidationError(
              fieldName,
              'Must be between 0 and 200 kg/ha',
            );
          }
          break;
        case 'Temperature':
          if (numValue < -10 || numValue > 50) {
            return ErrorHandler.handleValidationError(
              fieldName,
              'Must be between -10 and 50°C',
            );
          }
          break;
        case 'Humidity':
          if (numValue < 0 || numValue > 100) {
            return ErrorHandler.handleValidationError(
              fieldName,
              'Must be between 0 and 100%',
            );
          }
          break;
        case 'pH':
          if (numValue < 3.5 || numValue > 9.5) {
            return ErrorHandler.handleValidationError(
              fieldName,
              'Must be between 3.5 and 9.5',
            );
          }
          break;
        case 'Rainfall':
          if (numValue < 0 || numValue > 3000) {
            return ErrorHandler.handleValidationError(
              fieldName,
              'Must be between 0 and 3000 mm',
            );
          }
          break;
      }
    }

    return null;
  }

  Future<void> _saveQueryToFirestore(
      Map<String, dynamic> recommendationData) async {
    try {
      final firestoreService = FirestoreService();
      final inputData = {
        'N': double.parse(nitrogenController.text),
        'P': double.parse(phosphorusController.text),
        'K': double.parse(potassiumController.text),
        'temperature': double.parse(temperatureController.text),
        'humidity': double.parse(humidityController.text),
        'ph': double.parse(phController.text),
        'rainfall': double.parse(rainfallController.text),
        'model_type': selectedModel,
      };

      final recommendations = List<Map<String, dynamic>>.from(
          recommendationData['top_3_predictions'] ?? []);

      await firestoreService.saveCropRecommendationQuery(
        inputData: inputData,
        recommendations: recommendations,
        queryType: 'manual',
      );
    } catch (e) {
      // Log error but don't show to user as this is a background operation
      ErrorHandler.logError(
        ErrorHandler.handleUnknownError(e),
        context: 'Firestore Save',
      );
    }
  }

  void clearForm() {
    setState(() {
      nitrogenController.clear();
      phosphorusController.clear();
      potassiumController.clear();
      temperatureController.clear();
      humidityController.clear();
      phController.clear();
      rainfallController.clear();
      recommendation = "";
      confidence = "";
      topPredictions = [];
      currentError = null;
    });
  }

  Future<void> _loadCachedRecommendations() async {
    try {
      final cachedData = await OfflineService.getCachedCropRecommendations();
      if (cachedData.isNotEmpty) {
        // Show cached data dialog
        _showCachedDataDialog(cachedData);
      }
    } catch (e) {
      ErrorHandler.logError(
        ErrorHandler.handleUnknownError(e),
        context: 'Load Cached Data',
      );
    }
  }

  void _showCachedDataDialog(List<Map<String, dynamic>> cachedData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cached Recommendations'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cachedData.length,
            itemBuilder: (context, index) {
              final data = cachedData[index];
              return ListTile(
                title: Text(data['recommendationData']['recommended_crop'] ??
                    'Unknown'),
                subtitle: Text(
                    'Confidence: ${((data['recommendationData']['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                trailing: Text(
                  _formatTimestamp(data['timestamp']),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Load this recommendation
                  _loadCachedRecommendation(data);
                },
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

  void _loadCachedRecommendation(Map<String, dynamic> data) {
    final recommendationData = data['recommendationData'];
    setState(() {
      recommendation = recommendationData['recommended_crop'] ?? 'Unknown';
      confidence =
          ((recommendationData['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
      topPredictions = List<Map<String, dynamic>>.from(
          recommendationData['top_3_predictions'] ?? []);
    });
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOffline) _buildOfflineBanner(),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildModelSelection(),
                const SizedBox(height: 24),
                _buildInputForm(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (currentError != null) _buildErrorCard(),
                if (recommendation.isNotEmpty) _buildResultsSection(),
                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Crop Recommendation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        if (isOffline)
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _loadCachedRecommendations,
            tooltip: 'View Cached Data',
          ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            _showHelpDialog();
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'AI-Powered Crop Recommendation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your soil parameters to get personalized crop recommendations using advanced machine learning.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select AI Model',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModelCard(
                  title: 'Random Forest',
                  accuracy: '99.55%',
                  description: 'High accuracy, fast predictions',
                  isSelected: selectedModel == 'rf',
                  onTap: () => setState(() => selectedModel = 'rf'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModelCard(
                  title: 'Neural Network',
                  accuracy: '98.86%',
                  description: 'Deep learning, complex patterns',
                  isSelected: selectedModel == 'nn',
                  onTap: () => setState(() => selectedModel = 'nn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required String title,
    required String accuracy,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color:
                      isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                  size: 20,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    accuracy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Soil Parameters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
              "Nitrogen (N) - kg/ha", nitrogenController, Icons.science),
          _buildInputField(
              "Phosphorus (P) - kg/ha", phosphorusController, Icons.science),
          _buildInputField(
              "Potassium (K) - kg/ha", potassiumController, Icons.science),
          _buildInputField(
              "Temperature (°C)", temperatureController, Icons.thermostat),
          _buildInputField(
              "Humidity (%)", humidityController, Icons.water_drop),
          _buildInputField("Soil pH", phController, Icons.eco),
          _buildInputField("Rainfall (mm)", rainfallController, Icons.cloud),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
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
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: clearForm,
            icon: const Icon(Icons.clear, size: 20),
            label: const Text('Clear Form'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : getRecommendation,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.psychology, size: 20),
                  label:
                      Text(isLoading ? 'Analyzing...' : 'Get Recommendation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    if (currentError == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            ErrorHandler.getErrorColor(currentError!.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ErrorHandler.getErrorColor(currentError!.severity)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ErrorHandler.getErrorIcon(currentError!.type),
            color: ErrorHandler.getErrorColor(currentError!.severity),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ErrorHandler.getErrorTitle(currentError!.type),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ErrorHandler.getErrorColor(currentError!.severity),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentError!.userFriendlyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: ErrorHandler.getErrorColor(currentError!.severity),
                  ),
                ),
              ],
            ),
          ),
          if (currentError!.isRetryable)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: getRecommendation,
              tooltip: 'Retry',
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      children: [
        _buildRecommendationCard(),
        if (topPredictions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTopPredictionsCard(),
        ],
      ],
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF4CAF50).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Recommended Crop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Confidence: $confidence%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPredictionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3 Predictions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          ...topPredictions.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> prediction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == 0
                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prediction['crop'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: index == 0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF212121),
                        ),
                      ),
                    ),
                    Text(
                      '${(prediction['confidence'] * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: index == 0
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Guidelines'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use this feature:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Enter your soil parameters accurately'),
              Text('2. Select an AI model (Random Forest recommended)'),
              Text('3. Click "Get Recommendation" to analyze'),
              Text('4. Review the recommended crop and alternatives'),
              SizedBox(height: 16),
              Text(
                'Parameter Guidelines:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Nitrogen: 0-200 kg/ha'),
              Text('• Phosphorus: 0-200 kg/ha'),
              Text('• Potassium: 0-200 kg/ha'),
              Text('• Temperature: -10 to 50°C'),
              Text('• Humidity: 0-100%'),
              Text('• pH: 3.5-9.5'),
              Text('• Rainfall: 0-3000 mm'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
