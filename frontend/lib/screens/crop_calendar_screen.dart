import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crop/services/network_service.dart';
import 'package:crop/config/app_config.dart';
import 'package:crop/widgets/loading_widget.dart';
import 'package:crop/widgets/error_widget.dart';
import 'monthly_calendar_screen.dart';
import 'seasonal_crops_screen.dart';

class CropCalendarScreen extends StatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _currentMonthData;
  List<Map<String, dynamic>>? _yearlyCalendar;
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

    _loadCalendarData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load current month data
      final currentResponse = await NetworkService.get(
        AppConfig.cropCalendarCurrentEndpoint,
        timeout: const Duration(seconds: 60),
      );
      if (currentResponse['success']) {
        _currentMonthData = currentResponse['data'];
      }

      // Load yearly calendar summary (simplified version)
      final yearlyResponse = await NetworkService.get(
        '${AppConfig.cropCalendarApiBaseUrl}/calendar/yearly/summary',
        timeout: const Duration(seconds: 60),
      );
      if (yearlyResponse['success']) {
        _yearlyCalendar = List<Map<String, dynamic>>.from(
            yearlyResponse['data']['yearly_summary']);
      }

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
                  onRetry: _loadCalendarData,
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
                          _buildCurrentMonthCard(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildYearlyCalendarPreview(),
                          const SizedBox(height: 24),
                          _buildSeasonalCrops(),
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
        'Crop Calendar',
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
          onPressed: _loadCalendarData,
        ),
      ],
    );
  }

  Widget _buildCurrentMonthCard() {
    if (_currentMonthData == null) return const SizedBox();

    final monthName = _currentMonthData!['month_name'];
    final plantingCrops = _currentMonthData!['planting_crops'] as List;
    final harvestingCrops = _currentMonthData!['harvesting_crops'] as List;

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
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$monthName Schedule',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Planting',
                plantingCrops.length.toString(),
                Icons.eco,
                const Color(0xFF81C784),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Harvesting',
                harvestingCrops.length.toString(),
                Icons.agriculture,
                const Color(0xFFFFB74D),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (plantingCrops.isNotEmpty) ...[
            Text(
              'Planting This Month:',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plantingCrops.take(3).map((crop) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    crop['crop'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Monthly View',
                'View crops by month',
                Icons.calendar_month,
                const Color(0xFF2196F3),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonthlyCalendarScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Seasonal Crops',
                'Crops by season',
                Icons.wb_sunny,
                const Color(0xFFFF9800),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SeasonalCropsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyCalendarPreview() {
    if (_yearlyCalendar == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yearly Calendar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: _yearlyCalendar!.take(6).map((monthData) {
              return _buildMonthPreview(monthData);
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MonthlyCalendarScreen(),
              ),
            ),
            child: Text(
              'View Complete Calendar',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthPreview(Map<String, dynamic> monthData) {
    final monthName = monthData['month_name'];
    final plantingCount = monthData['total_planting'];
    final harvestingCount = monthData['total_harvesting'];
    final isCurrentMonth = monthData['month'] == DateTime.now().month;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentMonth ? const Color(0xFF2E7D32).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentMonth
            ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              monthName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                color: isCurrentMonth
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF212121),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.eco, size: 16, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 4),
                Text(
                  plantingCount.toString(),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.agriculture,
                    size: 16, color: const Color(0xFFFF9800)),
                const SizedBox(width: 4),
                Text(
                  harvestingCount.toString(),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalCrops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seasonal Crops',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSeasonCard('Kharif', 'Monsoon', Icons.water_drop,
                  const Color(0xFF2196F3), [6, 7, 8, 9, 10, 11]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSeasonCard('Rabi', 'Winter', Icons.ac_unit,
                  const Color(0xFF00BCD4), [10, 11, 12, 1, 2, 3]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSeasonCard('Zaid', 'Summer', Icons.wb_sunny,
                  const Color(0xFFFF9800), [3, 4, 5, 6]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonCard(String season, String description, IconData icon,
      Color color, List<int> months) {
    final isCurrentSeason = months.contains(DateTime.now().month);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeasonalCropsScreen(selectedSeason: season),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(isCurrentSeason ? 0.2 : 0.1),
              color.withOpacity(isCurrentSeason ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentSeason ? color : color.withOpacity(0.2),
            width: isCurrentSeason ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              season,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212121),
              ),
            ),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            if (isCurrentSeason) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Current',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
