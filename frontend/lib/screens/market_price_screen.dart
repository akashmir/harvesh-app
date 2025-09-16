import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'market_price_input_screen.dart';
import 'profit_calculator_screen.dart';
import 'market_analytics_screen.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

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

      // Load available crops
      final cropsResponse = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/crops',
        timeout: const Duration(seconds: 30),
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

      // Load current prices for top crops
      await _loadCurrentPrices();

      // Load analytics
      final analyticsResponse = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/analytics',
        timeout: const Duration(seconds: 30),
      );

      if (analyticsResponse['success']) {
        setState(() {
          _analytics =
              Map<String, dynamic>.from(analyticsResponse['data'] as Map);
        });
      }

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentPrices() async {
    final topCrops = ['Rice', 'Wheat', 'Maize', 'Cotton', 'Tomato'];
    List<Map<String, dynamic>> prices = [];

    for (String crop in topCrops) {
      try {
        final response = await NetworkService.get(
          '${AppConfig.marketPriceApiBaseUrl}/price/current?crop=$crop',
          timeout: const Duration(seconds: 10),
        );

        if (response['success']) {
          prices.add(Map<String, dynamic>.from(response['data'] as Map));
        }
      } catch (e) {
        // Continue with other crops if one fails
      }
    }

    setState(() {
      _currentPrices = prices;
    });
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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildQuickActions(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
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
                  Icons.trending_up,
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
                      'Market Price Intelligence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time prices, predictions & profit analysis',
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
                Icons.eco,
                '${_availableCrops.length}',
                'Crops',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.attach_money,
                '₹${_currentPrices.isNotEmpty ? _currentPrices.first['current_price']?.toStringAsFixed(0) ?? '0' : '0'}',
                'Avg Price',
              ),
              const SizedBox(width: 24),
              _buildHeaderStat(
                Icons.analytics,
                _analytics['insights']?['total_calculations']?.toString() ??
                    '0',
                'Calculations',
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
}
