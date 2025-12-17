// screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/monitoring_provider.dart';
import '../../models/alert.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final monitoringProvider = Provider.of<MonitoringProvider>(context);

    // Filter out alerts older than yesterday and sort by date (newest first)
    final now = DateTime.now();
    final yesterdayStart = DateTime(now.year, now.month, now.day - 1);

    final recentAlerts =
        monitoringProvider.activeAlerts
            .where((alert) => alert.timestamp.isAfter(yesterdayStart))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group alerts by date
    final todayAlerts = _filterAlertsByDate(recentAlerts, DateTime.now());
    final yesterdayAlerts = _filterAlertsByDate(
      recentAlerts,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Notification',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'News 🔥',
                style: const TextStyle(
                  color: Color(0xFF0066FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
              for (var alert in recentAlerts) {
                monitoringProvider.resolveAlert(alert.id);
              }
            },
            child: const Text(
              'Mark all',
              style: TextStyle(
                color: Color(0xFF0066FF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Notifications List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (todayAlerts.isNotEmpty) ...[
                  _buildDateHeader('Today'),
                  const SizedBox(height: 12),
                  ...todayAlerts.map(
                    (alert) =>
                        _buildNotificationCard(alert, monitoringProvider),
                  ),
                ],

                if (yesterdayAlerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDateHeader('Yesterday'),
                  const SizedBox(height: 12),
                  ...yesterdayAlerts.map(
                    (alert) =>
                        _buildNotificationCard(alert, monitoringProvider),
                  ),
                ],

                if (recentAlerts.isEmpty) ...[
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll see notifications here when they arrive',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        date,
        style: const TextStyle(
          color: Color(0xFF0066FF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Alert alert, MonitoringProvider provider) {
    final icon = _getNotificationIcon(alert.type);
    final color = _getNotificationColor(alert.severity);
    final timeAgo = _getTimeAgo(alert.timestamp);
    final formattedDate = DateFormat('MMM dd, HH:mm').format(alert.timestamp);

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.removeResolvedAlert(alert.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isResolved ? Colors.white : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isResolved
                ? const Color(0xFFF0F0F0)
                : color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getNotificationTitle(alert.type),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              onPressed: () {
                provider.removeResolvedAlert(alert.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notification deleted'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  List<Alert> _filterAlertsByDate(List<Alert> alerts, DateTime date) {
    return alerts.where((alert) {
      final alertDate = DateTime(
        alert.timestamp.year,
        alert.timestamp.month,
        alert.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return alertDate == targetDate;
    }).toList();
  }

  IconData _getNotificationIcon(AlertType type) {
    switch (type) {
      case AlertType.heartRate:
        return Icons.favorite;
      case AlertType.breathing:
        return Icons.air;
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.stress:
        return Icons.sentiment_very_dissatisfied;
      case AlertType.noise:
        return Icons.volume_up;
      case AlertType.motion:
        return Icons.directions_walk;
    }
  }

  Color _getNotificationColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return const Color(0xFF3B82F6);
      case AlertSeverity.medium:
        return const Color(0xFFF59E0B);
      case AlertSeverity.high:
        return const Color(0xFFEF4444);
      case AlertSeverity.critical:
        return const Color(0xFF9333EA);
    }
  }

  String _getNotificationTitle(AlertType type) {
    switch (type) {
      case AlertType.heartRate:
        return 'Heart Rate Alert';
      case AlertType.breathing:
        return 'Breathing Alert';
      case AlertType.temperature:
        return 'Temperature Alert';
      case AlertType.stress:
        return 'Stress Alert';
      case AlertType.noise:
        return 'Noise Alert';
      case AlertType.motion:
        return 'Movement Alert';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
