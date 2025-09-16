import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _yieldController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCrop = 'Rice';
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableCrops = [];
  Map<String, dynamic>? _profitResult;

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
    _loadCrops();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _yieldController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _yieldController.text = '5000.0';
    _areaController.text = '1.0';
    _priceController.text = '25.0';
  }

  Future<void> _loadCrops() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/crops',
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          final cropsData = response['data']['crops'] as Map<String, dynamic>;
          _availableCrops = cropsData.entries
              .map((e) => {
                    'name': e.key,
                    ...Map<String, dynamic>.from(e.value as Map),
                  })
              .toList();
        });
      }
    } catch (e) {
      // Handle error silently, use default crops
      setState(() {
        _availableCrops = [
          {'name': 'Rice', 'baseline_price': 25.0},
          {'name': 'Wheat', 'baseline_price': 22.0},
          {'name': 'Maize', 'baseline_price': 18.0},
          {'name': 'Cotton', 'baseline_price': 65.0},
          {'name': 'Tomato', 'baseline_price': 35.0},
        ];
      });
    }
  }

  Future<void> _calculateProfit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _profitResult = null;
      });

      final calculationData = {
        'crop_name': _selectedCrop,
        'yield_kg': double.parse(_yieldController.text),
        'area_hectares': double.parse(_areaController.text),
        'market_price': double.parse(_priceController.text),
      };

      final response = await NetworkService.post(
        '${AppConfig.marketPriceApiBaseUrl}/profit/calculate',
        body: calculationData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        setState(() {
          _profitResult = Map<String, dynamic>.from(response['data'] as Map);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profit calculation completed successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to calculate profit';
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

  Future<void> _getCurrentPrice() async {
    try {
      final response = await NetworkService.get(
        '${AppConfig.marketPriceApiBaseUrl}/price/current?crop=$_selectedCrop',
        timeout: const Duration(seconds: 10),
      );

      if (response['success']) {
        final priceData = Map<String, dynamic>.from(response['data'] as Map);
        setState(() {
          _priceController.text =
              priceData['current_price']?.toStringAsFixed(2) ?? '0.0';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profit Calculator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _calculateProfit,
            child: const Text(
              'Calculate',
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
                _buildSectionHeader('Crop Selection'),
                _buildCropSelectionCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Production Details'),
                _buildProductionCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Market Price'),
                _buildPriceCard(),
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
                _buildCalculateButton(),
                if (_profitResult != null) ...[
                  const SizedBox(height: 24),
                  _buildProfitResult(),
                ],
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
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildCropSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedCrop,
          decoration: const InputDecoration(
            labelText: 'Select Crop *',
            prefixIcon: Icon(Icons.eco, color: Color(0xFF4CAF50)),
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4CAF50)),
            ),
          ),
          items: _availableCrops.map((crop) {
            return DropdownMenuItem<String>(
              value: crop['name'],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(crop['name']),
                  Text(
                    '₹${crop['baseline_price']?.toStringAsFixed(0) ?? '0'}/kg avg',
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
              _selectedCrop = value!;
            });
            _getCurrentPrice();
          },
        ),
      ),
    );
  }

  Widget _buildProductionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _yieldController,
              decoration: const InputDecoration(
                labelText: 'Expected Yield (kg) *',
                hintText: 'Enter expected yield',
                prefixIcon: Icon(Icons.scale, color: Color(0xFF4CAF50)),
                suffixText: 'kg',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Yield is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Yield must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Field Area (Hectares) *',
                hintText: 'Enter field area',
                prefixIcon: Icon(Icons.straighten, color: Color(0xFF4CAF50)),
                suffixText: 'ha',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
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

  Widget _buildPriceCard() {
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
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Market Price (₹/kg) *',
                      hintText: 'Enter market price',
                      prefixIcon:
                          Icon(Icons.attach_money, color: Color(0xFF4CAF50)),
                      suffixText: '₹/kg',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _getCurrentPrice,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Get Current'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use current market price or enter your expected selling price for accurate profit calculation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _calculateProfit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
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
                'Calculate Profit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildProfitResult() {
    if (_profitResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.calculate,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Profit Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '₹${_profitResult!['net_profit']?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    'Net Profit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_profitResult!['profit_margin']?.toStringAsFixed(1) ?? '0.0'}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    'Profit Margin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Total Revenue',
                    '₹${_profitResult!['total_revenue']?.toStringAsFixed(0) ?? '0'}',
                    Icons.trending_up,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResultItem(
                    'Total Cost',
                    '₹${_profitResult!['total_cost']?.toStringAsFixed(0) ?? '0'}',
                    Icons.trending_down,
                    const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCostBreakdown(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This calculation includes all major production costs: seeds, fertilizers, pesticides, labor, machinery, irrigation, and other expenses.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostBreakdown() {
    final costBreakdown =
        _profitResult!['cost_breakdown'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost Breakdown (per hectare)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        ...costBreakdown.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₹${entry.value?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
