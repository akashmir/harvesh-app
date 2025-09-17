import 'package:flutter/material.dart';

class MajorCityMandisScreen extends StatefulWidget {
  const MajorCityMandisScreen({super.key});

  @override
  State<MajorCityMandisScreen> createState() => _MajorCityMandisScreenState();
}

class _MajorCityMandisScreenState extends State<MajorCityMandisScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _majorCityMandis = [];
  List<Map<String, dynamic>> _majorCityPrices = [];

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

    _loadMajorCityData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadMajorCityData() {
    setState(() {
      _majorCityMandis = _getTopMandis();
      _majorCityPrices = _getMajorCityPrices();
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Major City Mandis',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFF9800),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMandisList(),
                const SizedBox(height: 24),
                _buildPricesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFF9800),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Major City Mandis',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Market prices from major cities across India',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderStat(
                Icons.store,
                '${_majorCityMandis.length}',
                'Mandis',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.eco,
                '${_majorCityPrices.length}',
                'Crops',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.location_city,
                '5',
                'Cities',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandisList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Major City Mandis (${_majorCityMandis.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Agricultural markets from major cities across India',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ..._majorCityMandis.map((mandi) => _buildMandiItem(mandi)),
          ],
        ),
      ),
    );
  }

  Widget _buildMandiItem(Map<String, dynamic> mandi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_city,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mandi['mandi_name'] ?? 'Unknown Mandi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'MAJOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${mandi['district'] ?? ''}, ${mandi['state'] ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (mandi['crops_available'] as List<dynamic>?)
                          ?.take(4)
                          .map((crop) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  crop.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList() ??
                      [],
                ),
                if ((mandi['crops_available'] as List<dynamic>?)?.length !=
                        null &&
                    (mandi['crops_available'] as List<dynamic>?)!.length > 4)
                  Text(
                    '+ ${(mandi['crops_available'] as List<dynamic>?)!.length - 4} more crops',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mandi['crops_available']?.length ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[600],
                ),
              ),
              Text(
                'crops',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.price_check, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sample Prices from Major Cities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Current market prices from major city mandis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ..._majorCityPrices.map((price) => _buildPriceItem(price)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(Map<String, dynamic> price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.eco,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price['crop_name'] ?? 'Unknown Crop',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${price['mandi_name'] ?? 'Unknown Mandi'} • ${price['date'] ?? 'Today'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      size: 14,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${price['mandi_state'] ?? ''}, ${price['mandi_district'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price['current_price'] ?? '0'}/${price['unit'] ?? 'kg'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getDemandColor(price['market_demand']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  price['market_demand'] ?? 'Medium',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDemandColor(String? demand) {
    switch (demand?.toLowerCase()) {
      case 'high':
        return Colors.green[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Get top mandis from major cities
  List<Map<String, dynamic>> _getTopMandis() {
    return [
      {
        'mandi_name': 'Delhi Mandi',
        'state': 'Delhi',
        'district': 'New Delhi',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'crops_available': [
          'Rice',
          'Wheat',
          'Maize',
          'Cotton',
          'Tomato',
          'Onion',
          'Soybean',
          'Mustard'
        ],
        'is_major_city': true,
      },
      {
        'mandi_name': 'Mumbai Mandi',
        'state': 'Maharashtra',
        'district': 'Mumbai',
        'latitude': 19.0760,
        'longitude': 72.8777,
        'crops_available': [
          'Rice',
          'Wheat',
          'Cotton',
          'Tomato',
          'Onion',
          'Sugarcane',
          'Groundnut'
        ],
        'is_major_city': true,
      },
      {
        'mandi_name': 'Bangalore Mandi',
        'state': 'Karnataka',
        'district': 'Bangalore',
        'latitude': 12.9716,
        'longitude': 77.5946,
        'crops_available': [
          'Rice',
          'Maize',
          'Tomato',
          'Onion',
          'Chickpea',
          'Groundnut',
          'Sugarcane'
        ],
        'is_major_city': true,
      },
      {
        'mandi_name': 'Kolkata Mandi',
        'state': 'West Bengal',
        'district': 'Kolkata',
        'latitude': 22.5726,
        'longitude': 88.3639,
        'crops_available': [
          'Rice',
          'Wheat',
          'Maize',
          'Potato',
          'Tomato',
          'Mustard',
          'Jute'
        ],
        'is_major_city': true,
      },
      {
        'mandi_name': 'Chennai Mandi',
        'state': 'Tamil Nadu',
        'district': 'Chennai',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'crops_available': [
          'Rice',
          'Cotton',
          'Sugarcane',
          'Groundnut',
          'Chickpea',
          'Tomato'
        ],
        'is_major_city': true,
      },
    ];
  }

  /// Get sample prices for major city mandis
  List<Map<String, dynamic>> _getMajorCityPrices() {
    return [
      {
        'crop_name': 'Rice',
        'current_price': '28.50',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
        'mandi_name': 'Delhi Mandi',
        'mandi_state': 'Delhi',
        'mandi_district': 'New Delhi',
      },
      {
        'crop_name': 'Wheat',
        'current_price': '22.75',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Medium',
        'mandi_name': 'Mumbai Mandi',
        'mandi_state': 'Maharashtra',
        'mandi_district': 'Mumbai',
      },
      {
        'crop_name': 'Cotton',
        'current_price': '65.00',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
        'mandi_name': 'Bangalore Mandi',
        'mandi_state': 'Karnataka',
        'mandi_district': 'Bangalore',
      },
      {
        'crop_name': 'Tomato',
        'current_price': '35.50',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
        'mandi_name': 'Kolkata Mandi',
        'mandi_state': 'West Bengal',
        'mandi_district': 'Kolkata',
      },
      {
        'crop_name': 'Onion',
        'current_price': '30.25',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Medium',
        'mandi_name': 'Chennai Mandi',
        'mandi_state': 'Tamil Nadu',
        'mandi_district': 'Chennai',
      },
      {
        'crop_name': 'Maize',
        'current_price': '19.80',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Low',
        'mandi_name': 'Delhi Mandi',
        'mandi_state': 'Delhi',
        'mandi_district': 'New Delhi',
      },
      {
        'crop_name': 'Sugarcane',
        'current_price': '3.20',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
        'mandi_name': 'Mumbai Mandi',
        'mandi_state': 'Maharashtra',
        'mandi_district': 'Mumbai',
      },
      {
        'crop_name': 'Groundnut',
        'current_price': '45.00',
        'unit': 'kg',
        'price_type': 'wholesale',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Medium',
        'mandi_name': 'Bangalore Mandi',
        'mandi_state': 'Karnataka',
        'mandi_district': 'Bangalore',
      },
    ];
  }
}
