import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UltraCropRecommendationResultsScreen extends StatelessWidget {
  final Map<String, dynamic> recommendationData;
  final LatLng location;
  final String locationName;

  const UltraCropRecommendationResultsScreen({
    super.key,
    required this.recommendationData,
    required this.location,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('Ultra Recommendations'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationHeader(),
            const SizedBox(height: 20),
            _buildPrimaryRecommendation(),
            const SizedBox(height: 20),
            _buildDetailedAnalysis(),
            const SizedBox(height: 20),
            _buildActionableInsights(),
            const SizedBox(height: 20),
            _buildDataSources(),
            const SizedBox(height: 20),
            _buildBackButton(context),
          ],
        ),
      ),
    );
  }

  // Safely get unified data object regardless of backend variant
  Map<String, dynamic> _getData() {
    final data = recommendationData['data'];
    if (data is Map<String, dynamic>) return data;
    return recommendationData;
  }

  Map<String, dynamic>? _getRecommendationBlock(Map<String, dynamic> data) {
    final rec = data['recommendation'];
    if (rec is Map<String, dynamic>) return rec;
    return null;
  }

  String? _getPrimaryCrop(Map<String, dynamic> data) {
    final rec = _getRecommendationBlock(data);
    if (rec != null) return rec['primary_recommendation'] as String?;

    final list = data['recommendations'];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map<String, dynamic>) {
        final dynamic name =
            first['crop_name'] ?? first['crop'] ?? first['name'];
        return name is String ? name : null;
      }
    }

    final quick = data['recommended_crop'];
    if (quick is String) return quick;
    return null;
  }

  int _getConfidencePct(Map<String, dynamic> data) {
    final rec = _getRecommendationBlock(data);
    if (rec != null) {
      final conf = rec['confidence'];
      if (conf is num) return (conf * 100).round();
    }

    final list = data['recommendations'];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map<String, dynamic>) {
        final dynamic conf = first['confidence'];
        if (conf is num) return (conf * 100).round();
        final dynamic score = first['score'];
        if (score is num) return score.round();
      }
    }

    final quickConf = data['confidence'];
    if (quickConf is num) return (quickConf * 100).round();
    return 0;
  }

  Widget _buildLocationHeader() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF1B5E20),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farm Location',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryRecommendation() {
    if (recommendationData['success'] != true) {
      return _buildErrorCard();
    }

    final data = _getData();
    final crop = _getPrimaryCrop(data);
    if (crop == null) {
      return _buildErrorCard();
    }
    final confidence = _getConfidencePct(data);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Recommendation',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Powered by Ultra ML Models',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  crop,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$confidence% Confidence',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              recommendationData['error'] ?? 'Failed to get recommendation',
              style: GoogleFonts.poppins(
                color: Colors.red[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    if (recommendationData['success'] != true) return const SizedBox.shrink();

    final data = _getData();
    final analysis = data['comprehensive_analysis'];
    if (analysis == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Analysis',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          'Environmental Analysis',
          Icons.eco,
          [
            'Soil Health: ${analysis['environmental_analysis']['soil_health']}',
            'Climate Suitability: ${analysis['environmental_analysis']['climate_suitability']}',
            'Water Access: ${(analysis['environmental_analysis']['water_availability']).toStringAsFixed(1)}%',
          ],
        ),
        const SizedBox(height: 12),
        _buildAnalysisCard(
          'Economic Analysis',
          Icons.attach_money,
          [
            'Yield Potential: ${analysis['economic_analysis']['yield_potential']}',
            'ROI Estimate: ${analysis['economic_analysis']['roi_estimate']}',
            'Profit Margin: ${analysis['economic_analysis']['profit_margin']}',
          ],
        ),
        const SizedBox(height: 12),
        _buildAnalysisCard(
          'Sustainability Metrics',
          Icons.eco,
          [
            'Sustainability Score: ${analysis['sustainability_metrics']['sustainability_score']}/10',
            'Environmental Impact: ${analysis['sustainability_metrics']['environmental_impact']}',
            'Carbon Footprint: ${analysis['sustainability_metrics']['carbon_footprint']}',
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(String title, IconData icon, List<String> items) {
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
              Icon(icon, color: const Color(0xFF1B5E20), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionableInsights() {
    if (recommendationData['success'] != true) return const SizedBox.shrink();

    final data = _getData();
    final insights = data['actionable_insights'];
    if (insights == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actionable Insights',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          'Immediate Actions',
          Icons.play_arrow,
          insights['immediate_actions'] ?? [],
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Preparation Needed',
          Icons.build,
          insights['preparation_needed'] ?? [],
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Long-term Strategy',
          Icons.trending_up,
          insights['long_term_strategy'] ?? [],
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title, IconData icon, List<dynamic> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDataSources() {
    if (recommendationData['success'] != true) return const SizedBox.shrink();

    final data = _getData();
    final sources = data['data_sources'];
    if (sources == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Sources',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Soil Data: ${sources['soil_data']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Weather Data: ${sources['weather_data']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            'Satellite Data: ${sources['satellite_indices']}',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Recommender'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
