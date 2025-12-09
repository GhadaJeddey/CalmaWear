import 'dart:async';
import '../models/sensor_data.dart';
import '../models/alert.dart';

class MonitoringService {
  StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  StreamController<Alert> _alertController =
      StreamController<Alert>.broadcast();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  double _stressThreshold = 70.0; // Default threshold

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<Alert> get alertStream => _alertController.stream;

  // Update stress threshold
  void updateStressThreshold(double threshold) {
    _stressThreshold = threshold;
  }

  // Démarrer le monitoring simulé
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Génère des données toutes les 3 secondes
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final sensorData = _generateMockSensorData();
      _sensorDataController.add(sensorData);

      // Vérifier les alertes
      _checkForAlerts(sensorData);
    });
  }

  // Arrêter le monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
  }

  // Générer des données de capteurs simulées
  SensorData _generateMockSensorData() {
    final now = DateTime.now();

    // Variations réalistes pour simuler un enfant
    double baseHeartRate = 70 + (DateTime.now().second % 30); // 70-100 BPM
    double baseTemperature =
        36.5 + (DateTime.now().minute % 3) * 0.3; // 36.5-37.4°C
    double baseNoise = 40 + (DateTime.now().second % 50); // 40-90 dB
    double baseAgitation = 20 + (DateTime.now().minute % 6) * 10; // 20-70%
    double baseBreathingRate =
        30 + (DateTime.now().second % 10); // 30-40 respirations/min
    // Simuler des pics occasionnels de stress
    if (DateTime.now().minute % 5 == 0) {
      baseHeartRate += 25;
      baseAgitation += 30;
      baseNoise += 25;
    }

    final sensorData = SensorData(
      timestamp: now,
      heartRate: baseHeartRate.clamp(60, 140).toDouble(),
      breathingRate: baseBreathingRate.clamp(15, 40).toDouble(),
      temperature: baseTemperature.clamp(36.0, 39.0),
      noiseLevel: baseNoise.clamp(30, 120),
      motion: baseAgitation.clamp(0, 100),
      stressScore: 0, // Sera calculé
    );

    // Calculer le score de stress
    sensorData.stressScore = _calculateStressScore(sensorData);

    return sensorData;
  }

  // Calculer le score de stress basé sur les données
  // Calculer le score de stress basé sur les données (version améliorée)
  double _calculateStressScore(SensorData data) {
    double score = 0;

    // Rythme cardiaque (poids: 30%)
    if (data.heartRate > 100) {
      score += 30;
    } else if (data.heartRate > 90) {
      score += 20;
    } else if (data.heartRate > 80) {
      score += 10;
    }

    // 👇 Rythme respiratoire (poids: 20%) - NOUVEAU
    if (data.breathingRate > 35) {
      score += 20;
    } else if (data.breathingRate > 30) {
      score += 15;
    } else if (data.breathingRate > 25) {
      score += 5;
    }

    // Température (poids: 15%)
    if (data.temperature > 37.5) {
      score += 15;
    } else if (data.temperature > 37.2) {
      score += 8;
    }

    // Niveau de bruit (poids: 15%)
    if (data.noiseLevel > 80) {
      score += 15;
    } else if (data.noiseLevel > 65) {
      score += 8;
    }

    // Agitation (poids: 20%)
    if (data.motion > 70) {
      score += 20;
    } else if (data.motion > 50) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  // Vérifier et déclencher les alertes
  void _checkForAlerts(SensorData data) {
    // Only send alerts if stress score is above threshold
    if (data.stressScore <= _stressThreshold) {
      return;
    }

    // Only send stress alerts - no heart rate, breathing, temperature, or noise alerts
    if (data.stressScore > 70) {
      final alert = Alert(
        id: 'stress_${data.timestamp.millisecondsSinceEpoch}',
        type: AlertType.stress,
        message: 'Niveau de stress élevé: ${data.stressScore.round()}%',
        severity: data.stressScore > 85
            ? AlertSeverity.high
            : AlertSeverity.medium,
        timestamp: data.timestamp,
        sensorData: data,
      );
      _alertController.add(alert);
    }
  }

  // Nettoyer les ressources
  void dispose() {
    stopMonitoring();
    _sensorDataController.close();
    _alertController.close();
  }
}
