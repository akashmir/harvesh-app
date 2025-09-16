import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../config/app_config.dart';

class FarmerFriendlyCropScreen extends StatefulWidget {
  const FarmerFriendlyCropScreen({super.key});

  @override
  State<FarmerFriendlyCropScreen> createState() =>
      _FarmerFriendlyCropScreenState();
}

class _FarmerFriendlyCropScreenState extends State<FarmerFriendlyCropScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();

  String _selectedSoilType = 'Loamy';
  String _selectedSeason = 'Kharif';
  String _selectedWaterSupply = 'Medium';
  String _selectedRegion = 'North India';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _recommendations = [];

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _areaController.text = '1.0';
  }

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _recommendations = [];
      });

      // Convert farmer-friendly inputs to technical parameters
      final technicalData = _convertToTechnicalData();

      final response = await NetworkService.post(
        AppConfig.cropRecommendationEndpoint,
        body: technicalData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _recommendations = List<Map<String, dynamic>>.from(
              response['data']['recommendations'] ?? []);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop recommendations ready!'),
            backgroundColor: Color(0xFF8BC34A),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to get recommendations';
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

  Map<String, dynamic> _convertToTechnicalData() {
    // Convert farmer-friendly inputs to technical parameters
    Map<String, double> soilParams = _getSoilParameters(_selectedSoilType);
    Map<String, double> weatherParams =
        _getWeatherParameters(_selectedRegion, _selectedSeason);

    return {
      'N': soilParams['N']!,
      'P': soilParams['P']!,
      'K': soilParams['K']!,
      'temperature': weatherParams['temperature']!,
      'humidity': weatherParams['humidity']!,
      'ph': soilParams['ph']!,
      'rainfall': weatherParams['rainfall']!,
      'model_type': 'rf',
    };
  }

  Map<String, double> _getSoilParameters(String soilType) {
    switch (soilType) {
      case 'Loamy':
        return {'N': 80.0, 'P': 50.0, 'K': 60.0, 'ph': 6.5};
      case 'Clay':
        return {'N': 70.0, 'P': 45.0, 'K': 55.0, 'ph': 7.0};
      case 'Sandy':
        return {'N': 60.0, 'P': 40.0, 'K': 50.0, 'ph': 6.0};
      case 'Silty':
        return {'N': 75.0, 'P': 48.0, 'K': 58.0, 'ph': 6.8};
      default:
        return {'N': 80.0, 'P': 50.0, 'K': 60.0, 'ph': 6.5};
    }
  }

  Map<String, double> _getWeatherParameters(String region, String season) {
    Map<String, Map<String, double>> baseWeather = {
      'North India': {'temperature': 25.0, 'humidity': 60.0, 'rainfall': 800.0},
      'South India': {
        'temperature': 28.0,
        'humidity': 70.0,
        'rainfall': 1200.0
      },
      'East India': {'temperature': 26.0, 'humidity': 75.0, 'rainfall': 1500.0},
      'West India': {'temperature': 30.0, 'humidity': 55.0, 'rainfall': 600.0},
    };

    Map<String, Map<String, double>> seasonMultipliers = {
      'Kharif': {'temperature': 1.1, 'humidity': 1.2, 'rainfall': 1.5},
      'Rabi': {'temperature': 0.8, 'humidity': 0.7, 'rainfall': 0.3},
      'Zaid': {'temperature': 1.3, 'humidity': 0.6, 'rainfall': 0.2},
    };

    var base = baseWeather[region]!;
    var multiplier = seasonMultipliers[season]!;

    return {
      'temperature': base['temperature']! * multiplier['temperature']!,
      'humidity': base['humidity']! * multiplier['humidity']!,
      'rainfall': base['rainfall']! * multiplier['rainfall']!,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🌾 Smart Crop Recommender',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8BC34A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _getRecommendations,
            child: const Text(
              'Get Crops',
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
                _buildWelcomeCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('🏞️ Your Field Details'),
                _buildFieldDetailsCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('🌱 Growing Conditions'),
                _buildGrowingConditionsCard(),
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
                _buildRecommendButton(),
                if (_recommendations.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRecommendationsResult(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.agriculture,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Find the Best Crops for Your Field!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Just tell us about your field and we\'ll recommend the perfect crops for you!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

  Widget _buildFieldDetailsCard() {
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
                    value: _selectedSoilType,
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
                        _selectedSoilType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedWaterSupply,
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
                          value: 'High', child: Text('Good Water')),
                      DropdownMenuItem(
                          value: 'Medium', child: Text('Moderate Water')),
                      DropdownMenuItem(
                          value: 'Low', child: Text('Limited Water')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedWaterSupply = value!;
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

  Widget _buildGrowingConditionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeason,
                    decoration: const InputDecoration(
                      labelText: 'Growing Season',
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Your Region',
                      prefixIcon:
                          Icon(Icons.location_on, color: Color(0xFF8BC34A)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF8BC34A)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'North India', child: Text('North India')),
                      DropdownMenuItem(
                          value: 'South India', child: Text('South India')),
                      DropdownMenuItem(
                          value: 'East India', child: Text('East India')),
                      DropdownMenuItem(
                          value: 'West India', child: Text('West India')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We\'ll automatically consider weather conditions for your region and season!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildRecommendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getRecommendations,
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
                '🌾 Get My Crop Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildRecommendationsResult() {
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
                    Icons.eco,
                    color: Color(0xFF8BC34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recommended Crops for You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._recommendations.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> crop = entry.value;
              return _buildCropCard(crop, index + 1);
            }).toList(),
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
                      'These recommendations are based on your field conditions and local weather. Choose the crop that best fits your farming goals!',
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

  Widget _buildCropCard(Map<String, dynamic> crop, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rank == 1
            ? const Color(0xFF8BC34A).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank == 1 ? const Color(0xFF8BC34A) : Colors.grey[300]!,
          width: rank == 1 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank == 1 ? const Color(0xFF8BC34A) : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop['crop'] ?? 'Unknown Crop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: rank == 1 ? const Color(0xFF2E7D32) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${((crop['confidence'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (rank == 1)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BC34A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST CHOICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
