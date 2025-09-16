import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'add_crop_screen.dart';

class FieldDetailScreen extends StatefulWidget {
  final Map<String, dynamic> field;

  const FieldDetailScreen({
    super.key,
    required this.field,
  });

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _fieldDetails;
  List<Map<String, dynamic>> _cropHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

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

    _loadFieldDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await NetworkService.get(
        '${AppConfig.fieldManagementApiBaseUrl}/fields/${widget.field['id']}',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _fieldDetails = response['data']['field'];
          _cropHistory = List<Map<String, dynamic>>.from(
            response['data']['crop_history'],
          );
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load field details';
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

  Future<void> _loadRecommendations() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.fieldManagementApiBaseUrl}/fields/${widget.field['id']}/recommendations',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        // Navigate to recommendations screen or show in dialog
        _showRecommendationsDialog(response['data']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load recommendations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRecommendationsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Recommendations'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on your field conditions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text('Soil Type: ${data['field']['soil_type']}'),
              Text(
                  'Soil pH: ${data['field']['soil_ph']} (${data['soil_analysis']['ph_status']})'),
              Text('Area: ${data['field']['area_hectares']} hectares'),
              const SizedBox(height: 16),
              Text(
                'Recommended Crops:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: data['recommendations']['all_recommendations']
                    .map<Widget>((crop) => Chip(
                          label: Text(crop),
                          backgroundColor:
                              const Color(0xFF2E7D32).withOpacity(0.1),
                          labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                        ))
                    .toList(),
              ),
              if (data['recommendations']['avoid_crops'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Recently Planted (Avoid):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: data['recommendations']['avoid_crops']
                      .map<Widget>((crop) => Chip(
                            label: Text(crop),
                            backgroundColor: Colors.red[50],
                            labelStyle: TextStyle(color: Colors.red[700]),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddCrop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Crop'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddCrop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCropScreen(fieldId: widget.field['id']),
      ),
    );

    if (result == true) {
      _loadFieldDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.field['name'] ?? 'Field Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFieldDetails,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCrop,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Crop',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(message: 'Loading field details...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadFieldDetails,
        ),
      );
    }

    if (_fieldDetails == null) {
      return const Center(
        child: Text('Field details not found'),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildFieldHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
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
                  Icons.agriculture,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fieldDetails!['name'] ?? 'Unnamed Field',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_fieldDetails!['description'] != null &&
                        _fieldDetails!['description'].isNotEmpty)
                      Text(
                        _fieldDetails!['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderInfo(
                Icons.straighten,
                '${_fieldDetails!['area_hectares']?.toStringAsFixed(1) ?? '0.0'} ha',
                'Area',
              ),
              const SizedBox(width: 24),
              _buildHeaderInfo(
                Icons.terrain,
                _fieldDetails!['soil_type'] ?? 'Unknown',
                'Soil Type',
              ),
              const SizedBox(width: 24),
              _buildHeaderInfo(
                Icons.water_drop,
                '${_fieldDetails!['soil_moisture']?.toStringAsFixed(0) ?? '0'}%',
                'Moisture',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String value, String label) {
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: TabController(
            length: 3, vsync: this, initialIndex: _selectedTabIndex),
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        indicator: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Crop History'),
          Tab(text: 'Recommendations'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCropHistoryTab();
      case 2:
        return _buildRecommendationsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildSoilCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Field Name', _fieldDetails!['name'] ?? 'Unknown'),
            _buildInfoRow('Area',
                '${_fieldDetails!['area_hectares']?.toStringAsFixed(1) ?? '0.0'} hectares'),
            _buildInfoRow('Created', _formatDate(_fieldDetails!['created_at'])),
            _buildInfoRow(
                'Last Updated', _formatDate(_fieldDetails!['updated_at'])),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location & GPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Latitude',
                _fieldDetails!['latitude']?.toStringAsFixed(6) ?? '0.000000'),
            _buildInfoRow('Longitude',
                _fieldDetails!['longitude']?.toStringAsFixed(6) ?? '0.000000'),
            _buildInfoRow('Elevation',
                '${_fieldDetails!['elevation']?.toStringAsFixed(1) ?? '0.0'} meters'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Soil Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                'Soil Type', _fieldDetails!['soil_type'] ?? 'Unknown'),
            _buildInfoRow('Soil pH',
                _fieldDetails!['soil_ph']?.toStringAsFixed(1) ?? '0.0'),
            _buildInfoRow('Soil Moisture',
                '${_fieldDetails!['soil_moisture']?.toStringAsFixed(0) ?? '0'}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildCropHistoryTab() {
    if (_cropHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Crop History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start by adding your first crop to this field.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cropHistory.length,
      itemBuilder: (context, index) {
        final crop = _cropHistory[index];
        return _buildCropCard(crop);
      },
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    crop['crop_name'] ?? 'Unknown Crop',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                if (crop['harvesting_date'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Harvested',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Growing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCropInfo(
                  Icons.calendar_today,
                  'Planted: ${_formatDate(crop['planting_date'])}',
                ),
                if (crop['harvesting_date'] != null) ...[
                  const SizedBox(width: 16),
                  _buildCropInfo(
                    Icons.calendar_today,
                    'Harvested: ${_formatDate(crop['harvesting_date'])}',
                  ),
                ],
              ],
            ),
            if (crop['yield_kg'] != null) ...[
              const SizedBox(height: 8),
              _buildCropInfo(
                Icons.scale,
                'Yield: ${crop['yield_kg']} kg',
              ),
            ],
            if (crop['notes'] != null && crop['notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                crop['notes'],
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildCropInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Get Crop Recommendations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized crop recommendations based on your field\'s soil conditions and history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.psychology),
              label: const Text('Get Recommendations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
