import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/network_service.dart';

class AddCropScreen extends StatefulWidget {
  final String fieldId;

  const AddCropScreen({
    super.key,
    required this.fieldId,
  });

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _plantingDateController = TextEditingController();
  final _harvestingDateController = TextEditingController();
  final _yieldController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedPlantingDate;
  DateTime? _selectedHarvestingDate;

  // Common crops for quick selection
  final List<String> _commonCrops = [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Groundnut',
    'Sunflower',
    'Potato',
    'Tomato',
    'Onion',
    'Cabbage',
    'Cauliflower',
    'Brinjal',
    'Chilli',
    'Okra',
    'Cucumber',
    'Pumpkin',
    'Watermelon',
    'Mango',
    'Banana',
    'Papaya',
    'Coconut',
    'Apple',
    'Grapes'
  ];

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cropNameController.dispose();
    _plantingDateController.dispose();
    _harvestingDateController.dispose();
    _yieldController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPlantingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPlantingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedPlantingDate) {
      setState(() {
        _selectedPlantingDate = picked;
        _plantingDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _selectHarvestingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedHarvestingDate ??
          (_selectedPlantingDate ?? DateTime.now())
              .add(const Duration(days: 90)),
      firstDate: _selectedPlantingDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedHarvestingDate) {
      setState(() {
        _selectedHarvestingDate = picked;
        _harvestingDateController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cropData = {
        'crop_name': _cropNameController.text.trim(),
        'planting_date': _formatDateForAPI(_selectedPlantingDate!),
        if (_selectedHarvestingDate != null)
          'harvesting_date': _formatDateForAPI(_selectedHarvestingDate!),
        if (_yieldController.text.isNotEmpty)
          'yield_kg': double.parse(_yieldController.text),
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final response = await NetworkService.post(
        '${AppConfig.fieldManagementApiBaseUrl}/fields/${widget.fieldId}/crops',
        body: cropData,
        timeout: const Duration(seconds: 30),
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop added successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to save crop';
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
          'Add Crop',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCrop,
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
                _buildSectionHeader('Crop Information'),
                _buildCropInfoCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Planting & Harvesting'),
                _buildDatesCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Additional Information'),
                _buildAdditionalCard(),
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

  Widget _buildCropInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _commonCrops;
                }
                return _commonCrops.where((crop) => crop
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _cropNameController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Crop Name *',
                    hintText: 'Enter or select crop name',
                    prefixIcon: Icon(Icons.eco, color: Color(0xFF2E7D32)),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Crop name is required';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Select:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonCrops.take(12).map((crop) {
                return ActionChip(
                  label: Text(crop),
                  onPressed: () {
                    _cropNameController.text = crop;
                  },
                  backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _plantingDateController,
              decoration: const InputDecoration(
                labelText: 'Planting Date *',
                hintText: 'Select planting date',
                prefixIcon:
                    Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              readOnly: true,
              onTap: _selectPlantingDate,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Planting date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _harvestingDateController,
              decoration: const InputDecoration(
                labelText: 'Harvesting Date (Optional)',
                hintText: 'Select harvesting date',
                prefixIcon:
                    Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              readOnly: true,
              onTap: _selectHarvestingDate,
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
                      'You can add harvesting date and yield later when the crop is ready.',
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

  Widget _buildAdditionalCard() {
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
                labelText: 'Yield (kg)',
                hintText: 'Enter yield in kilograms',
                prefixIcon: Icon(Icons.scale, color: Color(0xFF2E7D32)),
                suffixText: 'kg',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(value) < 0) {
                    return 'Yield must be positive';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any additional notes about this crop',
                prefixIcon: Icon(Icons.note, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)),
                ),
              ),
              maxLines: 3,
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
        onPressed: _isLoading ? null : _saveCrop,
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
                'Add Crop to Field',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
