import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class QueryHistoryScreen extends StatefulWidget {
  const QueryHistoryScreen({super.key});

  @override
  State<QueryHistoryScreen> createState() => _QueryHistoryScreenState();
}

class _QueryHistoryScreenState extends State<QueryHistoryScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _cropQueries = [];
  List<Map<String, dynamic>> _diseaseDetections = [];
  List<Map<String, dynamic>> _weatherQueries = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQueryHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQueryHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cropQueries =
          await _firestoreService.getCropRecommendationHistory();
      final diseaseDetections =
          await _firestoreService.getPlantDiseaseDetectionHistory();
      final weatherQueries = await _firestoreService.getWeatherQueryHistory();

      setState(() {
        _cropQueries = cropQueries;
        _diseaseDetections = diseaseDetections;
        _weatherQueries = weatherQueries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load query history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCropQuery(String queryId) async {
    try {
      await _firestoreService.deleteCropRecommendationQuery(queryId);
      await _loadQueryHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Query deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete query: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Query History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Crop Queries'),
            Tab(text: 'Disease Detection'),
            Tab(text: 'Weather Queries'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCropQueriesTab(),
                _buildDiseaseDetectionsTab(),
                _buildWeatherQueriesTab(),
              ],
            ),
    );
  }

  Widget _buildCropQueriesTab() {
    if (_cropQueries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.agriculture,
        title: 'No Crop Queries Yet',
        subtitle:
            'Start by getting crop recommendations to see your history here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQueryHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cropQueries.length,
        itemBuilder: (context, index) {
          final query = _cropQueries[index];
          return _buildCropQueryCard(query);
        },
      ),
    );
  }

  Widget _buildDiseaseDetectionsTab() {
    if (_diseaseDetections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bug_report,
        title: 'No Disease Detections Yet',
        subtitle:
            'Use the pest detection feature to see your detection history here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQueryHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _diseaseDetections.length,
        itemBuilder: (context, index) {
          final detection = _diseaseDetections[index];
          return _buildDiseaseDetectionCard(detection);
        },
      ),
    );
  }

  Widget _buildWeatherQueriesTab() {
    if (_weatherQueries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cloud,
        title: 'No Weather Queries Yet',
        subtitle: 'Check weather information to see your query history here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQueryHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _weatherQueries.length,
        itemBuilder: (context, index) {
          final query = _weatherQueries[index];
          return _buildWeatherQueryCard(query);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropQueryCard(Map<String, dynamic> query) {
    final recommendations = query['recommendations'] as List<dynamic>? ?? [];
    final inputData = query['inputData'] as Map<String, dynamic>? ?? {};
    final queryType = query['queryType'] as String? ?? 'manual';
    final location = query['location'] as String?;
    final createdAt = query['createdAt'] as String? ?? '';

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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        queryType == 'location'
                            ? 'Location-based Query'
                            : 'Manual Query',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      if (location != null)
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteCropQuery(query['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (inputData.isNotEmpty) ...[
              Text(
                'Input Parameters:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: inputData.entries.map((entry) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (recommendations.isNotEmpty) ...[
              Text(
                'Top Recommendations:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              ...recommendations.take(3).map((rec) {
                final cropName = rec['crop'] ?? rec['name'] ?? 'Unknown';
                final confidence = rec['confidence'] ?? rec['score'] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cropName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseDetectionCard(Map<String, dynamic> detection) {
    final result = detection['detectionResult'] as Map<String, dynamic>? ?? {};
    final confidence = detection['confidence'] as String? ?? '0';
    final createdAt = detection['createdAt'] as String? ?? '';

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
                    color: const Color(0xFFF44336).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Color(0xFFF44336),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['disease'] ??
                            result['name'] ??
                            'Unknown Disease',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'Confidence: $confidence%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result['description'] != null)
              Text(
                result['description'],
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherQueryCard(Map<String, dynamic> query) {
    final weatherData = query['weatherData'] as Map<String, dynamic>? ?? {};
    final location = query['location'] as Map<String, dynamic>? ?? {};
    final createdAt = query['createdAt'] as String? ?? '';

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
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['address'] ?? 'Unknown Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      if (weatherData['temperature'] != null)
                        Text(
                          '${weatherData['temperature']}°C',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (weatherData.isNotEmpty) ...[
              Text(
                'Weather Conditions:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: weatherData.entries.map((entry) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
