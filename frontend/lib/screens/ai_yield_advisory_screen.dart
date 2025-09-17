import 'package:flutter/material.dart';
import '../services/ai_yield_advisory_service.dart';
import '../services/location_service.dart';

class AiYieldAdvisoryScreen extends StatefulWidget {
  const AiYieldAdvisoryScreen({super.key});

  @override
  State<AiYieldAdvisoryScreen> createState() => _AiYieldAdvisoryScreenState();
}

class _AiYieldAdvisoryScreenState extends State<AiYieldAdvisoryScreen>
    with TickerProviderStateMixin {
  final _service = AiYieldAdvisoryService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _crops = const [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Soybean',
  ];

  String _selectedCrop = 'Rice';
  String _season = 'Kharif';
  final _areaController = TextEditingController(text: '1.0');

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _advisory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _runAdvisory() async {
    setState(() {
      _loading = true;
      _error = null;
      _advisory = null;
    });

    try {
      final position = await LocationService.getLocationWithFallback();
      final lat = position?.latitude ?? 28.6139;
      final lon = position?.longitude ?? 77.2090;
      final area = double.tryParse(_areaController.text.trim()) ?? 1.0;

      final res = await _service
          .getAdvisory(
            cropName: _selectedCrop,
            latitude: lat,
            longitude: lon,
            areaHectares: area,
            season: _season,
          )
          .timeout(const Duration(seconds: 30));

      if (res['success'] == true) {
        setState(() {
          _advisory = Map<String, dynamic>.from(res['data'] as Map);
          _loading = false;
        });
      } else {
        setState(() {
          _error = (res['error'] ?? 'Failed to generate advisory').toString();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Yield & Advisory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3F51B5),
        actions: [
          TextButton(
            onPressed: _loading ? null : _runAdvisory,
            child: const Text('Run',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 16),
                _buildInputCard(),
                const SizedBox(height: 16),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_error != null) _buildError(_error!),
                if (_advisory != null) ...[
                  const SizedBox(height: 16),
                  _buildResults(_advisory!),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _runAdvisory,
        backgroundColor: const Color(0xFF3F51B5),
        label:
            const Text('Get Advisory', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF3F51B5).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6))
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get AI-driven yield predictions with irrigation, fertilization, and pest management advice based on your location.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              decoration: const InputDecoration(
                labelText: 'Crop',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.eco, color: Color(0xFF3F51B5)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3F51B5))),
              ),
              items: _crops
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCrop = v ?? _selectedCrop),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area (ha)',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.straighten, color: Color(0xFF3F51B5)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3F51B5))),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _season,
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      border: OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF3F51B5)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3F51B5))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Kharif', child: Text('Kharif')),
                      DropdownMenuItem(value: 'Rabi', child: Text('Rabi')),
                      DropdownMenuItem(value: 'Zaid', child: Text('Zaid')),
                    ],
                    onChanged: (v) => setState(() => _season = v ?? _season),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(message, style: TextStyle(color: Colors.red[700])),
    );
  }

  Widget _buildResults(Map<String, dynamic> advisory) {
    final prediction = Map<String, dynamic>.from(advisory['prediction'] as Map);
    final advice = Map<String, dynamic>.from(advisory['advisory'] as Map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Predicted Yield',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          const Icon(Icons.analytics, color: Color(0xFF3F51B5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${(prediction['predicted_yield'] ?? 0).toString()} kg total',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                              'Per hectare: ${(prediction['yield_per_hectare'] ?? 0).toString()} kg/ha',
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '${(((prediction['confidence_score'] ?? 0.7) as num) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3F51B5))),
                        const Text('Confidence',
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOverallScoreCard(advice),
        const SizedBox(height: 12),
        _buildAdviceCard('Irrigation Plan', Icons.water_drop, Color(0xFF03A9F4),
            _getIrrigationAdvice(advice)),
        const SizedBox(height: 12),
        _buildAdviceCard('Fertilization Plan', Icons.grass, Color(0xFF8BC34A),
            _getFertilizationAdvice(advice)),
        const SizedBox(height: 12),
        _buildAdviceCard('Pest Management', Icons.bug_report, Color(0xFFF44336),
            _getPestManagementAdvice(advice)),
        const SizedBox(height: 12),
        _buildAdviceCard('Risks & Alerts', Icons.warning_amber,
            Color(0xFFFF9800), List<String>.from(advice['risks'] ?? const [])),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdviceCard(
      String title, IconData icon, Color color, List<String> lines) {
    return Card(
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
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(l)),
                  ],
                ),
              ),
            if (lines.isEmpty)
              Text('No specific advice at the moment.',
                  style: TextStyle(color: Colors.grey[600]))
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScoreCard(Map<String, dynamic> advice) {
    final overallScore = advice['overall_score'] as double? ?? 0.0;
    Color scoreColor;
    String scoreText;

    if (overallScore >= 80) {
      scoreColor = const Color(0xFF4CAF50); // Green
      scoreText = 'Excellent';
    } else if (overallScore >= 60) {
      scoreColor = const Color(0xFFFF9800); // Orange
      scoreText = 'Good';
    } else {
      scoreColor = const Color(0xFFF44336); // Red
      scoreText = 'Needs Attention';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assessment,
                color: scoreColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Field Score',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreText,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${overallScore.toStringAsFixed(0)}/100',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Score',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to convert new data structure to list format
  List<String> _getIrrigationAdvice(Map<String, dynamic> advice) {
    final irrigation = advice['irrigation'] as Map<String, dynamic>?;
    if (irrigation == null) return ['No irrigation advice available'];

    return [
      irrigation['advice'] ?? 'No specific irrigation advice',
      'Frequency: ${irrigation['frequency'] ?? 'Not specified'}',
      'Amount: ${irrigation['amount'] ?? 'Not specified'}',
    ];
  }

  List<String> _getFertilizationAdvice(Map<String, dynamic> advice) {
    final fertilization = advice['fertilization'] as Map<String, dynamic>?;
    if (fertilization == null) return ['No fertilization advice available'];

    return [
      fertilization['advice'] ?? 'No specific fertilization advice',
      'NPK Ratio: ${fertilization['npk_ratio'] ?? 'Not specified'}',
      'Timing: ${fertilization['timing'] ?? 'Not specified'}',
    ];
  }

  List<String> _getPestManagementAdvice(Map<String, dynamic> advice) {
    final pestManagement = advice['pest_management'] as Map<String, dynamic>?;
    if (pestManagement == null) return ['No pest management advice available'];

    List<String> adviceList = [
      pestManagement['advice'] ?? 'No specific pest management advice',
      'Monitoring: ${pestManagement['monitoring_schedule'] ?? 'Not specified'}',
    ];

    // Add preventive measures if available
    final preventiveMeasures =
        pestManagement['preventive_measures'] as List<dynamic>?;
    if (preventiveMeasures != null) {
      adviceList.add('Preventive Measures:');
      for (String measure in preventiveMeasures) {
        adviceList.add('• $measure');
      }
    }

    return adviceList;
  }
}
