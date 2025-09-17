import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/network_service.dart';
import '../services/location_service.dart';
import '../services/ultra_crop_service.dart';
import '../services/ultra_crop_offline_service.dart';
import 'ultra_crop_recommendation_results_screen.dart';

class UltraCropRecommenderScreen extends StatefulWidget {
  const UltraCropRecommenderScreen({super.key});

  @override
  State<UltraCropRecommenderScreen> createState() =>
      _UltraCropRecommenderScreenState();
}

class _UltraCropRecommenderScreenState extends State<UltraCropRecommenderScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _farmSizeController = TextEditingController();
  String _farmSizeUnit = 'hectares';

  // Map and Location
  GoogleMapController? _mapController;
  // Position state is used implicitly by _selectedLocation; no separate field needed
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Default: Delhi
  String _locationName = 'Delhi, India';
  bool _isLocationLoading = false;

  // Form Data
  String _selectedIrrigationType = 'canal';
  String _selectedCropType = 'all';
  String _selectedLanguage = 'en';
  List<String> _preferredCrops = [];

  // Optional Soil Test Data
  bool _hasSoilTestData = false;
  final Map<String, TextEditingController> _soilControllers = {
    'ph': TextEditingController(),
    'nitrogen': TextEditingController(),
    'phosphorus': TextEditingController(),
    'potassium': TextEditingController(),
    'organic_carbon': TextEditingController(),
    'soil_moisture': TextEditingController(),
  };

  // API Response
  Map<String, dynamic>? _recommendationData;
  bool _isLoading = false;
  String? _error;

  // Offline Mode
  bool _isOfflineMode = false;
  bool _isOfflineAvailable = false;
  bool _isDownloadingOfflineData = false;

  // UI State
  int _currentStep = 0;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _checkOfflineCapability();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _farmSizeController.dispose();
    _soilControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final permission = await LocationService.checkLocationPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final newPermission = await LocationService.requestLocationPermission();

        if (newPermission != LocationPermission.whileInUse &&
            newPermission != LocationPermission.always) {
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
      });

      // Get location name
      await _updateLocationName();

      // Update map
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 15),
        );
      }
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
        _error = 'Location error: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _checkOfflineCapability() async {
    try {
      final isAvailable =
          await UltraCropOfflineService.isOfflineModeAvailable();
      final isOnline = await NetworkService.checkConnectivity();

      setState(() {
        _isOfflineAvailable = isAvailable;
        _isOfflineMode = !isOnline;
      });

      // Auto-sync cached recommendations if online
      if (isOnline && isAvailable) {
        UltraCropOfflineService.syncCachedRecommendations();
      }
    } catch (e) {
      print('Error checking offline capability: $e');
    }
  }

  Future<void> _downloadOfflineData() async {
    setState(() {
      _isDownloadingOfflineData = true;
    });

    try {
      final result = await UltraCropOfflineService.downloadOfflineData();

      if (result['success']) {
        setState(() {
          _isOfflineAvailable = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline data downloaded successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () => _showOfflineDataDetails(result['data']),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to download offline data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading offline data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloadingOfflineData = false;
      });
    }
  }

  void _showOfflineDataDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Data Downloaded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Crops cached: ${data['crops_cached']}'),
            Text('• Models cached: ${data['models_cached']}'),
            Text(
                '• Cache size: ${data['cache_size_mb'].toStringAsFixed(2)} MB'),
            const SizedBox(height: 8),
            const Text(
              'You can now use the Ultra Crop Recommender offline!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLocationName() async {
    try {
      // In production, use geocoding service
      // For now, use coordinates
      setState(() {
        _locationName =
            '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      print('Geocoding error: $e');
    }
  }

  Future<void> _getUltraRecommendation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _recommendationData = null;
    });

    try {
      double farmSize = double.parse(_farmSizeController.text);

      // Convert to hectares if needed
      if (_farmSizeUnit == 'acres') {
        farmSize = farmSize * 0.404686; // Convert acres to hectares
      }

      Map<String, double>? soilData;

      // Add soil test data if available
      if (_hasSoilTestData) {
        soilData = <String, double>{};
        _soilControllers.forEach((key, controller) {
          if (controller.text.isNotEmpty) {
            soilData![key] = double.tryParse(controller.text) ?? 0.0;
          }
        });
      }

      Map<String, dynamic> response;

      // Check if we should use offline mode
      final isOnline = await NetworkService.checkConnectivity();

      if (!isOnline && _isOfflineAvailable) {
        // Use offline recommendation
        response = await UltraCropOfflineService.getOfflineRecommendation(
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          location: _locationName,
          farmSize: farmSize,
          irrigationType: _selectedIrrigationType,
          soilData: soilData,
          language: _selectedLanguage,
        );
      } else if (!isOnline && !_isOfflineAvailable) {
        // No connection and no offline data
        setState(() {
          _error =
              'No internet connection and offline data not available. Please download offline data when connected.';
          _isLoading = false;
        });
        return;
      } else {
        // Use online recommendation
        response = await UltraCropService.getUltraRecommendation(
          latitude: _selectedLocation.latitude,
          longitude: _selectedLocation.longitude,
          location: _locationName,
          farmSize: farmSize,
          irrigationType: _selectedIrrigationType,
          preferredCrops: _preferredCrops,
          soilData: soilData,
          language: _selectedLanguage,
        );
      }

      if (response['success'] == true) {
        setState(() {
          // Pass the full API response through so results screen can access
          // success, data, and error fields consistently.
          _recommendationData = response;
          _isLoading = false;
        });

        // Navigate to results
        _showResults();
      } else {
        setState(() {
          _error = response['error'] ?? 'Unknown error occurred';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UltraCropRecommendationResultsScreen(
          recommendationData: _recommendationData!,
          location: _selectedLocation,
          locationName: _locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ULTRA CROP RECOMMENDER',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        // Offline Mode Indicator
        if (_isOfflineMode)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Download Offline Data Button
        if (!_isOfflineAvailable && !_isOfflineMode)
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _isDownloadingOfflineData ? null : _downloadOfflineData,
            tooltip: 'Download Offline Data',
          ),

        // Help Button
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Progress Indicator
        _buildProgressIndicator(),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Status Card
                  if (_isOfflineMode || !_isOfflineAvailable)
                    _buildOfflineStatusCard(),
                  if (_isOfflineMode || !_isOfflineAvailable)
                    const SizedBox(height: 16),

                  _buildStepContent(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Step ${_currentStep + 1} of 4',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOfflineMode
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (_isOfflineMode ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isOfflineMode ? Icons.wifi_off : Icons.cloud_download,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isOfflineMode ? 'Offline Mode' : 'Offline Data Available',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isOfflineMode) ...[
            const Text(
              'You\'re currently offline. Using cached models and data for recommendations.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (!_isOfflineAvailable) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ No offline data available. Recommendations may be limited.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ] else ...[
            const Text(
              'Download offline data to use Ultra Crop Recommender without internet.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isDownloadingOfflineData ? null : _downloadOfflineData,
                icon: _isDownloadingOfflineData
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.blue),
                label: Text(
                  _isDownloadingOfflineData
                      ? 'Downloading...'
                      : 'Download Offline Data',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildLocationStep();
      case 1:
        return _buildFarmDetailsStep();
      case 2:
        return _buildSoilTestStep();
      case 3:
        return _buildPreferencesStep();
      default:
        return _buildLocationStep();
    }
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          '📍 Select Your Farm Location',
          'Choose your farm location on the map or use current location',
        ),
        const SizedBox(height: 20),

        // Location Card
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLocationLoading ? null : _getCurrentLocation,
                    icon: _isLocationLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: const Text('Current Location'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Map
              if (_showMap) ...[
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onTap: (position) {
                        setState(() {
                          _selectedLocation = position;
                        });
                        _updateLocationName();
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: _selectedLocation,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                          infoWindow: InfoWindow(
                            title: 'Selected Farm Location',
                            snippet: _locationName,
                          ),
                        ),
                      },
                      mapType: MapType.hybrid,
                      zoomControlsEnabled: true,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tap on the map to select your exact farm location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showMap = !_showMap;
                        });
                      },
                      child: Text(_showMap ? 'Hide Map' : 'Show Map'),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.map, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Map Hidden',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showMap = true;
                          });
                        },
                        child: const Text('Show Map'),
                      ),
                    ],
                  ),
                ),
              ],

              // Coordinates Display
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed,
                        color: Color(0xFF1B5E20), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          '🏞️ Farm Details',
          'Tell us about your farm size and irrigation setup',
        ),
        const SizedBox(height: 20),

        // Farm Size
        _buildInputCard(
          title: 'Farm Size',
          icon: Icons.square_foot,
          child: TextFormField(
            controller: _farmSizeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Farm Size',
              hintText: 'Enter your farm size',
              suffixIcon: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _farmSizeUnit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'hectares',
                        child: Text('Hectares'),
                      ),
                      DropdownMenuItem(
                        value: 'acres',
                        child: Text('Acres'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _farmSizeUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter farm size';
              }
              final size = double.tryParse(value);
              if (size == null || size <= 0) {
                return 'Please enter a valid farm size';
              }
              return null;
            },
          ),
        ),

        const SizedBox(height: 16),

        // Irrigation Type
        _buildInputCard(
          title: 'Irrigation Type',
          icon: Icons.water_drop,
          child: DropdownButtonFormField<String>(
            value: _selectedIrrigationType,
            decoration: const InputDecoration(
              labelText: 'Irrigation Method',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'canal', child: Text('Canal Irrigation')),
              DropdownMenuItem(value: 'tubewell', child: Text('Tubewell')),
              DropdownMenuItem(value: 'drip', child: Text('Drip Irrigation')),
              DropdownMenuItem(value: 'sprinkler', child: Text('Sprinkler')),
              DropdownMenuItem(value: 'rainfed', child: Text('Rainfed')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedIrrigationType = value!;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Crop Type Preference
        _buildInputCard(
          title: 'Crop Type Preference',
          icon: Icons.agriculture,
          child: DropdownButtonFormField<String>(
            value: _selectedCropType,
            decoration: const InputDecoration(
              labelText: 'Preferred Crop Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Crops')),
              DropdownMenuItem(
                  value: 'grains', child: Text('Grains (Rice, Wheat, Maize)')),
              DropdownMenuItem(
                  value: 'cash', child: Text('Cash Crops (Cotton, Sugarcane)')),
              DropdownMenuItem(
                  value: 'legumes', child: Text('Legumes (Soybean, Pulses)')),
              DropdownMenuItem(value: 'vegetables', child: Text('Vegetables')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCropType = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSoilTestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          '🧪 Soil Test Data (Optional)',
          'Add your soil test results for more accurate recommendations',
        ),
        const SizedBox(height: 20),

        // Soil Test Toggle
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.science, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Do you have soil test results?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _hasSoilTestData,
                    onChanged: (value) {
                      setState(() {
                        _hasSoilTestData = value;
                        if (!value) {
                          // Clear soil data when disabled
                          _soilControllers.values.forEach((controller) {
                            controller.clear();
                          });
                        }
                      });
                    },
                    activeColor: const Color(0xFF1B5E20),
                  ),
                ],
              ),
              if (!_hasSoilTestData) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No problem! We\'ll use satellite data and AI to analyze your soil conditions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_hasSoilTestData) ...[
                const SizedBox(height: 16),
                const Text(
                  'Enter your soil test values:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                // Soil Parameters Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildSoilInput('pH', 'ph', '6.0-8.0'),
                    _buildSoilInput('Nitrogen (kg/ha)', 'nitrogen', '50-200'),
                    _buildSoilInput(
                        'Phosphorus (kg/ha)', 'phosphorus', '10-50'),
                    _buildSoilInput(
                        'Potassium (kg/ha)', 'potassium', '100-400'),
                    _buildSoilInput(
                        'Organic Carbon (%)', 'organic_carbon', '0.5-2.5'),
                    _buildSoilInput(
                        'Soil Moisture (%)', 'soil_moisture', '20-80'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoilInput(String label, String key, String range) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _soilControllers[key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: range,
            hintStyle: const TextStyle(fontSize: 10),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          '⚙️ Preferences',
          'Set your language and other preferences',
        ),
        const SizedBox(height: 20),

        // Language Selection
        _buildInputCard(
          title: 'Language Preference',
          icon: Icons.language,
          child: DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Select Language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
              DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
              DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
              DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
              DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.summarize, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('📍 Location', _locationName),
              _buildSummaryRow('🏞️ Farm Size',
                  '${_farmSizeController.text} $_farmSizeUnit'),
              _buildSummaryRow(
                  '💧 Irrigation', _selectedIrrigationType.toUpperCase()),
              _buildSummaryRow('🌾 Crop Type', _selectedCropType.toUpperCase()),
              _buildSummaryRow('🧪 Soil Test',
                  _hasSoilTestData ? 'Provided' : 'Not Provided'),
              _buildSummaryRow('🌐 Language', _selectedLanguage.toUpperCase()),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Ready to Analyze Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              const Icon(
                Icons.rocket_launch,
                size: 48,
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ready to Get Ultra Recommendations!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Our AI will analyze satellite data, weather patterns, soil conditions, and market trends to give you the best crop recommendations.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Analyzing your farm data...'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _getUltraRecommendation,
                  icon: const Icon(Icons.psychology),
                  label: const Text('GET ULTRA RECOMMENDATIONS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentStep < 3
                ? () {
                    setState(() {
                      _currentStep++;
                    });
                  }
                : _getUltraRecommendation,
            icon:
                Icon(_currentStep < 3 ? Icons.arrow_forward : Icons.psychology),
            label: Text(_currentStep < 3 ? 'Next' : 'Analyze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ultra Crop Recommender Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. 📍 Select your farm location on the map'),
              Text('2. 🏞️ Enter your farm details (size, irrigation)'),
              Text('3. 🧪 Add soil test data (optional but recommended)'),
              Text('4. ⚙️ Set your preferences and language'),
              Text('5. 🚀 Get AI-powered crop recommendations'),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 🛰️ Satellite soil analysis'),
              Text('• 🌦️ Weather pattern analysis'),
              Text('• 🤖 AI ensemble models'),
              Text('• 📊 Market trend analysis'),
              Text('• 💰 Profit calculations'),
              Text('• 🌱 Sustainability scoring'),
              Text('• 🗣️ Multilingual support'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
