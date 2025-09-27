import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/location_service.dart';
import '../services/regional_data_service.dart';
import '../config/app_config.dart';

class EnhancedSimpleLocationCropScreen extends StatefulWidget {
  const EnhancedSimpleLocationCropScreen({super.key});

  @override
  State<EnhancedSimpleLocationCropScreen> createState() =>
      _EnhancedSimpleLocationCropScreenState();
}

class _EnhancedSimpleLocationCropScreenState
    extends State<EnhancedSimpleLocationCropScreen>
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
  bool isLocationLoading = false;
  String selectedModel = "rf";
  String locationInfo = "";
  RegionalData? regionalData;
  bool useLocationData = true;
  String errorMessage = "";

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

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

    _loadLocationData();
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

  Future<void> _loadLocationData() async {
    if (!useLocationData) return;

    setState(() {
      isLocationLoading = true;
      errorMessage = "";
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          locationInfo = "Unable to get location. Using manual input.";
          isLocationLoading = false;
        });
        return;
      }

      final locationName = await LocationService.getLocationName(
          position.latitude, position.longitude);

      regionalData = await RegionalDataService.getRegionalData(
          position.latitude, position.longitude);

      setState(() {
        locationInfo = locationName;
        isLocationLoading = false;
      });

      if (regionalData != null) {
        _fillFormWithRegionalData(regionalData!);
      }
    } catch (e) {
      setState(() {
        locationInfo = "Error getting location: $e";
        isLocationLoading = false;
      });
    }
  }

  void _fillFormWithRegionalData(RegionalData data) {
    setState(() {
      nitrogenController.text = data.nitrogen.toStringAsFixed(1);
      phosphorusController.text = data.phosphorus.toStringAsFixed(1);
      potassiumController.text = data.potassium.toStringAsFixed(1);
      temperatureController.text = data.temperature.toStringAsFixed(1);
      humidityController.text = data.humidity.toStringAsFixed(1);
      phController.text = data.ph.toStringAsFixed(1);
      rainfallController.text = data.rainfall.toStringAsFixed(1);
    });
  }

  Future<void> getRecommendation() async {
    if (nitrogenController.text.isEmpty ||
        phosphorusController.text.isEmpty ||
        potassiumController.text.isEmpty ||
        temperatureController.text.isEmpty ||
        humidityController.text.isEmpty ||
        phController.text.isEmpty ||
        rainfallController.text.isEmpty) {
      setState(() {
        errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      isLoading = true;
      recommendation = "";
      confidence = "";
      topPredictions = [];
      errorMessage = "";
    });

    try {
      // Validate API configuration
      if (!AppConfig.isCropApiUrlValid) {
        setState(() {
          errorMessage =
              "Crop API URL not configured. Please check environment variables.";
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.cropApiBaseUrl}/recommend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'N': double.parse(nitrogenController.text),
          'P': double.parse(phosphorusController.text),
          'K': double.parse(potassiumController.text),
          'temperature': double.parse(temperatureController.text),
          'humidity': double.parse(humidityController.text),
          'ph': double.parse(phController.text),
          'rainfall': double.parse(rainfallController.text),
          'model_type': selectedModel,
        }),
      );

      if (response.statusCode == 200) {
        final recommendationData = jsonDecode(response.body);
        setState(() {
          recommendation = recommendationData['recommended_crop'];
          confidence =
              (recommendationData['confidence'] * 100).toStringAsFixed(1);
          topPredictions = List<Map<String, dynamic>>.from(
              recommendationData['top_3_predictions']);
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = "Error: ${errorData['error']}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildLocationCard(),
                const SizedBox(height: 24),
                _buildModelSelection(),
                const SizedBox(height: 24),
                _buildInputForm(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                if (errorMessage.isNotEmpty) _buildErrorCard(),
                if (recommendation.isNotEmpty) _buildResultsSection(),
                const SizedBox(height: 100), // Space for bottom navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2196F3),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Smart Crop Recommendation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            useLocationData ? Icons.location_on : Icons.location_off,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              useLocationData = !useLocationData;
            });
            if (useLocationData) {
              _loadLocationData();
            }
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
            Color(0xFF2196F3),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
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
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Location-Based AI Recommendations',
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
            'Get personalized crop recommendations based on your location and local climate data.',
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

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: useLocationData ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: useLocationData ? Colors.green.shade200 : Colors.grey.shade300,
        ),
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
          Row(
            children: [
              Icon(
                useLocationData ? Icons.location_on : Icons.location_off,
                color: useLocationData ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                useLocationData ? 'Location-Based Data' : 'Manual Input',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: useLocationData ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLocationLoading)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Getting location data...'),
              ],
            )
          else
            Text(
              locationInfo.isNotEmpty
                  ? locationInfo
                  : 'Tap location icon to enable',
              style: const TextStyle(fontSize: 14),
            ),
          if (regionalData != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Region: ${regionalData!.region} | Climate: ${regionalData!.temperature.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
              ? const Color(0xFF2196F3).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
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
                      isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
                  size: 20,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF2196F3) : Colors.grey[400],
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
                    ? const Color(0xFF2196F3)
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
          Row(
            children: [
              const Text(
                'Soil Parameters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const Spacer(),
              if (useLocationData && regionalData != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-filled',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          suffixIcon: useLocationData && regionalData != null
              ? Icon(Icons.location_on, color: Colors.green[600], size: 20)
              : null,
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
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
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
            onPressed: useLocationData ? _loadLocationData : null,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Refresh Location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3)),
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
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: const Color(0xFF2196F3).withOpacity(0.3),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
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
                  'AI Recommendation',
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
          if (regionalData != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Based on ${regionalData!.region} climate data',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
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
            'Top 3 Crop Options',
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
}
