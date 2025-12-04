// screens/dashboard/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/planner_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/sensor_data.dart';
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
      monitoringProvider.toggleMonitoring(); // Start monitoring
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    switch (index) {
      case 0: // Home (current screen)
        break;
      case 1: // Planner
        context.go(Routes.planner);
        break;
      case 2: // Community
        context.go(Routes.community);

      case 3: // Chat
        context.go(Routes.chat);
        break;
      case 4: // Profile
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(user?.name ?? 'User'),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Current Status Card
                    _buildCurrentStatusCard(monitoringProvider),

                    const SizedBox(height: 20),

                    // Last Detected Trigger
                    _buildLastTriggerCard(monitoringProvider),

                    const SizedBox(height: 20),

                    // Vital Signs
                    _buildVitalSignsCards(monitoringProvider),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0066FF), width: 2),
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFFE3F2FD),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0066FF),
                  size: 28,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Greeting
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

          // Notification Bell
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

          const SizedBox(width: 8),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F4FF),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout),
              color: const Color(0xFF0066FF),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).signOut();
                Navigator.pushReplacementNamed(context, '/welcome');
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
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Concentric Circles with Percentage
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: ConcentricCirclesPainter(
                    percentage: stressScore / 100,
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
    final alerts = provider.activeAlerts;
    final lastAlert = alerts.isNotEmpty ? alerts.last : null;

    if (lastAlert == null || lastAlert.isResolved) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
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
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notification_important,
              color: Colors.red.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Detected Trigger',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastAlert.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTimeAgo(lastAlert.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.red.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsCards(MonitoringProvider provider) {
    final sensorData = provider.currentSensorData;

    return Column(
      children: [
        _buildVitalSignCard(
          icon: Icons.favorite,
          label: 'Heart Rate',
          value: '${sensorData?.heartRate.round() ?? 0} Bpm',
          subValue: 'Avg: 94ms',
          status: _getHeartRateStatus(sensorData?.heartRate ?? 0),
          color: _getHeartRateColor(sensorData?.heartRate ?? 0),
        ),
        const SizedBox(height: 12),
        _buildVitalSignCard(
          icon: Icons.air,
          label: 'Breathing',
          value: '${sensorData?.breathingRate.round() ?? 0} Rpm',
          subValue: 'Respiratory rate',
          status: _getBreathingStatus(sensorData?.breathingRate ?? 0),
          color: _getBreathingColor(sensorData?.breathingRate ?? 0),
        ),
        const SizedBox(height: 12),
        _buildVitalSignCard(
          icon: Icons.directions_walk,
          label: 'Movement',
          value: _getMovementLevel(sensorData?.motion ?? 0),
          subValue: '${sensorData?.motion.round() ?? 0}% activity',
          status: _getMovementStatus(sensorData?.motion ?? 0),
          color: _getMovementColor(sensorData?.motion ?? 0),
        ),
      ],
    );
  }

  Widget _buildVitalSignCard({
    required IconData icon,
    required String label,
    required String value,
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
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

    // Draw 5 concentric circles with animation
    for (int i = 5; i >= 1; i--) {
      final radius = maxRadius * (i / 5.0) * (0.9 + animationValue * 0.1);
      final opacity = (1.0 - (i - 1) / 5.0) * 0.15;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }

    // Draw filled center circle
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
