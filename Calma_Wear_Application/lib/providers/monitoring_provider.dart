import 'package:flutter/foundation.dart';
import '../services/realtime_sensor_service.dart';
import '../services/vest_bluetooth_service.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';
import '../services/weekly_stats_service.dart';

class MonitoringProvider with ChangeNotifier {
  final RealtimeSensorService _realtimeService = RealtimeSensorService();

  SensorData? _currentSensorData;
  List<Alert> _activeAlerts = [];
  List<SensorData> _sensorHistory = [];
  bool _isMonitoring = false;
  double _stressThreshold = 70.0;
  late WeeklyStatsService _weeklyStatsService;

  SensorData? get currentSensorData => _currentSensorData;
  List<Alert> get activeAlerts => List.unmodifiable(_activeAlerts);
  List<SensorData> get sensorHistory => List.unmodifiable(_sensorHistory);
  bool get isMonitoring => _isMonitoring;
  double get stressThreshold => _stressThreshold;

  // Data source mode getters
  SensorDataMode get dataSourceMode => _realtimeService.currentMode;
  bool get isHardwareMode =>
      _realtimeService.currentMode == SensorDataMode.HARDWARE_BLUETOOTH;
  bool get isSyntheticMode =>
      _realtimeService.currentMode == SensorDataMode.SYNTHETIC_DATA;
  VestConnectionState get vestConnectionState =>
      _realtimeService.vestConnectionState;

  // Initialiser le monitoring
  void initializeMonitoring() {
    _weeklyStatsService = WeeklyStatsService();
    // Set initial threshold in service
    _realtimeService.updateStressThreshold(_stressThreshold);

    // Écouter les données des capteurs depuis Firebase Realtime Database
    _realtimeService.sensorDataStream.listen((sensorData) {
      _currentSensorData = sensorData;
      _sensorHistory.add(sensorData);

      // Garder seulement les 100 dernières mesures
      if (_sensorHistory.length > 100) {
        _sensorHistory.removeAt(0);
      }

      notifyListeners();
    });

    // Écouter les alertes
    _realtimeService.alertStream.listen((alert) {
      _activeAlerts.add(alert);
      notifyListeners();
    });
  }

  // Démarrer/arrêter le monitoring
  Future<void> toggleMonitoring() async {
    if (_isMonitoring) {
      await _realtimeService.stopMonitoring();
    } else {
      await _realtimeService.startMonitoring();
    }
    _isMonitoring = !_isMonitoring;
    notifyListeners();
  }

  // Marquer une alerte comme résolue
  void resolveAlert(String alertId) {
    final index = _activeAlerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _activeAlerts[index].isResolved = true;
      notifyListeners();
    }
  }

  // Supprimer une alerte résolue
  void removeResolvedAlert(String alertId) {
    _activeAlerts.removeWhere((alert) => alert.id == alertId);
    notifyListeners();
  }

  // Mettre à jour le seuil de stress
  void updateStressThreshold(double newThreshold) {
    _stressThreshold = newThreshold;
    _realtimeService.updateStressThreshold(newThreshold);
    notifyListeners();
  }

  void updateSensorData(SensorData data) {
    _currentSensorData = data;

    // Save alert if stress is high
    if (data.stressScore > 75) {
      _weeklyStatsService.saveStressAlert(data.stressScore);
    }

    notifyListeners();
  }

  // Switch data source mode (demo vs hardware)
  Future<void> switchDataSourceMode(SensorDataMode newMode) async {
    await _realtimeService.setDataSourceMode(newMode);
    notifyListeners();
  }

  // Quick toggle between modes
  Future<void> toggleDataSourceMode() async {
    final newMode = dataSourceMode == SensorDataMode.SYNTHETIC_DATA
        ? SensorDataMode.HARDWARE_BLUETOOTH
        : SensorDataMode.SYNTHETIC_DATA;
    await switchDataSourceMode(newMode);
  }

  // Obtenir l'historique des données pour les graphiques
  List<SensorData> getLastHourData() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _sensorHistory
        .where((data) => data.timestamp.isAfter(oneHourAgo))
        .toList();
  }

  // Nettoyer
  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}
