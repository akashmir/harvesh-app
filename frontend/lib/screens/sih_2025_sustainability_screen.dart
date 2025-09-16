import 'package:flutter/material.dart';
import '../services/sih_2025_simple_service.dart';

class Sih2025SustainabilityScreen extends StatefulWidget {
  const Sih2025SustainabilityScreen({Key? key}) : super(key: key);

  @override
  State<Sih2025SustainabilityScreen> createState() =>
      _Sih2025SustainabilityScreenState();
}

class _Sih2025SustainabilityScreenState
    extends State<Sih2025SustainabilityScreen> {
  final Sih2025SimpleService _sih2025Service = Sih2025SimpleService();

  bool _isLoading = false;
  Map<String, dynamic> _sustainabilityData = {};
  double _sustainabilityScore = 0.0;
  String _recommendations = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainability Scoring'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Environmental Impact Assessment',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Assess your farming practices and get sustainability scores with recommendations for eco-friendly improvements.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Farm Information Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Farm Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Crop Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Crop Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Rice',
                        'Wheat',
                        'Corn',
                        'Soybean',
                        'Cotton',
                        'Sugarcane',
                        'Potato',
                        'Tomato'
                      ].map((String crop) {
                        return DropdownMenuItem<String>(
                          value: crop,
                          child: Text(crop),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _sustainabilityData['crop_type'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Farm Size
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Farm Size (hectares)',
                        hintText: '5.0',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['farm_size'] =
                              double.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Delhi',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['location'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Water Usage
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Water Usage (liters per hectare)',
                        hintText: '5000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['water_usage'] =
                              double.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Irrigation Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Irrigation Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Drip', 'Sprinkler', 'Flood', 'Manual']
                          .map((String type) {
                        return DropdownMenuItem<String>(
                          value: type.toLowerCase(),
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _sustainabilityData['irrigation_type'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fertilizer Usage
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Fertilizer Usage (kg per hectare)',
                        hintText: '100',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['fertilizer_usage'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pesticide Usage
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Pesticide Usage (kg per hectare)',
                        hintText: '10',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['pesticide_usage'] = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Energy Usage
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Energy Usage (kWh per hectare)',
                        hintText: '200',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _sustainabilityData['energy_usage'] =
                              double.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _assessSustainability,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics),
                        label: Text(_isLoading
                            ? 'Assessing...'
                            : 'Assess Sustainability'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (_sustainabilityScore > 0) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sustainability Assessment Results',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Score Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getScoreColor(_sustainabilityScore)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _getScoreColor(_sustainabilityScore)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Sustainability Score',
                              style: TextStyle(
                                fontSize: 16,
                                color: _getScoreColor(_sustainabilityScore),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_sustainabilityScore * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 32,
                                color: _getScoreColor(_sustainabilityScore),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getScoreDescription(_sustainabilityScore),
                              style: TextStyle(
                                fontSize: 14,
                                color: _getScoreColor(_sustainabilityScore),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      if (_recommendations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Recommendations',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recommendations,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 0.8)
      return 'Excellent! Your farming practices are very sustainable.';
    if (score >= 0.6) return 'Good! There are some areas for improvement.';
    return 'Needs improvement. Consider implementing more sustainable practices.';
  }

  Future<void> _assessSustainability() async {
    if (_sustainabilityData['crop_type'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result =
          await _sih2025Service.assessSustainability(_sustainabilityData);

      setState(() {
        _sustainabilityScore = result['score'] ?? 0.0;
        _recommendations = result['recommendations'] ??
            'No specific recommendations available.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assessment failed: $e')),
      );
    }
  }
}
