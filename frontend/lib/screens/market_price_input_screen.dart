import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class MarketPriceInputScreen extends StatefulWidget {
  const MarketPriceInputScreen({super.key});

  @override
  State<MarketPriceInputScreen> createState() => _MarketPriceInputScreenState();
}

class _MarketPriceInputScreenState extends State<MarketPriceInputScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCrop = 'Rice';
  String _selectedState = 'All India';
  int _daysAhead = 30;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableCrops = [];
  Map<String, dynamic>? _currentPrice;
  Map<String, dynamic>? _pricePrediction;

  final List<String> _states = [
    'All India',
    'Punjab',
    'Haryana',
    'Uttar Pradesh',
    'Maharashtra',
    'Karnataka',
    'Tamil Nadu',
    'West Bengal',
    'Gujarat',
    'Rajasthan',
    'Madhya Pradesh',
    'Andhra Pradesh',
    'Telangana',
    'Bihar',
    'Odisha',
    'Assam',
    'Kerala',
    'Jharkhand',
    'Chhattisgarh',
    'Himachal Pradesh',
    'Uttarakhand',
    'Jammu and Kashmir',
    'Goa',
    'Sikkim',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Tripura',
    'Arunachal Pradesh'
  ];

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

    _loadCrops();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/crops',
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
          {'name': 'Rice', 'baseline_price': 25.0},
          {'name': 'Wheat', 'baseline_price': 22.0},
          {'name': 'Maize', 'baseline_price': 18.0},
          {'name': 'Cotton', 'baseline_price': 65.0},
          {'name': 'Tomato', 'baseline_price': 35.0},
        ];
      });
    }
  }

  Future<void> _getCurrentPrice() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPrice = null;
      });

      final response = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/price/current?crop=$_selectedCrop&state=$_selectedState',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _currentPrice = Map<String, dynamic>.from(response['data'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to get current price';
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

  Future<void> _predictPrice() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _pricePrediction = null;
      });

      final predictionData = {
        'crop_name': _selectedCrop,
        'days_ahead': _daysAhead,
      };

      final response = await NetworkService.post(
        '${AppConfig.marketPriceApiBaseUrl}/price/predict',
        body: predictionData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _pricePrediction = Map<String, dynamic>.from(response['data'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to predict price';
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
          'Market Prices',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Crop & Location'),
              _buildSelectionCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Current Price'),
              _buildCurrentPriceCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Price Prediction'),
              _buildPredictionCard(),
              const SizedBox(height: 32),
            ],
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
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
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
                prefixIcon: Icon(Icons.eco, color: Color(0xFF2196F3)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
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
                        '₹${crop['baseline_price']?.toStringAsFixed(0) ?? '0'}/kg avg',
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
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'Select State',
                prefixIcon: Icon(Icons.location_on, color: Color(0xFF2196F3)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
                ),
              ),
              items: _states.map((state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPriceCard() {
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
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentPrice,
                    icon: const Icon(Icons.price_check, size: 16),
                    label: const Text('Get Current Price'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LoadingWidget(message: 'Fetching current price...'),
            ],
            if (_currentPrice != null) ...[
              const SizedBox(height: 16),
              _buildPriceResult(_currentPrice!, 'Current Price'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
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
                  child: DropdownButtonFormField<int>(
                    value: _daysAhead,
                    decoration: const InputDecoration(
                      labelText: 'Predict for',
                      prefixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2196F3)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Next 7 days')),
                      DropdownMenuItem(value: 15, child: Text('Next 15 days')),
                      DropdownMenuItem(value: 30, child: Text('Next 30 days')),
                      DropdownMenuItem(value: 60, child: Text('Next 60 days')),
                      DropdownMenuItem(value: 90, child: Text('Next 90 days')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _daysAhead = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _predictPrice,
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: const Text('Predict'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LoadingWidget(message: 'Predicting price...'),
            ],
            if (_pricePrediction != null) ...[
              const SizedBox(height: 16),
              _buildPriceResult(_pricePrediction!, 'Price Prediction'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Price predictions are based on historical trends, seasonal patterns, and market demand. Actual prices may vary.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
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

  Widget _buildPriceResult(Map<String, dynamic> priceData, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: title == 'Current Price' ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              title == 'Current Price' ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                title == 'Current Price'
                    ? Icons.price_check
                    : Icons.trending_up,
                color: title == 'Current Price'
                    ? Colors.blue[700]
                    : Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: title == 'Current Price'
                      ? Colors.blue[700]
                      : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${priceData['current_price'] ?? priceData['predicted_price']}/kg',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: title == 'Current Price'
                  ? Colors.blue[700]
                  : Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPriceInfo('Crop', priceData['crop_name'] ?? 'Unknown'),
              _buildPriceInfo('Location', priceData['state'] ?? 'All India'),
              if (priceData['confidence_score'] != null)
                _buildPriceInfo('Confidence',
                    '${(priceData['confidence_score'] * 100).toStringAsFixed(0)}%'),
            ],
          ),
          if (priceData['date'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Date: ${priceData['date']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (priceData['target_date'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${priceData['target_date']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value) {
    return Column(
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
    );
  }
}
