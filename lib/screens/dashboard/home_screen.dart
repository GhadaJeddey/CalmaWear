// screens/dashboard/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/sensor_data.dart';
import '../../models/alert.dart';
import '../chat/chat_screen.dart';
import '../planner/planner_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import './notifications_screen.dart';
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
  bool _showCrisisPopup = false;

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
    super.dispose();
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
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    switch (index) {
      case 0:
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

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = Provider.of<AuthProvider>(context).currentUser;
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final stressScore =
        monitoringProvider.currentSensorData?.stressScore ?? 0.0;

    // Show crisis popup if stress is above threshold
    if (stressScore > 70 && !_showCrisisPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showCrisisPopup = true);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(user?.name ?? 'User', user?.profileImageUrl),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildConnectedDevices(),
                        const SizedBox(height: 20),
                        _buildCurrentStatusCard(monitoringProvider),
                        const SizedBox(height: 20),
                        _buildLastTriggerCard(monitoringProvider),
                        const SizedBox(height: 20),
                        _buildVitalSignsSection(monitoringProvider),
                        const SizedBox(height: 20),
                        _buildWeeklyStressChart(monitoringProvider),
                        const SizedBox(height: 20),
                        _buildWeeklyHeartRateChart(monitoringProvider),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0066FF), width: 2),
              image: profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profileImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImageUrl == null
                ? ClipOval(
                    child: Container(
                      color: const Color(0xFFE3F2FD),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0066FF),
                        size: 28,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Welcome Back',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FF),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: const Color(0xFF0066FF),
              onPressed: () {
                context.pushNamed('notifications');
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
    final statusText = _getStatusText(stressScore);
    final statusColor = _getStatusColor(stressScore);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'Current\nStatus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0066FF),
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: ConcentricCirclesPainter(
                    percentage: (100 - stressScore) / 100,
                    animationValue: _pulseController.value,
                    color: statusColor,
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: Text(
                        '${(100 - stressScore).round()}%',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.warning_rounded,
              color: Colors.red.shade600,
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
      children: [
        _buildVitalSignCard(
          icon: Icons.favorite,
          label: 'Heart Rate',
          value: '${sensorData?.heartRate.round() ?? 0}',
          unit: 'Bpm',
          subValue: 'Avg: 94ms',
          status: _getHeartRateStatus(sensorData?.heartRate ?? 0),
          color: _getHeartRateColor(sensorData?.heartRate ?? 0),
        ),
        const SizedBox(height: 12),
        _buildVitalSignCard(
          icon: Icons.air,
          label: 'Breathing',
          value: '${sensorData?.breathingRate.round() ?? 0}',
          unit: 'Rpm',
          subValue: 'Respiratory rate',
          status: _getBreathingStatus(sensorData?.breathingRate ?? 0),
          color: _getBreathingColor(sensorData?.breathingRate ?? 0),
        ),
        const SizedBox(height: 12),
        _buildVitalSignCard(
          icon: Icons.directions_walk,
          label: 'Movement',
          value: _getMovementLevel(sensorData?.motion ?? 0),
          unit: '',
          subValue: '${sensorData?.motion.round() ?? 0}% activity',
          status: _getMovementStatus(sensorData?.motion ?? 0),
          color: _getMovementColor(sensorData?.motion ?? 0),
        ),
        const SizedBox(height: 12),
        _buildVitalSignCard(
          icon: Icons.volume_up,
          label: 'Noise',
          value: '${sensorData?.noiseLevel.round() ?? 0}',
          unit: 'dB',
          subValue: 'Environment sound',
          status: _getNoiseStatus(sensorData?.noiseLevel ?? 0),
          color: _getNoiseColor(sensorData?.noiseLevel ?? 0),
        ),
      ],
    );
  }

  Widget _buildVitalSignCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String subValue,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
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
                Text(
                  subValue,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStressChart(MonitoringProvider provider) {
    // Get last 7 days of alert counts
    final weeklyAlerts = _getWeeklyAlertCounts(provider.activeAlerts);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'Weekly Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
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
    // Get last 7 days of data
    final weeklyData = _getWeeklyAverages(provider.sensorHistory, false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'Weekly Heart Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
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
                color: const Color(0xFFFF9800),
                maxValue: 140,
                minValue: 60,
                showGradient: true,
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

  Widget _buildWeekDayLabels() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final dayIndex = (now.weekday - 7 + index + 1) % 7;
        return Text(
          days[dayIndex],
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
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
    final now = DateTime.now();
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
        // Use mock data if no real data available
        if (isStressScore) {
          weeklyAverages[i] = 30 + math.Random().nextDouble() * 40;
        } else {
          weeklyAverages[i] = 70 + math.Random().nextDouble() * 20;
        }
      }
    }

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

  Widget _buildConnectedDevices() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0066FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.watch, color: Color(0xFF0066FF), size: 32),
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
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device • 10 minutes ago',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Connected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Play relaxation sounds
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playing relaxation sounds...'),
                        backgroundColor: Color(0xFF0066FF),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'SOS Button',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
    if (stressScore < 50) return const Color(0xFF3B82F6);
    if (stressScore < 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getHeartRateStatus(double hr) {
    if (hr > 100) return 'High';
    if (hr > 80) return 'Elevated';
    return 'Normal';
  }

  Color _getHeartRateColor(double hr) {
    if (hr > 100) return const Color(0xFFEF4444);
    if (hr > 80) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getBreathingStatus(double br) {
    if (br > 35) return 'Fast';
    if (br > 25) return 'Elevated';
    return 'Normal';
  }

  Color _getBreathingColor(double br) {
    if (br > 35) return const Color(0xFFEF4444);
    if (br > 25) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _getMovementLevel(double motion) {
    if (motion > 70) return 'High';
    if (motion > 40) return 'Moderate';
    return 'Low';
  }

  String _getMovementStatus(double motion) {
    if (motion > 70) return 'Active';
    if (motion > 40) return 'Moving';
    return 'Resting';
  }

  Color _getMovementColor(double motion) {
    if (motion > 70) return const Color(0xFFEF4444);
    if (motion > 40) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  String _getNoiseStatus(double noise) {
    if (noise > 80) return 'Loud';
    if (noise > 60) return 'Moderate';
    return 'Quiet';
  }

  Color _getNoiseColor(double noise) {
    if (noise > 80) return const Color(0xFFEF4444);
    if (noise > 60) return const Color(0xFFF59E0B);
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

  LineChartPainter({
    required this.dataPoints,
    required this.color,
    this.maxValue = 100,
    this.minValue = 0,
    this.showGradient = false,
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

      for (int i = 1; i < points.length; i++) {
        gradientPath.lineTo(points[i].dx, points[i].dy);
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

    // Draw line
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
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

  BarChartPainter({
    required this.dataPoints,
    required this.color,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || maxValue == 0) return;

    final barWidth = size.width / (dataPoints.length * 2);
    final spacing = barWidth;

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
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue;
  }
}
