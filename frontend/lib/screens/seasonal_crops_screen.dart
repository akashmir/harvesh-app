import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crop/services/network_service.dart';
import 'package:crop/config/app_config.dart';
import 'package:crop/widgets/loading_widget.dart';
import 'package:crop/widgets/error_widget.dart';
import 'crop_schedule_detail_screen.dart';

class SeasonalCropsScreen extends StatefulWidget {
  final String? selectedSeason;

  const SeasonalCropsScreen({super.key, this.selectedSeason});

  @override
  State<SeasonalCropsScreen> createState() => _SeasonalCropsScreenState();
}

class _SeasonalCropsScreenState extends State<SeasonalCropsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _seasonsData;
  List<Map<String, dynamic>>? _cropsData;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedSeason = 'Kharif';

  final Map<String, Map<String, dynamic>> _seasonInfo = {
    'Kharif': {
      'name': 'Kharif',
      'description': 'Monsoon season crops',
      'months': 'June - November',
      'icon': Icons.water_drop,
      'color': Color(0xFF2196F3),
    },
    'Rabi': {
      'name': 'Rabi',
      'description': 'Winter season crops',
      'months': 'October - March',
      'icon': Icons.ac_unit,
      'color': Color(0xFF00BCD4),
    },
    'Zaid': {
      'name': 'Zaid',
      'description': 'Summer season crops',
      'months': 'March - June',
      'icon': Icons.wb_sunny,
      'color': Color(0xFFFF9800),
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.selectedSeason ?? 'Kharif';

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _loadSeasonalData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasonalData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load seasons data
      final seasonsResponse =
          await NetworkService.get(AppConfig.cropCalendarSeasonsEndpoint);
      if (seasonsResponse['success']) {
        _seasonsData = seasonsResponse['data'];
      }

      // Load crops for selected season
      await _loadCropsForSeason(_selectedSeason);

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCropsForSeason(String season) async {
    try {
      final response = await NetworkService.get(
          '${AppConfig.cropCalendarSeasonEndpoint}/$season');
      if (response['success']) {
        _cropsData = List<Map<String, dynamic>>.from(response['data']['crops']);
      } else {
        setState(() {
          _errorMessage =
              response['error'] ?? 'Failed to load crops for $season season';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  void _onSeasonChanged(String season) {
    setState(() {
      _selectedSeason = season;
    });
    _loadCropsForSeason(season);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const LoadingWidget()
          : _errorMessage != null
              ? CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadSeasonalData,
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildSeasonSelector(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildSeasonContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Seasonal Crops',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadSeasonalData,
        ),
      ],
    );
  }

  Widget _buildSeasonSelector() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _seasonInfo.entries.map((entry) {
          final seasonKey = entry.key;
          final seasonData = entry.value;
          final isSelected = seasonKey == _selectedSeason;
          final color = seasonData['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => _onSeasonChanged(seasonKey),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seasonData['icon'] as IconData,
                      color: isSelected ? color : Colors.white,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seasonData['name'] as String,
                      style: GoogleFonts.poppins(
                        color: isSelected ? color : Colors.white,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    Text(
                      seasonData['months'] as String,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? color.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSeasonContent() {
    final seasonData = _seasonInfo[_selectedSeason]!;
    final color = seasonData['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeasonHeader(seasonData, color),
        const SizedBox(height: 24),
        if (_cropsData != null && _cropsData!.isNotEmpty) ...[
          _buildCropsList(),
        ] else ...[
          _buildNoCropsCard(),
        ],
      ],
    );
  }

  Widget _buildSeasonHeader(Map<String, dynamic> seasonData, Color color) {
    final totalCrops = _cropsData?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  seasonData['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seasonData['name'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      seasonData['description'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Available Crops',
                totalCrops.toString(),
                Icons.eco,
                Colors.white.withOpacity(0.2),
                Colors.white,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Season Period',
                seasonData['months'] as String,
                Icons.calendar_today,
                Colors.white.withOpacity(0.2),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.9),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crops for $_selectedSeason Season',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cropsData!.length,
          itemBuilder: (context, index) {
            final crop = _cropsData![index];
            return _buildCropCard(crop);
          },
        ),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    final seasonData = _seasonInfo[_selectedSeason]!;
    final color = seasonData['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropScheduleDetailScreen(
                cropName:
                    crop['crop_key'] ?? crop['crop'].toString().toLowerCase(),
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop['crop'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${crop['growing_days']} days growing period',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planting:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  crop['planting_months'].join(', '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harvesting:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  crop['harvesting_months'].join(', '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFFFF9800),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCropsCard() {
    final seasonData = _seasonInfo[_selectedSeason]!;
    final color = seasonData['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(
            Icons.eco,
            size: 64,
            color: color.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Crops Available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No crops are available for the $_selectedSeason season in our database.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
