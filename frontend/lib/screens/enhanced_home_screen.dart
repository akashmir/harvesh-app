import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:crop/widgets/enhanced_navigation_drawer.dart';
import 'ultra_crop_recommender_screen.dart';
import 'enhanced_blog_screen.dart';
import 'enhanced_pest_detection_screen.dart';
import 'query_history_screen.dart';
import 'crop_calendar_screen.dart';
import 'field_management_screen.dart';
import 'yield_prediction_screen.dart';
import 'market_price_screen.dart';
import 'weather_integration_screen.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import 'ai_yield_advisory_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Weather integration state
  Map<String, dynamic>? _currentWeather;
  bool _isWeatherLoading = true;
  String? _weatherError;
  final String _selectedLocation = 'Delhi';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _loadCurrentWeather();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentWeather() async {
    try {
      setState(() {
        _isWeatherLoading = true;
        _weatherError = null;
      });

      // Check location permission first
      final permission = await LocationService.checkLocationPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Request permission
        final newPermission = await LocationService.requestLocationPermission();

        if (newPermission == LocationPermission.deniedForever) {
          setState(() {
            _weatherError =
                'Location permission denied. Please enable location access in settings.';
            _isWeatherLoading = false;
          });
          return;
        } else if (newPermission == LocationPermission.denied) {
          setState(() {
            _weatherError =
                'Location permission required for accurate weather data.';
            _isWeatherLoading = false;
          });
          return;
        }
      }

      // Use automatic location detection
      final response = await WeatherService.getCurrentWeatherAuto();

      if (response['success']) {
        setState(() {
          _currentWeather = Map<String, dynamic>.from(response['data'] as Map);
          _isWeatherLoading = false;
        });
      } else {
        setState(() {
          _weatherError = response['error'] ?? 'Failed to load weather';
          _isWeatherLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _weatherError = 'Weather service unavailable: ${e.toString()}';
        _isWeatherLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      endDrawer: const EnhancedCustomDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRealTimeWeatherCard(),
                const SizedBox(height: 24),
                //_buildUltraRecommenderHero(),
                const SizedBox(height: 24),
                _buildMainFeaturesGrid(),
                const SizedBox(height: 24),
                _buildAdditionalFeatures(),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(
                    height: 20), // Reduced spacing since no bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Harvest',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  // Widget _buildUltraRecommenderHero() {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Color(0xFF1B5E20),
  //           Color(0xFF2E7D32),
  //           Color(0xFF388E3C),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF1B5E20).withOpacity(0.3),
  //           blurRadius: 15,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.2),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: const Icon(
  //                 Icons.psychology,
  //                 color: Colors.white,
  //                 size: 32,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             const Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     '🚀 ULTRA CROP RECOMMENDER',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 20,
  //                       fontWeight: FontWeight.bold,
  //                       letterSpacing: 0.5,
  //                     ),
  //                   ),
  //                   SizedBox(height: 4),
  //                   Text(
  //                     'NEW FEATURE',
  //                     style: TextStyle(
  //                       color: Colors.amber,
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.bold,
  //                       letterSpacing: 1.0,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 20),
  //
  //         const Text(
  //           'Advanced AI-powered crop recommendations using:',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: 16,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //
  //         // Features List
  //         const Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   FeatureItem(icon: '🛰️', text: 'Satellite Soil Analysis'),
  //                   FeatureItem(icon: '🌦️', text: 'Weather Patterns'),
  //                   FeatureItem(icon: '🤖', text: 'ML Ensemble Models'),
  //                 ],
  //               ),
  //             ),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   FeatureItem(icon: '📊', text: 'Market Analysis'),
  //                   FeatureItem(icon: '💰', text: 'Profit Calculations'),
  //                   FeatureItem(icon: '🌱', text: 'Sustainability Score'),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //
  //         const SizedBox(height: 20),
  //
  //         // CTA Button
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton.icon(
  //             onPressed: () => Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => const UltraCropRecommenderScreen(),
  //               ),
  //             ),
  //             icon: const Icon(Icons.rocket_launch, color: Color(0xFF1B5E20)),
  //             label: const Text(
  //               'TRY ULTRA RECOMMENDER',
  //               style: TextStyle(
  //                 color: Color(0xFF1B5E20),
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(vertical: 16),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               elevation: 0,
  //             ),
  //           ),
  //         ),
  //
  //         const SizedBox(height: 12),
  //
  //         // Confidence Badge
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 12,
  //                 vertical: 6,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.2),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: const Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(Icons.verified, color: Colors.amber, size: 16),
  //                   SizedBox(width: 4),
  //                   Text(
  //                     'AI-Powered • 95% Accuracy',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRealTimeWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF00BCD4),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Real-Time Weather',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadCurrentWeather,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isWeatherLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_weatherError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _weatherError!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_weatherError!.contains('permission') ||
                    _weatherError!.contains('settings'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_weatherError!.contains('settings')) {
                          await LocationService.openAppSettings();
                        } else {
                          await _loadCurrentWeather();
                        }
                      },
                      icon: const Icon(Icons.settings, size: 16),
                      label: Text(
                        _weatherError!.contains('settings')
                            ? 'Open Settings'
                            : 'Try Again',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                  ),
              ],
            )
          else if (_currentWeather != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _currentWeather!['precise_location_label'] ??
                                  _currentWeather!['location'] ??
                                  _selectedLocation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_currentWeather!['country'] != null)
                            Text(
                              _currentWeather!['country'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_currentWeather!['temperature']?.toStringAsFixed(0) ?? '--'}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentWeather!['description'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Humidity: ${_currentWeather!['humidity']?.toStringAsFixed(0) ?? '--'}%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_currentWeather!['icon'] != null)
                  Image.network(
                    'https://openweathermap.org/img/wn/${_currentWeather!['icon']}@2x.png',
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.wb_sunny,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WeatherIntegrationScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Full Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeaturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Main Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: [
            _buildMainFeatureCard(
              title: '🚀 ULTRA CROP RECOMMENDER',
              subtitle: 'AI-powered satellite analysis with ML ensemble',
              icon: Icons.psychology,
              color: const Color(0xFF1B5E20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UltraCropRecommenderScreen()),
              ),
            ),
            _buildMainFeatureCard(
              title: '🤖 AI Yield & Advisory',
              subtitle: 'Predict yield + irrigation, fertilizer, pest plan',
              icon: Icons.psychology,
              color: const Color(0xFF3F51B5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AiYieldAdvisoryScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        _buildAdditionalFeatureCard(
          title: '💰 Market Prices',
          subtitle: 'Location-based mandi prices from Agmarknet',
          icon: Icons.trending_up,
          color: const Color(0xFF2196F3),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MarketPriceScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: 'Crop Doctor',
          subtitle: 'Take a photo to check plant health',
          icon: Icons.camera_alt,
          color: const Color(0xFFF44336),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EnhancedPestDetectionScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: '📊 Yield Calculator',
          subtitle: 'Know how much you can harvest',
          icon: Icons.analytics,
          color: const Color(0xFF8BC34A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const YieldPredictionScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: '📖 Farming Tips',
          subtitle: 'Learn from expert farmers',
          icon: Icons.article,
          color: const Color(0xFF9C27B0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedBlogScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: '📅 Planting Calendar',
          subtitle: 'When to plant and harvest crops',
          icon: Icons.calendar_today,
          color: const Color(0xFF2E7D32),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CropCalendarScreen()),
          ),
        ),
        _buildAdditionalFeatureCard(
          title: '🏞️ My Fields',
          subtitle: 'Keep track of all your fields',
          icon: Icons.agriculture,
          color: const Color(0xFF4CAF50),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const FieldManagementScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: '📊 Yield Calculator',
          subtitle: 'Know how much you can harvest',
          icon: Icons.analytics,
          color: const Color(0xFF8BC34A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const YieldPredictionScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: 'More Additional Features',
          subtitle: 'Advanced AI-powered farming solutions',
          icon: Icons.smart_toy,
          color: const Color(0xFF9C27B0),
          onTap: () => Navigator.pushNamed(context, '/sih_2025_dashboard'),
        ),
        const SizedBox(height: 12),
        _buildAdditionalFeatureCard(
          title: '📋 My History',
          subtitle: 'See your past crop recommendations',
          icon: Icons.history,
          color: const Color(0xFF607D8B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QueryHistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.psychology,
                title: 'Crop Recommendation',
                subtitle: 'Rice recommended for your soil',
                time: '2 hours ago',
                color: const Color(0xFF4CAF50),
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.camera_alt,
                title: 'Disease Detection',
                subtitle: 'Healthy plant detected',
                time: '1 day ago',
                color: const Color(0xFF2196F3),
              ),
              const Divider(height: 24),
              _buildActivityItem(
                icon: Icons.cloud,
                title: 'Weather Alert',
                subtitle: 'Rain expected tomorrow',
                time: '2 days ago',
                color: const Color(0xFF00BCD4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

// Helper Widget for Feature Items
class FeatureItem extends StatelessWidget {
  final String icon;
  final String text;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
