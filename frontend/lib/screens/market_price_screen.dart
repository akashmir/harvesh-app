import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../services/mandi_location_service.dart';
import '../services/location_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'market_price_input_screen.dart';
import 'profit_calculator_screen.dart';
import 'market_analytics_screen.dart';
import 'major_city_mandis_screen.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _currentPrices = [];
  List<Map<String, dynamic>> _availableCrops = [];
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _mandiPrices = [];
  List<Map<String, dynamic>> _nearestMandis = [];
  bool _isLoading = true;
  bool _isLocationLoading = false;
  String? _errorMessage;
  String? _locationError;
  String? _currentLocation;
  bool _showingFallbackMandis = false;

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

    _loadData();
    _loadLocationBasedPrices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Try to load available crops with short timeout
      try {
        final cropsResponse = await NetworkService.get(
          '${AppConfig.marketPriceApiBaseUrl}/crops',
          timeout: const Duration(seconds: 5),
        );

        if (cropsResponse['success']) {
          setState(() {
            final cropsData =
                cropsResponse['data']['crops'] as Map<String, dynamic>;
            _availableCrops = cropsData.entries
                .map((e) => {
                      'name': e.key,
                      ...Map<String, dynamic>.from(e.value as Map),
                    })
                .toList();
          });
        }
      } catch (e) {
        // Use fallback crops data
        setState(() {
          _availableCrops = _getFallbackCrops();
        });
      }

      // Try to load current prices for top crops
      await _loadCurrentPrices();

      // Try to load analytics with short timeout
      try {
        final analyticsResponse = await NetworkService.get(
          '${AppConfig.marketPriceApiBaseUrl}/analytics',
          timeout: const Duration(seconds: 5),
        );

        if (analyticsResponse['success']) {
          setState(() {
            _analytics =
                Map<String, dynamic>.from(analyticsResponse['data'] as Map);
          });
        }
      } catch (e) {
        // Use fallback analytics data
        setState(() {
          _analytics = _getFallbackAnalytics();
        });
      }

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      // Even if everything fails, provide fallback data
      setState(() {
        _availableCrops = _getFallbackCrops();
        _analytics = _getFallbackAnalytics();
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _loadCurrentPrices() async {
    final topCrops = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Tomato'];
    List<Map<String, dynamic>> prices = [];

    for (String crop in topCrops) {
      try {
        final response = await NetworkService.get(
          '${AppConfig.marketPriceApiBaseUrl}/price/current?crop=$crop',
          timeout: const Duration(seconds: 3),
        );

        if (response['success']) {
          prices.add(Map<String, dynamic>.from(response['data'] as Map));
        }
      } catch (e) {
        // Continue with other crops if one fails
      }
    }

    // If no prices loaded from API, use fallback data
    if (prices.isEmpty) {
      prices = _getFallbackCurrentPrices();
    }

    setState(() {
      _currentPrices = prices;
    });
  }

  /// Get fallback current prices data when API is unavailable
  List<Map<String, dynamic>> _getFallbackCurrentPrices() {
    return [
      {
        'crop_name': 'Rice',
        'current_price': 28.50,
        'unit': 'kg',
        'state': 'All India',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
      },
      {
        'crop_name': 'Wheat',
        'current_price': 22.75,
        'unit': 'kg',
        'state': 'All India',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Medium',
      },
      {
        'crop_name': 'Maize',
        'current_price': 19.25,
        'unit': 'kg',
        'state': 'All India',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'Low',
      },
      {
        'crop_name': 'Cotton',
        'current_price': 65.00,
        'unit': 'kg',
        'state': 'All India',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
      },
      {
        'crop_name': 'Tomato',
        'current_price': 35.50,
        'unit': 'kg',
        'state': 'All India',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'market_demand': 'High',
      },
    ];
  }

  Future<void> _loadLocationBasedPrices() async {
    try {
      setState(() {
        _isLocationLoading = true;
        _locationError = null;
      });

      // Get user's current location
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _locationError =
              'Unable to get current location. Please check location permissions.';
          _isLocationLoading = false;
        });
        return;
      }

      // Get location name
      final locationName = await LocationService.getReadableLocationLabel(
          position.latitude, position.longitude);

      setState(() {
        _currentLocation = locationName;
      });

      // Get nearest mandis
      final mandisResponse =
          await MandiLocationService.getNearestMandisToPosition(
              position.latitude, position.longitude);

      if (mandisResponse['success']) {
        final mandis = List<Map<String, dynamic>>.from(mandisResponse['data']);

        // Check if we have real mandis or fallback data
        if (mandisResponse['fallback'] == true || mandis.isEmpty) {
          // No mandis found nearby, show empty state
          setState(() {
            _nearestMandis = [];
            _showingFallbackMandis = false;
          });
        } else {
          setState(() {
            _nearestMandis = mandis;
            _showingFallbackMandis = false;
          });
        }
      } else {
        // API failed, show empty state
        setState(() {
          _nearestMandis = [];
          _showingFallbackMandis = false;
        });
      }

      // Get location-based prices
      final pricesResponse =
          await MandiLocationService.getLocationBasedMarketPrices();

      if (pricesResponse['success']) {
        setState(() {
          _mandiPrices =
              List<Map<String, dynamic>>.from(pricesResponse['data']);
        });

        // Show message if using fallback data
        if (pricesResponse['fallback'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pricesResponse['message'] ?? 'Using sample data'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _locationError =
              pricesResponse['error'] ?? 'Failed to load location-based prices';
        });
      }

      setState(() {
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error loading location-based prices: ${e.toString()}';
        _isLocationLoading = false;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToProfitCalculator(),
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.calculate, color: Colors.white),
        label: const Text(
          'Calculate Profit',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading market price data...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildLocationBasedPrices(),
              const SizedBox(height: 24),
              _buildCurrentPrices(),
              const SizedBox(height: 24),
              _buildTopCrops(),
              const SizedBox(height: 24),
              _buildAnalyticsOverview(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Check Prices',
            'View current market prices',
            Icons.price_check,
            const Color(0xFF2196F3),
            () => _navigateToPriceInput(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            'Calculate Profit',
            'Estimate crop profitability',
            Icons.calculate,
            const Color(0xFF4CAF50),
            () => _navigateToProfitCalculator(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBasedPrices() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '📍 Location-Based Prices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF1976D2)),
                  onPressed: _loadLocationBasedPrices,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_currentLocation != null)
              Text(
                '📍 $_currentLocation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 12),
            if (_isLocationLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_locationError != null)
              _buildLocationError()
            else if (_nearestMandis.isEmpty && _mandiPrices.isEmpty)
              _buildEmptyLocationPrices()
            else
              _buildMandiPricesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 32),
          const SizedBox(height: 8),
          Text(
            'Location Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _locationError!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadLocationBasedPrices,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationPrices() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off, color: Colors.blue[600], size: 32),
          const SizedBox(height: 8),
          Text(
            'No Mandis Found Nearby',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No mandis found near your location. You can view major city mandis or try again.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _loadLocationBasedPrices,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showMajorCityMandis,
                icon: const Icon(Icons.location_city, size: 16),
                label: const Text('View Major Cities'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMandiPricesList() {
    return Column(
      children: [
        if (_nearestMandis.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                _showingFallbackMandis
                    ? Icons.location_city
                    : Icons.location_on,
                size: 16,
                color: _showingFallbackMandis
                    ? Colors.orange[600]
                    : const Color(0xFF1976D2),
              ),
              const SizedBox(width: 4),
              Text(
                _showingFallbackMandis
                    ? 'Top Mandis from Major Cities (${_nearestMandis.length})'
                    : 'Nearest Mandis (${_nearestMandis.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _showingFallbackMandis
                      ? Colors.orange[600]
                      : const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          if (_showingFallbackMandis) ...[
            const SizedBox(height: 4),
            Text(
              'No mandis found nearby. Showing major city mandis instead.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ..._nearestMandis.take(3).map((mandi) => _buildMandiItem(mandi)),
          const SizedBox(height: 16),
        ],
        Text(
          _showingFallbackMandis
              ? 'Crop Prices from Major City Mandis'
              : 'Crop Prices from Nearby Mandis',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 8),
        ..._mandiPrices.take(5).map((price) => _buildMandiPriceItem(price)),
        if (_mandiPrices.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${_mandiPrices.length - 5} more crops available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMandiItem(Map<String, dynamic> mandi) {
    final isMajorCity = mandi['is_major_city'] == true;
    final iconColor = isMajorCity ? Colors.orange[600] : Colors.green[600];
    final containerColor = isMajorCity ? Colors.orange[50] : Colors.green[50];
    final borderColor = isMajorCity ? Colors.orange[200] : Colors.green[200];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor!),
      ),
      child: Row(
        children: [
          Icon(isMajorCity ? Icons.location_city : Icons.store,
              color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mandi['mandi_name'] ?? 'Unknown Mandi',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    if (isMajorCity) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[600],
                          borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
                Text(
                  '${mandi['district'] ?? ''}, ${mandi['state'] ?? ''}${isMajorCity ? ' • Major City' : ' • ${mandi['distance_km']?.toStringAsFixed(1) ?? '0'} km'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${mandi['crops_available']?.length ?? 0} crops',
            style: TextStyle(
              fontSize: 12,
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandiPriceItem(Map<String, dynamic> price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.eco,
              color: Color(0xFF2196F3),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price['crop_name'] ?? 'Unknown Crop',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                Text(
                  '${price['mandi_name'] ?? 'Unknown Mandi'} • ${price['date'] ?? 'Today'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                price['market_demand'] ?? 'Medium',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrices() {
    if (_currentPrices.isEmpty) {
      return _buildEmptyPrices();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Market Prices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToPriceInput(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currentPrices.map((price) => _buildPriceItem(price)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrices() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.price_check,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Price Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check current market prices',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(Map<String, dynamic> price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.eco,
              color: Color(0xFF2196F3),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price['crop_name'] ?? 'Unknown Crop',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                Text(
                  '${price['state'] ?? 'All India'} • ${price['date'] ?? 'Today'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price['current_price']?.toStringAsFixed(0) ?? '0'}/kg',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                price['market_demand'] ?? 'Medium',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCrops() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Crops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCrops.take(12).map((crop) {
                return Chip(
                  label: Text(
                    crop['name'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                  labelStyle: const TextStyle(color: Color(0xFF2196F3)),
                );
              }).toList(),
            ),
            if (_availableCrops.length > 12) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${_availableCrops.length - 12} more crops available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    if (_analytics.isEmpty) {
      return const SizedBox.shrink();
    }

    final insights = _analytics['insights'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Market Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAnalytics(),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights['most_profitable_crop'] != null) ...[
              _buildInsightItem(
                'Most Profitable',
                insights['most_profitable_crop'],
                Icons.trending_up,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 8),
            ],
            if (insights['highest_price_crop'] != null) ...[
              _buildInsightItem(
                'Highest Price',
                insights['highest_price_crop'],
                Icons.attach_money,
                const Color(0xFFFF9800),
              ),
              const SizedBox(height: 8),
            ],
            _buildInsightItem(
              'Total Calculations',
              '${insights['total_calculations'] ?? 0}',
              Icons.calculate,
              const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
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
                  color: Color(0xFF1976D2),
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

  void _navigateToPriceInput() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MarketPriceInputScreen(),
      ),
    );
  }

  void _navigateToProfitCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfitCalculatorScreen(),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MarketAnalyticsScreen(),
      ),
    );
  }

  void _showMajorCityMandis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MajorCityMandisScreen(),
      ),
    );
  }

  /// Get fallback crops data when API is unavailable
  List<Map<String, dynamic>> _getFallbackCrops() {
    return [
      {'name': 'Rice', 'category': 'Cereal', 'season': 'Kharif'},
      {'name': 'Wheat', 'category': 'Cereal', 'season': 'Rabi'},
      {'name': 'Maize', 'category': 'Cereal', 'season': 'Kharif'},
      {'name': 'Cotton', 'category': 'Fiber', 'season': 'Kharif'},
      {'name': 'Tomato', 'category': 'Vegetable', 'season': 'All'},
      {'name': 'Onion', 'category': 'Vegetable', 'season': 'Rabi'},
      {'name': 'Soybean', 'category': 'Oilseed', 'season': 'Kharif'},
      {'name': 'Mustard', 'category': 'Oilseed', 'season': 'Rabi'},
      {'name': 'Sugarcane', 'category': 'Cash Crop', 'season': 'All'},
      {'name': 'Potato', 'category': 'Vegetable', 'season': 'Rabi'},
      {'name': 'Chickpea', 'category': 'Pulse', 'season': 'Rabi'},
      {'name': 'Groundnut', 'category': 'Oilseed', 'season': 'Kharif'},
    ];
  }

  /// Get fallback analytics data when API is unavailable
  Map<String, dynamic> _getFallbackAnalytics() {
    return {
      'insights': {
        'total_calculations': 150,
        'most_profitable_crop': 'Tomato',
        'highest_price_crop': 'Cotton',
        'average_price_trend': 'Stable',
        'market_volatility': 'Low',
      },
      'trends': {
        'price_increase': 5.2,
        'price_decrease': 2.1,
        'stable_prices': 92.7,
      },
      'recommendations': [
        'Consider growing high-value crops like Tomato and Cotton',
        'Monitor market trends for optimal selling time',
        'Diversify crop portfolio to reduce risk',
      ],
    };
  }
}
