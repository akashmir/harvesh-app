import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';

class AddFieldScreen extends StatefulWidget {
  final Position? currentPosition;

  const AddFieldScreen({
    super.key,
    this.currentPosition,
  });

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _elevationController = TextEditingController();
  final _soilPhController = TextEditingController();
  final _soilMoistureController = TextEditingController();

  String _selectedSoilType = 'loamy';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _soilTypes = [];

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
    _loadSoilTypes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _elevationController.dispose();
    _soilPhController.dispose();
    _soilMoistureController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.currentPosition != null) {
      _latitudeController.text =
          widget.currentPosition!.latitude.toStringAsFixed(6);
      _longitudeController.text =
          widget.currentPosition!.longitude.toStringAsFixed(6);
    }

    // Set default values
    _soilPhController.text = '6.5';
    _soilMoistureController.text = '50.0';
    _elevationController.text = '0.0';
  }

  Future<void> _loadSoilTypes() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.fieldManagementApiBaseUrl}/soil-types',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _soilTypes = List<Map<String, dynamic>>.from(
            response['data']['soil_types'].entries.map((e) => {
                  'key': e.key,
                  ...e.value,
                }),
          );
        });
      }
    } catch (e) {
      // Handle error silently, use default soil types
      setState(() {
        _soilTypes = [
          {
            'key': 'loamy',
            'name': 'Loamy Soil',
            'description': 'Balanced soil with good structure'
          },
          {
            'key': 'clay',
            'name': 'Clay Soil',
            'description': 'Heavy, dense soil with high water retention'
          },
          {
            'key': 'sandy',
            'name': 'Sandy Soil',
            'description': 'Light, well-draining soil'
          },
          {
            'key': 'silty',
            'name': 'Silty Soil',
            'description': 'Smooth, fertile soil'
          },
          {
            'key': 'peaty',
            'name': 'Peaty Soil',
            'description': 'Dark, organic-rich soil'
          },
        ];
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final fieldData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'area_hectares': double.parse(_areaController.text),
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'soil_type': _selectedSoilType,
        'soil_ph': double.parse(_soilPhController.text),
        'soil_moisture': double.parse(_soilMoistureController.text),
        'elevation': double.parse(_elevationController.text),
      };

      final response = await NetworkService.post(
        '${AppConfig.fieldManagementApiBaseUrl}/fields',
        body: fieldData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field added successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to save field';
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
          'Add New Field',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveField,
            child: const Text(
              'Save',
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
    if (_isLoading && _soilTypes.isEmpty) {
      return const Center(
        child: LoadingWidget(message: 'Loading soil types...'),
      );
    }

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
                _buildSectionHeader('Field Information'),
                _buildFieldInfoCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Location & GPS'),
                _buildLocationCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Soil Conditions'),
                _buildSoilCard(),
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
                _buildSaveButton(),
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
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildFieldInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name *',
                hintText: 'Enter field name',
                prefixIcon: Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Field name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter field description (optional)',
                prefixIcon: Icon(Icons.description, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Area (Hectares) *',
                hintText: 'Enter area in hectares',
                prefixIcon: Icon(Icons.straighten, color: Color(0xFF2E7D32)),
                suffixText: 'ha',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Area is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Area must be greater than 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
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
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude *',
                      hintText: 'Enter latitude',
                      prefixIcon:
                          Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Latitude is required';
                      }
                      final lat = double.tryParse(value);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Enter valid latitude (-90 to 90)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude *',
                      hintText: 'Enter longitude',
                      prefixIcon:
                          Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Longitude is required';
                      }
                      final lng = double.tryParse(value);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Enter valid longitude (-180 to 180)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _elevationController,
              decoration: const InputDecoration(
                labelText: 'Elevation (meters)',
                hintText: 'Enter elevation above sea level',
                prefixIcon: Icon(Icons.height, color: Color(0xFF2E7D32)),
                suffixText: 'm',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedSoilType,
              decoration: const InputDecoration(
                labelText: 'Soil Type *',
                prefixIcon: Icon(Icons.terrain, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              items: _soilTypes.map((soil) {
                return DropdownMenuItem<String>(
                  value: soil['key'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(soil['name'] ?? soil['key']),
                      if (soil['description'] != null)
                        Text(
                          soil['description'],
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
                  _selectedSoilType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _soilPhController,
                    decoration: const InputDecoration(
                      labelText: 'Soil pH',
                      hintText: '6.5',
                      prefixIcon: Icon(Icons.science, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final ph = double.tryParse(value);
                        if (ph == null || ph < 0 || ph > 14) {
                          return 'Enter valid pH (0-14)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _soilMoistureController,
                    decoration: const InputDecoration(
                      labelText: 'Soil Moisture (%)',
                      hintText: '50',
                      prefixIcon:
                          Icon(Icons.water_drop, color: Color(0xFF2E7D32)),
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final moisture = double.tryParse(value);
                        if (moisture == null ||
                            moisture < 0 ||
                            moisture > 100) {
                          return 'Enter valid moisture (0-100)';
                        }
                      }
                      return null;
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveField,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
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
                'Save Field',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
