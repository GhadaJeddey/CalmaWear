// screens/dashboard/home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/sensor_data.dart';
import '../../models/alert.dart';
import '../../services/realtime_sensor_service.dart';
import '../../services/vest_bluetooth_service.dart';
import '../../services/weekly_stats_service.dart';
import 'dart:math' as math;
import '../../router/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 0;
  bool _isInitializing = true;
  late AnimationController _pulseController;
  bool _showCrisisPopup = true;
  Timer? _popupBlockerTimer;
  // Weekly stats service for Firestore data
  final WeeklyStatsService _weeklyStatsService = WeeklyStatsService();

  // Cache weekly data from Firestore (update every 5 min)
  DateTime? _lastWeeklyUpdateTime;
  List<double>? _cachedWeeklyHeartRate;
  List<double>? _cachedWeeklyBreathing;
  List<double>? _cachedWeeklyMovement;
  List<double>? _cachedWeeklyNoise;
  List<double>? _cachedWeeklyStress;

  bool _isLoadingWeeklyData = false;
  List<double>? _cachedWeeklyAlerts;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initializeProviders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _popupBlockerTimer?.cancel();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.go(Routes.planner);
        break;
      case 2:
        context.go(Routes.community);
        break;
      case 3:
        context.go(Routes.chat);
        break;
      case 4:
        context.go(Routes.profile);
        break;
    }
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null && user.id != null) {
      final plannerProvider = Provider.of<PlannerProvider>(
        context,
        listen: false,
      );
      await plannerProvider.initialize(user.id!);

      final monitoringProvider = Provider.of<MonitoringProvider>(
        context,
        listen: false,
      );
      monitoringProvider.initializeMonitoring();
      monitoringProvider.toggleMonitoring();

      // Load weekly stats from Firestore
      await _loadWeeklyStats();
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  // Load weekly stats from Firestore
  Future<void> _loadWeeklyStats() async {
    final now = DateTime.now();
    final shouldUpdate =
        _lastWeeklyUpdateTime == null ||
        now.difference(_lastWeeklyUpdateTime!).inMinutes >= 5;

    if (!shouldUpdate &&
        _cachedWeeklyHeartRate != null &&
        _cachedWeeklyAlerts != null) {
      // Check alerts too
      return;
    }

    if (_isLoadingWeeklyData) return;

    setState(() => _isLoadingWeeklyData = true);

    try {
      // Load weekly stats
      final weeklyStats = await _weeklyStatsService.getWeeklyStatsAsLists();

      // Load weekly alerts - ADD THIS
      final weeklyAlerts = await _weeklyStatsService.getWeeklyAlertCounts();

      if (mounted) {
        setState(() {
          _cachedWeeklyHeartRate = weeklyStats['maxHeartRate'];
          _cachedWeeklyBreathing = weeklyStats['avgBreathingRate'];
          _cachedWeeklyMovement = weeklyStats['maxMovement'];
          _cachedWeeklyNoise = weeklyStats['maxNoise'];
          _cachedWeeklyAlerts = weeklyAlerts; // <-- STORE ALERTS
          _lastWeeklyUpdateTime = now;
          _isLoadingWeeklyData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading weekly stats: $e');
      if (mounted) {
        setState(() => _isLoadingWeeklyData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = Provider.of<AuthProvider>(context).currentUser;
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final stressScore =
        monitoringProvider.currentSensorData?.stressScore ?? 0.0;

    if (stressScore > 75 && _popupBlockerTimer == null) {
      // Alert just started - hide popup and start 5-minute blocker timer
      setState(() => _showCrisisPopup = false);

      _popupBlockerTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) {
          setState(() {
            _showCrisisPopup = true; // Show popup again after 5 minutes
            _popupBlockerTimer = null; // Reset timer for next alert
          });
        }
      });

      print('🚨 Alert detected - Hiding popup for 5 minutes');
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(user?.name ?? 'User', user?.profileImageUrl),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildConnectedDevices(),
                        const SizedBox(height: 24),
                        _buildCurrentStatusCard(monitoringProvider),
                        const SizedBox(height: 24),
                        _buildLastTriggerCard(monitoringProvider),
                        const SizedBox(height: 24),
                        _buildVitalSignsSection(monitoringProvider),
                        const SizedBox(height: 24),
                        _buildWeeklyStressChart(monitoringProvider),
                        const SizedBox(height: 24),
                        _buildWeeklyHeartRateChart(monitoringProvider),
                        const SizedBox(height: 24),
                        _buildWeeklyBreathingChart(monitoringProvider),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildWeeklyMovementChart(
                                monitoringProvider,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildWeeklyNoiseChart(monitoringProvider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showCrisisPopup) _buildCrisisPopup(monitoringProvider),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildHeader(String userName, String? profileImageUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF0066FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF0066FF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: profileImageUrl != null
                ? ClipOval(
                    child: Image.network(profileImageUrl, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Text(
            userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFCAD6FF).withOpacity(0.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: const Color.fromARGB(255, 43, 43, 43),
              padding: EdgeInsets.zero,
              onPressed: () {
                context.go('/home/notifications');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard(MonitoringProvider provider) {
    final sensorData = provider.currentSensorData;
    final stressScore = sensorData?.stressScore ?? 0.0;
    // Display stress score directly (100% = very stressed, 0% = very calm)
    final statusText = _getStatusText(stressScore);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8ECFF), Color.fromRGBO(255, 255, 255, 1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current\nStatus',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0066FF),
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Oval progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative ovals
              Container(
                width: 280,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(140),
                  border: Border.all(
                    color: const Color(0xFF9BA9FF).withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 240,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(120),
                  border: Border.all(
                    color: const Color(0xFF9BA9FF).withOpacity(0.6),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 200,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFF9BA9FF).withOpacity(0.9),
                    width: 2,
                  ),
                ),
              ),
              // Main progress oval
              SizedBox(
                width: 160,
                height: 200,
                child: CustomPaint(
                  painter: OvalProgressPainter(
                    percentage: stressScore / 100,
                    color: const Color(0xFF9BA9FF).withOpacity(0.3),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${stressScore.round()}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 0, 0, 0),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          statusText.toLowerCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 0, 0, 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastTriggerCard(MonitoringProvider provider) {
    final sensorData = provider.currentSensorData;
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (sensorData == null || user == null) {
      return const SizedBox();
    }

    // Only show if stress score is above threshold (75)
    if (sensorData.stressScore <= 75) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFEF4444).withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEF4444).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Detected Alert',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.crisis_alert,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stress Alert',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sensorData.stressScore.round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeAgo(sensorData.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsSection(MonitoringProvider provider) {
    final sensorData = provider.currentSensorData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Vital Signs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildVitalSignCard(
              icon: Icons.favorite_rounded,
              label: 'Heart Rate',
              value: '${sensorData?.heartRate.round() ?? 0}',
              unit: 'BPM',
              status: _getHeartRateStatus(sensorData?.heartRate ?? 0),
              color: Color(0xFF0066FF),
            ),
            _buildVitalSignCard(
              icon: Icons.air_rounded,
              label: 'Breathing',
              value: '${sensorData?.breathingRate.round() ?? 0}',
              unit: 'RPM',
              status: _getBreathingStatus(sensorData?.breathingRate ?? 0),
              color: Color(0xFF0066FF),
            ),
            _buildVitalSignCard(
              icon: Icons.directions_walk_rounded,
              label: 'Movement',
              value: '${sensorData?.motion.round() ?? 0}',
              unit: '%',
              status: _getMovementStatus(sensorData?.motion ?? 0),
              color: Color(0xFF0066FF),
            ),
            _buildVitalSignCard(
              icon: Icons.volume_up_rounded,
              label: 'Noise',
              value: '${sensorData?.noiseLevel.round() ?? 0}',
              unit: 'dB',
              status: _getNoiseStatus(sensorData?.noiseLevel ?? 0),
              color: Color(0xFF0066FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalSignCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Normal'
                      ? Color(0xFF10B981).withOpacity(0.1)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: status == 'Normal' ? Color(0xFF10B981) : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStressChart(MonitoringProvider provider) {
    // Get weekly alert counts from Firestore
    final weeklyAlerts = _cachedWeeklyAlerts ?? List<double>.filled(7, 0.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFFF5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEF4444).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crisis history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${weeklyAlerts.reduce((a, b) => a + b).toInt()} Total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: BarChartPainter(
                dataPoints: weeklyAlerts,
                color: const Color(0xFFD32F2F),
                maxValue: weeklyAlerts.reduce((a, b) => a > b ? a : b) + 2,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWeeklyHeartRateChart(MonitoringProvider provider) {
    // Load weekly stats if needed
    if (_cachedWeeklyHeartRate == null || _isLoadingWeeklyData) {
      _loadWeeklyStats();
    }

    // Get last 7 days of data from Firestore cache
    final weeklyData =
        _cachedWeeklyHeartRate ??
        List<double>.filled(7, 75.0); // Default baseline

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8ECFF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0066FF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heart Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFCAD6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: LineChartPainter(
                dataPoints: weeklyData,
                color: const Color(0xFF0066FF),
                maxValue: 140,
                minValue: 60,
                showGradient: true,
                thresholdValue: 100,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreathingChart(MonitoringProvider provider) {
    // Load weekly stats if needed
    if (_cachedWeeklyBreathing == null || _isLoadingWeeklyData) {
      _loadWeeklyStats();
    }

    // Get last 7 days of breathing data from Firestore cache
    final weeklyData =
        _cachedWeeklyBreathing ??
        List<double>.filled(7, 18.0); // Default baseline

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8ECFF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0066FF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Breathing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFCAD6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RPM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: LineChartPainter(
                dataPoints: weeklyData,
                color: const Color(0xFF0066FF),
                maxValue: 45,
                minValue: 15,
                showGradient: true,
                thresholdValue: 30,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWeeklyMovementChart(MonitoringProvider provider) {
    // Load weekly stats if needed
    if (_cachedWeeklyMovement == null || _isLoadingWeeklyData) {
      _loadWeeklyStats();
    }

    // Get last 7 days of maximum movement values from Firestore cache
    final weeklyMaxValues =
        _cachedWeeklyMovement ??
        List<double>.filled(7, 30.0); // Default baseline

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFCAD6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0066FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Movement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: CompactBarChartPainter(
                dataPoints: weeklyMaxValues,
                color: const Color(0xFF0066FF),
                maxValue: 100,
                thresholdValue: 70,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          _buildCompactWeekDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWeeklyNoiseChart(MonitoringProvider provider) {
    // Load weekly stats if needed
    if (_cachedWeeklyNoise == null || _isLoadingWeeklyData) {
      _loadWeeklyStats();
    }

    // Get last 7 days of maximum noise values from Firestore cache
    final weeklyMaxValues =
        _cachedWeeklyNoise ?? List<double>.filled(7, 45.0); // Default baseline

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFCAD6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0066FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Noise',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: CompactBarChartPainter(
                dataPoints: weeklyMaxValues,
                color: const Color(0xFF0066FF),
                maxValue: 120,
                thresholdValue: 80,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          _buildCompactWeekDayLabels(),
        ],
      ),
    );
  }

  Widget _buildWeekDayLabels() {
    final now = DateTime.now();
    // We display the last 7 days, oldest (6 days ago) on the left,
    // newest (today) on the right, to match the weekly stats order.
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        // For index 0..6, map to dates: 6 days ago .. today
        final date = now.subtract(Duration(days: 6 - index));
        final dayLabel = days[date.weekday - 1];
        return Text(
          dayLabel,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        );
      }),
    );
  }

  Widget _buildCompactWeekDayLabels() {
    final now = DateTime.now();
    // Compact labels for the last 7 days, oldest on the left, newest on the right
    final List<String> days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        final dayLabel = days[date.weekday - 1];
        return Text(
          dayLabel,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        );
      }),
    );
  }

  List<double> _getWeeklyAverages(
    List<SensorData> history,
    bool isStressScore,
  ) {
    // WEEKLY GRAPHS: Update only every 5 minutes (not every 3 seconds)
    // This keeps weekly graphs stable and prevents constant recalculation
    final now = DateTime.now();
    final shouldUpdate =
        _lastWeeklyUpdateTime == null ||
        now.difference(_lastWeeklyUpdateTime!).inMinutes >= 5;

    // Return cached data if available and still valid
    if (!shouldUpdate) {
      if (isStressScore && _cachedWeeklyStress != null) {
        return _cachedWeeklyStress!;
      } else if (!isStressScore && _cachedWeeklyHeartRate != null) {
        return _cachedWeeklyHeartRate!;
      }
    }

    // Recalculate weekly averages
    final weeklyAverages = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);

    // Group data by day of week (last 7 days)
    for (final data in history) {
      final daysDiff = now.difference(data.timestamp).inDays;
      if (daysDiff < 7) {
        final index = 6 - daysDiff; // Most recent day at index 6
        if (isStressScore) {
          weeklyAverages[index] += data.stressScore;
        } else {
          weeklyAverages[index] += data.heartRate;
        }
        counts[index]++;
      }
    }

    // Calculate averages
    for (int i = 0; i < 7; i++) {
      if (counts[i] > 0) {
        weeklyAverages[i] = weeklyAverages[i] / counts[i];
      } else {
        // Use stable mock data (not random)
        if (isStressScore) {
          weeklyAverages[i] = 35.0; // Static value for empty days
        } else {
          weeklyAverages[i] = 75.0; // Static baseline heart rate
        }
      }
    }

    // Cache the result
    if (isStressScore) {
      _cachedWeeklyStress = weeklyAverages;
    } else {
      _cachedWeeklyHeartRate = weeklyAverages;
    }
    _lastWeeklyUpdateTime = now;

    return weeklyAverages;
  }

  List<double> _getWeeklyAlertCounts(List<Alert> alerts) {
    final now = DateTime.now();
    final weeklyCounts = List<double>.filled(7, 0.0);

    // Count alerts by day of week (last 7 days)
    for (final alert in alerts) {
      final daysDiff = now.difference(alert.timestamp).inDays;
      if (daysDiff < 7) {
        final index = 6 - daysDiff; // Most recent day at index 6
        weeklyCounts[index]++;
      }
    }

    return weeklyCounts;
  }

  List<double> _getWeeklyBreathingAverages(List<SensorData> history) {
    // Return cached data if still valid
    final now = DateTime.now();
    if (_lastWeeklyUpdateTime != null &&
        now.difference(_lastWeeklyUpdateTime!).inMinutes < 5 &&
        _cachedWeeklyBreathing != null) {
      return _cachedWeeklyBreathing!;
    }

    final weeklyAverages = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);

    // Group data by day of week (last 7 days)
    for (final data in history) {
      final daysDiff = now.difference(data.timestamp).inDays;
      if (daysDiff < 7) {
        final index = 6 - daysDiff;
        weeklyAverages[index] += data.breathingRate;
        counts[index]++;
      }
    }

    // Calculate averages
    for (int i = 0; i < 7; i++) {
      if (counts[i] > 0) {
        weeklyAverages[i] = weeklyAverages[i] / counts[i];
      } else {
        weeklyAverages[i] = 18.0; // Static baseline
      }
    }

    _cachedWeeklyBreathing = weeklyAverages;
    return weeklyAverages;
  }

  List<double> _getWeeklyMaxValues(List<SensorData> history, String type) {
    // Return cached data if still valid
    final now = DateTime.now();
    if (_lastWeeklyUpdateTime != null &&
        now.difference(_lastWeeklyUpdateTime!).inMinutes < 5) {
      if (type == 'motion' && _cachedWeeklyMovement != null) {
        return _cachedWeeklyMovement!;
      } else if (type == 'noise' && _cachedWeeklyNoise != null) {
        return _cachedWeeklyNoise!;
      }
    }

    final weeklyMaxValues = List<double>.filled(7, 0.0);

    // Group data by day of week and find max (last 7 days)
    for (final data in history) {
      final daysDiff = now.difference(data.timestamp).inDays;
      if (daysDiff < 7) {
        final index = 6 - daysDiff;
        final value = type == 'motion' ? data.motion : data.noiseLevel;
        if (value > weeklyMaxValues[index]) {
          weeklyMaxValues[index] = value;
        }
      }
    }

    // Fill empty days with static baseline
    for (int i = 0; i < 7; i++) {
      if (weeklyMaxValues[i] == 0.0) {
        weeklyMaxValues[i] = type == 'motion' ? 30.0 : 45.0;
      }
    }

    // Cache the result
    if (type == 'motion') {
      _cachedWeeklyMovement = weeklyMaxValues;
    } else {
      _cachedWeeklyNoise = weeklyMaxValues;
    }

    return weeklyMaxValues;
  }

  Widget _buildConnectedDevices() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(209, 180, 197, 254),
            Color.fromARGB(174, 202, 214, 255),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B9FFF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CalmaWear Vest',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device • Active',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0066FF).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text(
              'Connected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisPopup(MonitoringProvider provider) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are just a click away!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click SOS button to play the relaxation sounds',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'CRISIS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  setState(() => _showCrisisPopup = false);
                },
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(double stressScore) {
    if (stressScore < 30) return 'calm';
    if (stressScore < 50) return 'relaxed';
    if (stressScore < 70) return 'alert';
    return 'stressed';
  }

  Color _getStatusColor(double stressScore) {
    if (stressScore < 30) return const Color(0xFF10B981);
    if (stressScore < 50) return const Color(0xFF0066FF);
    if (stressScore < 70) return const Color(0xFF0066FF);
    return const Color(0xFFEF4444);
  }

  String _getHeartRateStatus(double hr) {
    if (hr > 100) return 'High';
    if (hr > 80) return 'Elevated';
    return 'Normal';
  }

  Color _getHeartRateColor(double hr) {
    if (hr > 100) return const Color(0xFFEF4444);
    if (hr > 80) return const Color(0xFF0066FF);
    return const Color(0xFF10B981);
  }

  String _getBreathingStatus(double br) {
    if (br > 35) return 'Fast';
    if (br > 25) return 'Elevated';
    return 'Normal';
  }

  Color _getBreathingColor(double br) {
    if (br > 35) return const Color(0xFFEF4444);
    if (br > 25) return const Color(0xFF0066FF);
    return const Color(0xFF10B981);
  }

  String _getMovementStatus(double motion) {
    if (motion > 70) return 'High';
    if (motion > 50) return 'Active';
    return 'Normal';
  }

  String _getNoiseStatus(double noise) {
    if (noise > 80) return 'Loud';
    if (noise > 60) return 'Moderate';
    return 'Quiet';
  }

  Color _getNoiseColor(double noise) {
    if (noise > 80) return const Color(0xFFEF4444);
    if (noise > 60) return const Color(0xFF0066FF);
    return const Color(0xFF10B981);
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class ConcentricCirclesPainter extends CustomPainter {
  final double percentage;
  final double animationValue;
  final Color color;

  ConcentricCirclesPainter({
    required this.percentage,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 5; i >= 1; i--) {
      final radius = maxRadius * (i / 5.0) * (0.9 + animationValue * 0.1);
      final opacity = (1.0 - (i - 1) / 5.0) * 0.15;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    final centerPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius * 0.6, centerPaint);
  }

  @override
  bool shouldRepaint(ConcentricCirclesPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.animationValue != animationValue;
  }
}

// Line Chart Painter for weekly graphs
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  final double maxValue;
  final double minValue;
  final bool showGradient;
  final double? thresholdValue;

  LineChartPainter({
    required this.dataPoints,
    required this.color,
    this.maxValue = 100,
    this.minValue = 0,
    this.showGradient = false,
    this.thresholdValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    // Calculate points
    final spacing = size.width / (dataPoints.length - 1);
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue =
          (dataPoints[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    // Draw gradient fill if enabled
    if (showGradient && points.isNotEmpty) {
      final gradientPath = Path();
      gradientPath.moveTo(points.first.dx, size.height);
      gradientPath.lineTo(points.first.dx, points.first.dy);

      // Create smooth curve for gradient
      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          next.dy,
        );
        gradientPath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          next.dx,
          next.dy,
        );
      }

      gradientPath.lineTo(points.last.dx, size.height);
      gradientPath.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(gradientPath, gradientPaint);
    }

    // Draw smooth curve line
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);

      // Create smooth curve using cubic bezier
      for (int i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) / 2,
          next.dy,
        );
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          next.dx,
          next.dy,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw threshold line if provided
    if (thresholdValue != null) {
      final normalizedThreshold =
          (thresholdValue! - minValue) / (maxValue - minValue);
      final thresholdY = size.height - (normalizedThreshold * size.height);

      final thresholdPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const dashWidth = 5;
      const dashSpace = 5;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, thresholdY),
          Offset(startX + dashWidth, thresholdY),
          thresholdPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue;
  }
}

// Bar Chart Painter for Weekly Alerts
class BarChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  final double maxValue;
  final double? thresholdValue;

  BarChartPainter({
    required this.dataPoints,
    required this.color,
    required this.maxValue,
    this.thresholdValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || maxValue == 0) return;

    final barWidth = size.width / (dataPoints.length * 2);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw bars
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i * 2 + 0.5) * barWidth;
      final normalizedValue = dataPoints[i] / maxValue;
      final barHeight = normalizedValue * size.height;
      final y = size.height - barHeight;

      // Bar gradient
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.7)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);

      // Draw count label on top of bar if > 0
      if (dataPoints[i] > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: dataPoints[i].toInt().toString(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + (barWidth - textPainter.width) / 2, y - 18),
        );
      }
    }

    // Draw threshold line if provided
    if (thresholdValue != null && maxValue > 0) {
      final normalizedThreshold = thresholdValue! / maxValue;
      final thresholdY = size.height - (normalizedThreshold * size.height);

      final thresholdPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const dashWidth = 5;
      const dashSpace = 5;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, thresholdY),
          Offset(startX + dashWidth, thresholdY),
          thresholdPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue;
  }
}

// Circular Progress Painter for Status Card
class CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

// Compact Bar Chart Painter for Movement and Noise
class CompactBarChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;
  final double maxValue;
  final double? thresholdValue;

  CompactBarChartPainter({
    required this.dataPoints,
    required this.color,
    required this.maxValue,
    this.thresholdValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || maxValue == 0) return;

    final barWidth = (size.width / dataPoints.length) * 0.6;
    final spacing = (size.width / dataPoints.length);

    // Draw bars
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i * spacing) + (spacing - barWidth) / 2;
      final normalizedValue = dataPoints[i] / maxValue;
      final barHeight =
          normalizedValue * size.height * 0.85; // Use 85% of height
      final y = size.height - barHeight;

      // Bar with rounded corners
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.6)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(barRect, barPaint);
    }

    // Draw threshold line if provided
    if (thresholdValue != null && maxValue > 0) {
      final normalizedThreshold = thresholdValue! / maxValue;
      final thresholdY =
          size.height - (normalizedThreshold * size.height * 0.85);

      final thresholdPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const dashWidth = 5;
      const dashSpace = 5;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, thresholdY),
          Offset(startX + dashWidth, thresholdY),
          thresholdPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CompactBarChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue;
  }
}

// Add this custom painter class at the end of your file with the other painters
class OvalProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;

  OvalProgressPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fillHeight = size.height * percentage;
    final fillRect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );

    // Draw the fill with clipping to create oval shape
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(fillRect, paint);
    canvas.restore();

    // Draw the oval border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(OvalProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
