import 'package:crop/widgets/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'services/offline_service.dart';
import 'services/network_service.dart';
import 'screens/splash_screen.dart';
import 'screens/custom_splash_screen.dart';
import 'screens/crop_recommendation_screen.dart';
import 'screens/simple_location_crop_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/pest_detection_screen.dart';
import 'screens/enhanced_pest_detection_screen.dart';
import 'screens/enhanced_weather_screen.dart';
import 'screens/enhanced_blog_screen.dart';
import 'screens/enhanced_about_screen.dart';
import 'screens/enhanced_crop_recommendation_screen.dart';
import 'screens/enhanced_simple_location_crop_screen.dart';
import 'screens/enhanced_profile_screen.dart';
import 'screens/about_screen.dart';
import 'screens/enhanced_login_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/crop_calendar_screen.dart';
import 'screens/field_management_screen.dart';
import 'screens/yield_prediction_screen.dart';
import 'screens/market_price_screen.dart';
import 'screens/weather_integration_screen.dart';
import 'screens/sih_2025_dashboard.dart';
import 'screens/sih_2025_soil_analysis_screen.dart';
import 'screens/sih_2025_multilingual_screen.dart';
import 'screens/sih_2025_sustainability_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: "env.production");
    } catch (e) {
      // If env.production doesn't exist, try .env
      try {
        await dotenv.load(fileName: ".env");
      } catch (e2) {
        // If neither exists, continue with defaults
        // No environment file found, using default configuration
      }
    }

    // Initialize services
    await OfflineService.initialize();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: FirebaseConfig.currentPlatform,
    );

    // Sync offline data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NetworkService.syncOfflineData();
    });

    runApp(const MyApp());
  } catch (e) {
    // Handle initialization error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Configuration Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please check your environment variables and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Harvest',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const CustomSplashScreen(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/auth': (context) => const AuthWrapper(),
          '/login': (context) => const EnhancedLoginScreen(),
          '/home': (context) => const MainApp(),
          '/crop_recommendation': (context) =>
              const EnhancedSimpleLocationCropScreen(),
          '/crop_recommendation_manual': (context) =>
              const EnhancedCropRecommendationScreen(),
          '/crop_recommendation_old': (context) =>
              const SimpleLocationCropScreen(),
          '/crop_recommendation_manual_old': (context) =>
              const CropRecommendationScreen(),
          '/blogs': (context) => const EnhancedBlogScreen(),
          '/blogs_old': (context) => BlogScreen(),
          '/weather': (context) => const EnhancedWeatherScreen(),
          '/weather_old': (context) => const WeatherScreen(),
          '/pest_detection': (context) => const EnhancedPestDetectionScreen(),
          '/pest_detection_old': (context) => const PestDetectionScreen(),
          '/profile': (context) => const EnhancedProfileScreen(),
          '/about': (context) => const EnhancedAboutScreen(),
          '/about_old': (context) => const AboutScreen(),
          '/crop_calendar': (context) => const CropCalendarScreen(),
          '/field_management': (context) => const FieldManagementScreen(),
          '/yield_prediction': (context) => const YieldPredictionScreen(),
          '/market_price': (context) => const MarketPriceScreen(),
          '/weather_integration': (context) => const WeatherIntegrationScreen(),
          '/sih_2025_dashboard': (context) => const Sih2025Dashboard(),
          '/sih_2025_soil_analysis': (context) =>
              const Sih2025SoilAnalysisScreen(),
          '/sih_2025_multilingual': (context) =>
              const Sih2025MultilingualScreen(),
          '/sih_2025_sustainability': (context) =>
              const Sih2025SustainabilityScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Initialize the auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      print('⏳ AuthWrapper: Waiting for initialization...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print(
            '🏗️ AuthWrapper: Building - Loading: ${authProvider.isLoading}, Authenticated: ${authProvider.isAuthenticated}');

        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          print('✅ AuthWrapper: User is authenticated, showing home screen');
          return const EnhancedHomeScreen();
        } else {
          print(
              '❌ AuthWrapper: User is not authenticated, showing login screen');
          return const EnhancedLoginScreen();
        }
      },
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest'),
        centerTitle: true,
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              "Welcome to Harvest!",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your go-to app for smarter farming with personalized crop recommendations, AI-powered pest and plant detection, real-time weather updates, and engaging agriculture blogs.",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // 2x2 Grid of Feature Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              children: [
                _buildFeatureCard(
                  context,
                  'Smart Crop Recommender',
                  'Location-based AI recommendations',
                  Icons.location_on,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/crop_recommendation'),
                ),
                _buildFeatureCard(
                  context,
                  'Manual Crop Recommender',
                  'Enter data manually',
                  Icons.edit,
                  Colors.orange,
                  () => Navigator.pushNamed(
                      context, '/crop_recommendation_manual'),
                ),
                _buildFeatureCard(
                  context,
                  'Crop Disease Detection',
                  'AI-powered plant disease detection',
                  Icons.camera_alt,
                  Colors.red,
                  () => Navigator.pushNamed(context, '/pest_detection'),
                ),
                _buildFeatureCard(
                  context,
                  'Weather Updates',
                  'Real-time weather information',
                  Icons.cloud,
                  Colors.cyan,
                  () => Navigator.pushNamed(context, '/weather'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Additional Features Row
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    'Agricultural Blogs',
                    'Expert farming tips and guides',
                    Icons.article,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/blogs'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(26),
                color.withAlpha(13),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
