import 'package:flutter/material.dart';
import '../services/sih_2025_simple_service.dart';

/// Additional Features Dashboard
/// Main screen showcasing all advanced farming features
class Sih2025Dashboard extends StatefulWidget {
  const Sih2025Dashboard({Key? key}) : super(key: key);

  @override
  State<Sih2025Dashboard> createState() => _Sih2025DashboardState();
}

class _Sih2025DashboardState extends State<Sih2025Dashboard> {
  final Sih2025SimpleService _sih2025Service = Sih2025SimpleService();

  bool _isLoading = false;
  Map<String, dynamic> _systemHealth = {};
  List<String> _availableFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
  }

  Future<void> _loadSystemStatus() async {
    setState(() => _isLoading = true);

    try {
      // Check system health
      final health = await _sih2025Service.checkSystemHealth();
      final features = await _sih2025Service.getAvailableFeatures();

      setState(() {
        _systemHealth = health;
        _availableFeatures = features;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load system status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Additional Features Dashboard'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemStatusCard(),
                  const SizedBox(height: 16),
                  _buildFeaturesGrid(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemStatusCard() {
    final isHealthy = _systemHealth['status'] == 'healthy';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHealthy ? 'All systems operational' : 'Some systems offline',
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_systemHealth['message'] != null) ...[
              const SizedBox(height: 4),
              Text(_systemHealth['message']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'title': 'Crop Recommendations',
        'icon': Icons.agriculture,
        'color': Colors.blue,
        'description': 'AI-powered crop suggestions',
        'onTap': () => _navigateToCropRecommendation(),
      },
      {
        'title': 'Satellite Soil Data',
        'icon': Icons.satellite,
        'color': Colors.brown,
        'description': 'Real-time soil analysis',
        'onTap': () => _navigateToSoilAnalysis(),
      },
      {
        'title': 'Multilingual AI',
        'icon': Icons.translate,
        'color': Colors.purple,
        'description': 'Voice & chat in local languages',
        'onTap': () => _navigateToMultilingual(),
      },
      {
        'title': 'Disease Detection',
        'icon': Icons.bug_report,
        'color': Colors.red,
        'description': 'AI plant disease detection',
        'onTap': () => _navigateToDiseaseDetection(),
      },
      {
        'title': 'Sustainability',
        'icon': Icons.eco,
        'color': Colors.green,
        'description': 'Environmental impact analysis',
        'onTap': () => _navigateToSustainability(),
      },
      {
        'title': 'Weather Integration',
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'description': 'Real-time weather data',
        'onTap': () => _navigateToWeather(),
      },
      {
        'title': 'Market Prices',
        'icon': Icons.trending_up,
        'color': Colors.indigo,
        'description': 'Price predictions & analysis',
        'onTap': () => _navigateToMarketPrices(),
      },
      {
        'title': 'Offline Mode',
        'icon': Icons.offline_bolt,
        'color': Colors.grey,
        'description': 'Work without internet',
        'onTap': () => _navigateToOfflineMode(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          child: InkWell(
            onTap: feature['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: 32,
                    color: feature['color'] as Color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'] as String,
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
      },
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getComprehensiveRecommendation,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Smart Recommendation'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _checkAllServices,
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Health Check'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCropRecommendation() {
    // Navigate to crop recommendation screen
    Navigator.pushNamed(context, '/crop_recommendation');
  }

  void _navigateToSoilAnalysis() {
    // Navigate to soil analysis screen
    Navigator.pushNamed(context, '/sih_2025_soil_analysis');
  }

  void _navigateToMultilingual() {
    // Navigate to multilingual chat screen
    Navigator.pushNamed(context, '/sih_2025_multilingual');
  }

  void _navigateToDiseaseDetection() {
    // Navigate to disease detection screen
    Navigator.pushNamed(context, '/pest_detection');
  }

  void _navigateToSustainability() {
    // Navigate to sustainability screen
    Navigator.pushNamed(context, '/sih_2025_sustainability');
  }

  void _navigateToWeather() {
    // Navigate to weather screen
    Navigator.pushNamed(context, '/weather');
  }

  void _navigateToMarketPrices() {
    // Navigate to market prices screen
    Navigator.pushNamed(context, '/market_price');
  }

  void _navigateToOfflineMode() {
    // Navigate to offline mode screen (using profile screen for now)
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _getComprehensiveRecommendation() async {
    setState(() => _isLoading = true);

    try {
      // Sample data for comprehensive recommendation
      final soilData = {
        'ph': 7.0,
        'nitrogen': 50.0,
        'phosphorus': 30.0,
        'potassium': 40.0,
        'moisture': 60.0,
      };

      final weatherData = {
        'temperature': 25.0,
        'humidity': 70.0,
        'rainfall': 100.0,
        'wind_speed': 5.0,
      };

      final locationData = {
        'latitude': 28.6139,
        'longitude': 77.2090,
        'location': 'Delhi',
      };

      final recommendation =
          await _sih2025Service.getComprehensiveRecommendation(
        soilData: soilData,
        weatherData: weatherData,
        locationData: locationData,
        language: 'en',
      );

      setState(() => _isLoading = false);

      // Show recommendation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Comprehensive Recommendation'),
          content: Text(recommendation.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get recommendation: $e')),
      );
    }
  }

  Future<void> _checkAllServices() async {
    setState(() => _isLoading = true);

    try {
      final services = [
        ('Additional Features Service', _sih2025Service.checkHealth()),
      ];

      final results = await Future.wait([
        for (final (name, future) in services)
          future.then((health) => '$name: ${health ? "✅" : "❌"}')
      ]);

      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Service Health Check'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: results.map((result) => Text(result)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check services: $e')),
      );
    }
  }
}
