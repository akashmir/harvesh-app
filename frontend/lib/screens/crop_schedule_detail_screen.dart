import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crop/services/network_service.dart';
import 'package:crop/config/app_config.dart';
import 'package:crop/widgets/loading_widget.dart';
import 'package:crop/widgets/error_widget.dart';

class CropScheduleDetailScreen extends StatefulWidget {
  final String cropName;

  const CropScheduleDetailScreen({super.key, required this.cropName});

  @override
  State<CropScheduleDetailScreen> createState() =>
      _CropScheduleDetailScreenState();
}

class _CropScheduleDetailScreenState extends State<CropScheduleDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _cropData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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

    _loadCropData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCropData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await NetworkService.get(
          '${AppConfig.cropCalendarCropEndpoint}/${widget.cropName}');
      if (response['success']) {
        _cropData = response['data'];
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load crop data';
        });
      }
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
                  onRetry: _loadCropData,
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCropHeader(),
                          const SizedBox(height: 24),
                          _buildScheduleCards(),
                          const SizedBox(height: 24),
                          _buildSeasonalInfo(),
                          const SizedBox(height: 24),
                          _buildGrowingInfo(),
                          const SizedBox(height: 100),
                        ],
                      ),
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
        _cropData?['crop'] ?? 'Crop Details',
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
          onPressed: _loadCropData,
        ),
      ],
    );
  }

  Widget _buildCropHeader() {
    if (_cropData == null) return const SizedBox();

    final cropName = _cropData!['crop'];
    final description = _cropData!['description'];
    final isPlantingNow = _cropData!['is_planting_now'] ?? false;
    final isHarvestingNow = _cropData!['is_harvesting_now'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
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
                child: const Icon(
                  Icons.eco,
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
                      cropName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
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
              if (isPlantingNow) ...[
                _buildStatusBadge(
                    'Planting Now', Icons.eco, const Color(0xFF81C784)),
                const SizedBox(width: 8),
              ],
              if (isHarvestingNow) ...[
                _buildStatusBadge('Harvesting Now', Icons.agriculture,
                    const Color(0xFFFFB74D)),
                const SizedBox(width: 8),
              ],
              if (!isPlantingNow && !isHarvestingNow) ...[
                _buildStatusBadge(
                    'Dormant Season', Icons.pause, const Color(0xFF9E9E9E)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCards() {
    if (_cropData == null) return const SizedBox();

    final plantingMonths = _cropData!['planting_months'] as List;
    final harvestingMonths = _cropData!['harvesting_months'] as List;

    return Row(
      children: [
        Expanded(
          child: _buildScheduleCard(
            'Planting Season',
            plantingMonths,
            Icons.eco,
            const Color(0xFF4CAF50),
            'Best months to plant',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScheduleCard(
            'Harvesting Season',
            harvestingMonths,
            Icons.agriculture,
            const Color(0xFFFF9800),
            'Best months to harvest',
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    String title,
    List<dynamic> months,
    IconData icon,
    Color color,
    String subtitle,
  ) {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: months.map((month) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  month,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalInfo() {
    if (_cropData == null) return const SizedBox();

    final seasons = _cropData!['seasons'] as List;

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
              const Icon(Icons.wb_sunny, color: Color(0xFFFF9800), size: 20),
              const SizedBox(width: 8),
              Text(
                'Suitable Seasons',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seasons.map((season) {
              Color seasonColor;
              IconData seasonIcon;
              String seasonDescription;

              switch (season) {
                case 'Kharif':
                  seasonColor = const Color(0xFF2196F3);
                  seasonIcon = Icons.water_drop;
                  seasonDescription = 'Monsoon (Jun-Nov)';
                  break;
                case 'Rabi':
                  seasonColor = const Color(0xFF00BCD4);
                  seasonIcon = Icons.ac_unit;
                  seasonDescription = 'Winter (Oct-Mar)';
                  break;
                case 'Zaid':
                  seasonColor = const Color(0xFFFF9800);
                  seasonIcon = Icons.wb_sunny;
                  seasonDescription = 'Summer (Mar-Jun)';
                  break;
                default:
                  seasonColor = const Color(0xFF9E9E9E);
                  seasonIcon = Icons.help;
                  seasonDescription = season;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: seasonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: seasonColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(seasonIcon, color: seasonColor, size: 16),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: seasonColor,
                          ),
                        ),
                        Text(
                          seasonDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: seasonColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowingInfo() {
    if (_cropData == null) return const SizedBox();

    final growingDays = _cropData!['growing_days'];

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
              const Icon(Icons.schedule, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                'Growing Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Growing Period',
                  '$growingDays days',
                  Icons.timeline,
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Crop Type',
                  _getCropType(growingDays),
                  Icons.category,
                  const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF2E7D32),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getGrowingTip(growingDays),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF2E7D32),
                      fontStyle: FontStyle.italic,
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

  Widget _buildInfoItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getCropType(int growingDays) {
    if (growingDays <= 90) return 'Short Duration';
    if (growingDays <= 180) return 'Medium Duration';
    if (growingDays <= 365) return 'Long Duration';
    return 'Perennial';
  }

  String _getGrowingTip(int growingDays) {
    if (growingDays <= 90) {
      return 'Quick-growing crop. Monitor closely for pests and diseases.';
    } else if (growingDays <= 180) {
      return 'Medium-duration crop. Regular monitoring and maintenance required.';
    } else if (growingDays <= 365) {
      return 'Long-duration crop. Requires consistent care and monitoring.';
    } else {
      return 'Perennial crop. Long-term investment with year-round care.';
    }
  }
}
