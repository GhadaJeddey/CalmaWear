import 'sensor_data.dart';

enum AlertType { heartRate, breathing, temperature, stress, noise, motion }

enum AlertSeverity { low, medium, high, critical }

class Alert {
  final String id;
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final SensorData? sensorData;
  bool isResolved;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.sensorData,
    this.isResolved = false,
  });

  // Couleur basée sur la sévérité
  String get severityColor {
    switch (severity) {
      case AlertSeverity.low:
        return '4CAF50'; // Vert
      case AlertSeverity.medium:
        return 'FF9800'; // Orange
      case AlertSeverity.high:
        return 'F44336'; // Rouge
      case AlertSeverity.critical:
        return 'D32F2F'; // Rouge foncé
    }
  }

  // Icône basée sur le type
  String get typeIcon {
    switch (type) {
      case AlertType.heartRate:
        return '❤️';
      case AlertType.breathing: // 👈 NOUVEAU
        return '🌬️';
      case AlertType.temperature:
        return '🌡️';
      case AlertType.stress:
        return '😰';
      case AlertType.noise:
        return '🔊';
      case AlertType.motion:
        return '🌀';
    }
  }
}
