import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';

class YieldPredictionInputScreen extends StatefulWidget {
  const YieldPredictionInputScreen({super.key});

  @override
  State<YieldPredictionInputScreen> createState() =>
      _YieldPredictionInputScreenState();
}

class _YieldPredictionInputScreenState extends State<YieldPredictionInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _irrigationController = TextEditingController();
  final _seasonController = TextEditingController();

  String _selectedCrop = 'Rice';
  String _selectedSeason = 'Kharif';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableCrops = [];
  Map<String, dynamic>? _predictionResult;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _initializeForm();
    _loadCrops();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _areaController.dispose();
    _soilTypeController.dispose();
    _irrigationController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _areaController.text = '1.0';
    _soilTypeController.text = 'Loamy';
    _irrigationController.text = 'Medium';
  }

  Future<void> _loadCrops() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.yieldPredictionApiBaseUrl}/crops',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          final cropsData = response['data']['crops'] as Map<String, dynamic>;
          _availableCrops = cropsData.entries
              .map((e) => {
                    'name': e.key,
                    ...Map<String, dynamic>.from(e.value as Map),
                  })
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently, use default crops
      setState(() {
        _availableCrops = [
          {'name': 'Rice', 'min': 2000, 'max': 6000, 'avg': 4000},
          {'name': 'Wheat', 'min': 1500, 'max': 5000, 'avg': 3000},
          {'name': 'Maize', 'min': 2000, 'max': 8000, 'avg': 5000},
          {'name': 'Cotton', 'min': 800, 'max': 2000, 'avg': 1400},
          {'name': 'Sugarcane', 'min': 50000, 'max': 100000, 'avg': 75000},
        ];
      });
    }
  }

  Future<void> _predictYield() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _predictionResult = null;
      });

      final predictionData = {
        'crop_name': _selectedCrop,
        'area_hectares': double.parse(_areaController.text),
        'soil_type': _soilTypeController.text,
        'irrigation_level': _irrigationController.text,
        'season': _selectedSeason,
      };

      final response = await NetworkService.post(
        '${AppConfig.yieldPredictionApiBaseUrl}/predict',
        body: predictionData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _predictionResult =
              Map<String, dynamic>.from(response['data'] as Map);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yield prediction completed successfully!'),
            backgroundColor: Color(0xFF8BC34A),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to predict yield';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Predict Yield',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8BC34A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _predictYield,
            child: const Text(
              'Predict',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('🌾 Choose Your Crop'),
                _buildCropSelectionCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('🏞️ Your Field Details'),
                _buildFieldConditionsCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('🌱 Growing Conditions'),
                _buildEnvironmentalCard(),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildPredictButton(),
                if (_predictionResult != null) ...[
                  const SizedBox(height: 24),
                  _buildPredictionResult(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8BC34A),
        ),
      ),
    );
  }

  Widget _buildCropSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              decoration: const InputDecoration(
                labelText: 'Select Crop *',
                prefixIcon: Icon(Icons.eco, color: Color(0xFF8BC34A)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8BC34A)),
                ),
              ),
              items: _availableCrops.map((crop) {
                return DropdownMenuItem<String>(
                  value: crop['name'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop['name']),
                      Text(
                        'Avg: ${crop['avg']} kg/ha',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCrop = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeason,
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      prefixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF8BC34A)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8BC34A)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Kharif', child: Text('Kharif (Monsoon)')),
                      DropdownMenuItem(
                          value: 'Rabi', child: Text('Rabi (Winter)')),
                      DropdownMenuItem(
                          value: 'Zaid', child: Text('Zaid (Summer)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSeason = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldConditionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Field Size (Acres) *',
                hintText: 'Enter your field size',
                prefixIcon: Icon(Icons.straighten, color: Color(0xFF8BC34A)),
                suffixText: 'acres',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8BC34A)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Field size is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Size must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _soilTypeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Soil Type',
                      prefixIcon: Icon(Icons.terrain, color: Color(0xFF8BC34A)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8BC34A)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Loamy', child: Text('Loamy (Best)')),
                      DropdownMenuItem(value: 'Clay', child: Text('Clay')),
                      DropdownMenuItem(value: 'Sandy', child: Text('Sandy')),
                      DropdownMenuItem(value: 'Silty', child: Text('Silty')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _soilTypeController.text = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _irrigationController.text,
                    decoration: const InputDecoration(
                      labelText: 'Water Supply',
                      prefixIcon:
                          Icon(Icons.water_drop, color: Color(0xFF8BC34A)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8BC34A)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'High', child: Text('Good Water Supply')),
                      DropdownMenuItem(
                          value: 'Medium', child: Text('Moderate Water')),
                      DropdownMenuItem(
                          value: 'Low', child: Text('Limited Water')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _irrigationController.text = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We will automatically detect weather conditions for your location to give you the best predictions!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Prediction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our AI will use your location and current weather to predict the best yield for your crop!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _predictYield,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8BC34A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '🌾 Get My Yield Prediction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildPredictionResult() {
    if (_predictionResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BC34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF8BC34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Crop Yield Prediction',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8BC34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF8BC34A).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${_predictionResult!['predicted_yield']?.toStringAsFixed(0) ?? '0'} kg',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8BC34A),
                    ),
                  ),
                  Text(
                    'Expected Total Harvest',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_predictionResult!['yield_per_hectare']?.toStringAsFixed(0) ?? '0'} kg/ha',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    'Per Acre Production',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Accuracy',
                    '${(_predictionResult!['confidence_score'] * 100)?.toStringAsFixed(0) ?? '0'}%',
                    Icons.trending_up,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultItem(
                    'Crop',
                    _predictionResult!['crop_name'] ?? 'Unknown',
                    Icons.eco,
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Field Size',
                    '${_predictionResult!['area_hectares']?.toStringAsFixed(1) ?? '0.0'} acres',
                    Icons.straighten,
                    const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultItem(
                    'Season',
                    _predictionResult!['season'] ?? 'Unknown',
                    Icons.calendar_today,
                    const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This prediction is based on your field details and weather conditions. Results may vary based on actual farming practices.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
