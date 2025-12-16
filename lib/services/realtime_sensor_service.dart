import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';
import '../models/user.dart' as app_models;
import 'sms_service.dart';
import 'vest_bluetooth_service.dart';
import 'stress_prediction_service.dart';
import 'weekly_stats_service.dart';

// Data source mode enum
enum SensorDataMode {
  SYNTHETIC_DATA, // Demo mode - generated data
  HARDWARE_BLUETOOTH, // Production mode - BLE vest data
}

class RealtimeSensorService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SmsService _smsService = SmsService();
  final VestBluetoothService _vestService = VestBluetoothService();

  // LSTM prediction service
  final StressPredictionService _predictionService = StressPredictionService();

  // Weekly stats service for Firestore storage
  final WeeklyStatsService _weeklyStatsService = WeeklyStatsService();

  // Track daily sensor data for aggregation
  final Map<String, List<SensorData>> _dailySensorData = {};
  Timer? _dailyAggregationTimer;
  DateTime? _lastAggregationDate;

  // Store recent readings for LSTM (keep last 10)
  final List<SensorData> _recentReadingsHistory = [];
  static const int _maxHistorySize = 10;

  StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  StreamController<Alert> _alertController =
      StreamController<Alert>.broadcast();

  Timer? _generatorTimer;
  StreamSubscription? _databaseSubscription;
  StreamSubscription? _vestDataSubscription;
  bool _isMonitoring = false;
  double _stressThreshold = 75.0;
  final Random _random = Random();
  DateTime? _lastAlertTime; // Track last SMS alert time
  DateTime? _monitoringStartTime; // Track when monitoring started
  app_models.User? _currentUser; // Cache user data for SMS

  // Data source mode (default to synthetic for demonstration)
  SensorDataMode _currentMode = SensorDataMode.SYNTHETIC_DATA;

  // Base values for weekly metrics (these remain stable)
  double _baseHeartRate = 75.0;
  double _baseBreathingRate = 18.0;
  double _baseNoiseLevel = 45.0;
  double _baseMotionLevel = 30.0;

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<Alert> get alertStream => _alertController.stream;
  bool get isMonitoring => _isMonitoring;
  SensorDataMode get currentMode => _currentMode;
  VestConnectionState get vestConnectionState => _vestService.connectionState;

  // Update stress threshold
  void updateStressThreshold(double threshold) {
    _stressThreshold = threshold;
  }

  // Switch data source mode
  Future<void> setDataSourceMode(SensorDataMode mode) async {
    if (_currentMode == mode) return;

    // Stop current monitoring if active
    if (_isMonitoring) {
      await stopMonitoring();
    }

    _currentMode = mode;
    print('Data source mode changed to: $mode');
  }

  // Start real-time monitoring (mode-aware)
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    _isMonitoring = true;
    _monitoringStartTime =
        DateTime.now(); // Track start time for stress progression

    // Load user data for SMS alerts
    await _loadUserData(user.uid);

    if (_currentMode == SensorDataMode.SYNTHETIC_DATA) {
      // DEMO MODE: Generate synthetic data
      _startSyntheticDataGeneration(user.uid);
    } else {
      // HARDWARE MODE: Listen to BLE vest
      await _startHardwareDataCollection(user.uid);
    }

    // Listen to real-time database updates for UI
    _listenToSensorData(user.uid);

    // Start daily aggregation timer (runs every hour to update daily stats)
    _startDailyAggregationTimer();
  }

  // Start synthetic data generation (demo mode)
  void _startSyntheticDataGeneration(String userId) {
    _generatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final sensorData = await _generateSyntheticSensorData();

      // Store in Firebase Realtime Database
      await _storeSensorData(userId, sensorData);
    });
  }

  // Start hardware data collection (production mode)
  Future<void> _startHardwareDataCollection(String userId) async {
    try {
      // Connect to vest
      await _vestService.startScanning();

      // Listen to vest data stream
      _vestDataSubscription = _vestService.sensorDataStream.listen((
        sensorData,
      ) async {
        // Calculate stress score for hardware data using LSTM
        sensorData.stressScore =
            (await _calculateStressScore(sensorData)).toInt() as double;

        // Store in Firebase Realtime Database
        await _storeSensorData(userId, sensorData);
      });
    } catch (e) {
      print('Error starting hardware data collection: $e');
      // Fall back to synthetic data if hardware fails
      print('Falling back to synthetic data mode');
      _currentMode = SensorDataMode.SYNTHETIC_DATA;
      _startSyntheticDataGeneration(userId);
    }
  }

  // Load user data from Firestore for SMS alerts
  Future<void> _loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = app_models.User.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Stop monitoring
  Future<void> stopMonitoring() async {
    _generatorTimer?.cancel();
    await _databaseSubscription?.cancel();
    await _vestDataSubscription?.cancel();
    _dailyAggregationTimer?.cancel();

    // Disconnect vest if in hardware mode
    if (_currentMode == SensorDataMode.HARDWARE_BLUETOOTH) {
      await _vestService.disconnect();
    }

    // Store final daily aggregates before stopping
    await _aggregateAndStoreDailyStats();

    _isMonitoring = false;
  }

  // Generate simple synthetic sensor data with baseline values
  Future<SensorData> _generateSyntheticSensorData() async {
    final now = DateTime.now();

    // Track time since monitoring started
    final timeSinceStart = _monitoringStartTime != null
        ? now.difference(_monitoringStartTime!).inSeconds
        : 0;

    double hr, br, motion, temp, noise;
    String stateLabel = '';

    // Phase 1: First 30 seconds - CALM state (Level 0: <20%)
    if (timeSinceStart < 30) {
      stateLabel = 'CALM (Level 0: 10-15%)';

      // Base values for calm (10-15% stress)
      double baseHR = 78.0; // Just above 80 threshold for +10 points
      double baseBR = 26.0; // Just above 25 threshold for +5 points
      double baseMotion = 55.0; // Above 50 for +10 points

      // Add variation ±3 around base
      hr = baseHR + (_random.nextDouble() * 6 - 3); // 75-81 BPM
      br = baseBR + (_random.nextDouble() * 6 - 3); // 23-29 RPM
      motion = baseMotion + (_random.nextDouble() * 6 - 3); // 52-58%
      temp = 36.6 + _random.nextDouble() * 0.4; // 36.6-37.0°C
      noise = 50.0 + _random.nextDouble() * 20; // 50-70 dB

      print('🧘 $stateLabel (${timeSinceStart}s) - Target: 10-15% stress');
    }
    // Phase 2: 30-60 seconds - MILD STRESS state (Level 1: 20-40%)
    else if (timeSinceStart < 60) {
      stateLabel = 'MILD STRESS (Level 1: 25-35%)';

      // Base values for mild stress (25-35% stress)
      double baseHR = 85.0; // Above 80 for +10 points
      double baseBR = 28.0; // Above 25 for +5 points
      double baseMotion = 60.0; // Above 50 for +10 points

      // Add variation ±5 around base
      hr = baseHR + (_random.nextDouble() * 10 - 5); // 80-90 BPM
      br = baseBR + (_random.nextDouble() * 10 - 5); // 23-33 RPM
      motion = baseMotion + (_random.nextDouble() * 10 - 5); // 55-65%
      temp = 37.0 + _random.nextDouble() * 0.4; // 37.0-37.4°C
      noise = 65.0 + _random.nextDouble() * 15; // 65-80 dB

      print('😟 $stateLabel (${timeSinceStart}s) - Target: 25-35% stress');
    }
    // Phase 3: 60-90 seconds - HIGH STRESS state (Level 2: 40-70%)
    else if (timeSinceStart < 90) {
      stateLabel = 'HIGH STRESS (Level 2: 50-60%)';

      // Base values for high stress (50-60% stress)
      double baseHR = 95.0; // Above 90 for +20 points
      double baseBR = 32.0; // Above 30 for +15 points
      double baseMotion = 75.0; // Above 70 for +20 points

      // Add variation ±7 around base
      hr = baseHR + (_random.nextDouble() * 14 - 7); // 88-102 BPM
      br = baseBR + (_random.nextDouble() * 14 - 7); // 25-39 RPM
      motion = baseMotion + (_random.nextDouble() * 14 - 7); // 68-82%
      temp = 37.3 + _random.nextDouble() * 0.4; // 37.3-37.7°C
      noise = 75.0 + _random.nextDouble() * 10; // 75-85 dB

      print('😰 $stateLabel (${timeSinceStart}s) - Target: 50-60% stress');
    }
    // Phase 4: 90+ seconds - CRISIS state (Level 3: >70%)
    else {
      stateLabel = 'CRISIS (Level 3: 80-90%)';

      // Base values for crisis (80-90% stress)
      double baseHR = 115.0; // Above 100 for +30 points
      double baseBR = 37.0; // Above 35 for +20 points
      double baseMotion = 90.0; // Above 70 for +20 points

      // Add variation ±10 around base
      hr = baseHR + (_random.nextDouble() * 20 - 10); // 105-125 BPM
      br = baseBR + (_random.nextDouble() * 20 - 10); // 27-47 RPM
      motion = baseMotion + (_random.nextDouble() * 20 - 10); // 80-100%
      temp = 37.7 + _random.nextDouble() * 0.6; // 37.7-38.3°C
      noise = 85.0 + _random.nextDouble() * 15; // 85-100 dB

      print('🚨 $stateLabel (${timeSinceStart}s) - Target: 80-90% stress');
    }

    final sensorData = SensorData(
      timestamp: now,
      heartRate: hr,
      breathingRate: br,
      temperature: temp,
      noiseLevel: noise,
      motion: motion,
      stressScore: 0,
    );

    // Calculate stress score
    sensorData.stressScore = await _calculateStressScore(sensorData);

    // Print detailed info
    print('📊 Generated:');
    print('   HR: ${hr.toStringAsFixed(1)} BPM');
    print('   BR: ${br.toStringAsFixed(1)} RPM');
    print('   Temp: ${temp.toStringAsFixed(1)}°C');
    print('   Noise: ${noise.toStringAsFixed(1)} dB');
    print('   Motion: ${motion.toStringAsFixed(1)}%');
    print('   → Stress: ${sensorData.stressScore.toStringAsFixed(1)}%');

    // Determine stress level
    String stressLevel;
    if (sensorData.stressScore < 20) {
      stressLevel = 'Level 0 (Calm)';
    } else if (sensorData.stressScore < 40) {
      stressLevel = 'Level 1 (Mild)';
    } else if (sensorData.stressScore < 70) {
      stressLevel = 'Level 2 (High)';
    } else {
      stressLevel = 'Level 3 (Crisis)';
    }

    print('   → Level: $stressLevel');
    print('   → Alert: ${sensorData.stressScore > 75 ? "YES 🚨" : "NO ✅"}');
    print('');

    return sensorData;
  }

  Future<double> _calculateStressScore(SensorData data) async {
    print('📊 Using rule-based stress calculation');
    return _calculateSimpleStressScore(data);
  }

  // Calculate stress score using LSTM model API
  /* Future<double> _calculateStressScore(SensorData data) async {
    // Add current reading to history
    _recentReadingsHistory.add(data);

    // Keep only last N readings
    if (_recentReadingsHistory.length > _maxHistorySize) {
      _recentReadingsHistory.removeAt(0);
    }

    // Try LSTM prediction if we have enough data
    if (_recentReadingsHistory.length >= 3) {
      try {
        final prediction = await _predictionService.predictStress(
          _recentReadingsHistory,
        );

        if (prediction != null) {
          // LSTM prediction successful
          final stressPercent = prediction['stress_percent'] as double;
          final level = prediction['level'] as int;

          print(
            '🧠 LSTM: ${stressPercent.toStringAsFixed(1)}% - ${_predictionService.getStressLevelDescription(level)}',
          );

          return stressPercent;
        }
      } catch (e) {
        print('⚠️ LSTM failed, using simple fallback: $e');
      }
    }

    // Fallback to simple calculation when LSTM unavailable
    print(
      '📐 Using simple calculation (LSTM unavailable - ${_recentReadingsHistory.length} readings)',
    );
    return _calculateSimpleStressScore(data);
  } */

  // Simple fallback calculation (used when LSTM API unavailable)
  double _calculateSimpleStressScore(SensorData data) {
    double score = 0;

    // Heart rate (weight: 30%)
    if (data.heartRate > 100) {
      score += 30;
      print('   HR ${data.heartRate.toStringAsFixed(1)} → +30 (crisis)');
    } else if (data.heartRate > 90) {
      score += 20;
      print('   HR ${data.heartRate.toStringAsFixed(1)} → +20 (high)');
    } else if (data.heartRate > 80) {
      score += 10;
      print('   HR ${data.heartRate.toStringAsFixed(1)} → +10 (elevated)');
    } else {
      print('   HR ${data.heartRate.toStringAsFixed(1)} → +0 (normal)');
    }

    // Breathing rate (weight: 20%)
    if (data.breathingRate > 35) {
      score += 20;
      print('   BR ${data.breathingRate.toStringAsFixed(1)} → +20 (crisis)');
    } else if (data.breathingRate > 30) {
      score += 15;
      print('   BR ${data.breathingRate.toStringAsFixed(1)} → +15 (high)');
    } else if (data.breathingRate > 25) {
      score += 5;
      print('   BR ${data.breathingRate.toStringAsFixed(1)} → +5 (elevated)');
    } else {
      print('   BR ${data.breathingRate.toStringAsFixed(1)} → +0 (normal)');
    }

    // Temperature (weight: 15%)
    if (data.temperature > 37.5) {
      score += 15;
      print('   Temp ${data.temperature.toStringAsFixed(1)} → +15 (fever)');
    } else if (data.temperature > 37.2) {
      score += 8;
      print('   Temp ${data.temperature.toStringAsFixed(1)} → +8 (elevated)');
    } else {
      print('   Temp ${data.temperature.toStringAsFixed(1)} → +0 (normal)');
    }

    // Noise level (weight: 15%)
    if (data.noiseLevel > 80) {
      score += 15;
      print('   Noise ${data.noiseLevel.toStringAsFixed(1)} → +15 (loud)');
    } else if (data.noiseLevel > 65) {
      score += 8;
      print('   Noise ${data.noiseLevel.toStringAsFixed(1)} → +8 (moderate)');
    } else {
      print('   Noise ${data.noiseLevel.toStringAsFixed(1)} → +0 (quiet)');
    }

    // Motion/Agitation (weight: 20%)
    if (data.motion > 70) {
      score += 20;
      print('   Motion ${data.motion.toStringAsFixed(1)} → +20 (agitated)');
    } else if (data.motion > 50) {
      score += 10;
      print('   Motion ${data.motion.toStringAsFixed(1)} → +10 (active)');
    } else {
      print('   Motion ${data.motion.toStringAsFixed(1)} → +0 (calm)');
    }

    print('   Total score: $score');
    return score.clamp(0, 100);
  }

  // Helper methods for debugging
  double scoreForHR(double hr) {
    if (hr > 90) return 30;
    if (hr > 80) return 20;
    if (hr > 70) return 10;
    return 0;
  }

  double scoreForBR(double br) {
    if (br > 30) return 20;
    if (br > 25) return 15;
    if (br > 20) return 5;
    return 0;
  }

  double scoreForMotion(double motion) {
    if (motion > 60) return 20;
    if (motion > 40) return 10;
    return 0;
  }

  // Store sensor data in Firebase Realtime Database
  Future<void> _storeSensorData(String userId, SensorData data) async {
    try {
      final ref = _database.ref('users/$userId/sensor_data');

      // Push new data with auto-generated key
      await ref.push().set({
        'timestamp': data.timestamp.millisecondsSinceEpoch,
        'heartRate': data.heartRate,
        'breathingRate': data.breathingRate,
        'temperature': data.temperature,
        'noiseLevel': data.noiseLevel,
        'motion': data.motion,
        'stressScore': data.stressScore,
      });

      // Keep only last 100 records (cleanup old data)
      _cleanupOldData(userId);
    } catch (e) {
      print('❌ Error storing sensor data: $e');
      print('');
      print('⚠️  FIREBASE REALTIME DATABASE NOT SET UP!');
      print('');
      print('To fix this error:');
      print('1. Go to: https://console.firebase.google.com/');
      print('2. Select project: calmawear-81263');
      print('3. Click: Build → Realtime Database → Create Database');
      print('4. Select location: us-central1');
      print('5. Start in TEST MODE');
      print('6. After creation, go to Rules tab and set:');
      print('');
      print('{');
      print('  "rules": {');
      print('    "users": {');
      print('      "\$userId": {');
      print('        ".read": "\$userId === auth.uid",');
      print('        ".write": "\$userId === auth.uid",');
      print('        "sensor_data": {');
      print('          ".indexOn": ["timestamp"]');
      print('        }');
      print('      }');
      print('    }');
      print('  }');
      print('}');
      print('');
      print('7. Click PUBLISH');
      print('');

      // Stop monitoring to prevent repeated errors
      await stopMonitoring();
    }
  }

  // Listen to real-time database updates
  void _listenToSensorData(String userId) {
    final ref = _database.ref('users/$userId/sensor_data');

    // Listen to the last child added (most recent data)
    _databaseSubscription = ref.limitToLast(1).onChildAdded.listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        final sensorData = SensorData(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] as int,
          ),
          heartRate: (data['heartRate'] as num).toDouble(),
          breathingRate: (data['breathingRate'] as num).toDouble(),
          temperature: (data['temperature'] as num).toDouble(),
          noiseLevel: (data['noiseLevel'] as num).toDouble(),
          motion: (data['motion'] as num).toDouble(),
          stressScore: (data['stressScore'] as num).toDouble(),
        );

        // Emit the sensor data
        _sensorDataController.add(sensorData);

        // Track daily data for aggregation
        _trackDailySensorData(sensorData);

        // Check for alerts
        _checkForAlerts(sensorData);
      } catch (e) {
        print('Error parsing sensor data: $e');
      }
    });
  }

  // Check and trigger alerts based on stress threshold
  void _checkForAlerts(SensorData data) async {
    // Only send alerts if stress score is above threshold
    if (data.stressScore <= _stressThreshold) {
      return;
    }

    // Only send stress alerts
    if (data.stressScore > 75) {
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

      // Send SMS to teachers (rate limited to once every 10 minutes)
      await _sendSmsAlertToTeachers(data);
    }
  }

  // Send SMS alert to teacher contacts
  Future<void> _sendSmsAlertToTeachers(SensorData data) async {
    // Rate limit: only send SMS once every 30 minutes
    if (_lastAlertTime != null) {
      final timeSinceLastAlert = DateTime.now().difference(_lastAlertTime!);
      if (timeSinceLastAlert.inMinutes < 30) {
        print(
          'SMS alert rate limited (last sent ${timeSinceLastAlert.inMinutes} minutes ago)',
        );
        return;
      }
    }

    if (_currentUser == null) {
      print('User data not loaded for SMS alerts');
      return;
    }

    if (_currentUser!.teacherPhoneNumbers.isEmpty) {
      print('No teacher phone numbers configured');
      return;
    }

    final childName = _currentUser!.childName ?? 'Student';

    try {
      final success = await _smsService.sendStressAlertToTeachers(
        teacherPhoneNumbers: _currentUser!.teacherPhoneNumbers,
        childName: childName,
        sensorData: data,
      );

      if (success) {
        _lastAlertTime = DateTime.now();
        print(
          '✅ SMS alerts sent to ${_currentUser!.teacherPhoneNumbers.length} teacher(s)',
        );
      } else {
        print('⚠️  Failed to send SMS alerts');
      }
    } catch (e) {
      print('Error sending SMS alerts: $e');
    }
  }

  // Cleanup old data (keep only last 100 records)
  Future<void> _cleanupOldData(String userId) async {
    try {
      final ref = _database.ref('users/$userId/sensor_data');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final keys = data.keys.toList();

        // If more than 100 records, remove oldest ones
        if (keys.length > 100) {
          final sortedKeys = keys.toList()
            ..sort((a, b) {
              final aTime = data[a]['timestamp'] as int;
              final bTime = data[b]['timestamp'] as int;
              return aTime.compareTo(bTime);
            });

          // Remove oldest records
          final keysToRemove = sortedKeys.take(keys.length - 100);
          for (final key in keysToRemove) {
            await ref.child(key.toString()).remove();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old data: $e');
    }
  }

  // Get historical sensor data from database
  Future<List<SensorData>> getHistoricalData(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final ref = _database.ref('users/$userId/sensor_data');
      final snapshot = await ref.limitToLast(limit).get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final sensorDataList = <SensorData>[];

      data.forEach((key, value) {
        final record = value as Map<dynamic, dynamic>;
        sensorDataList.add(
          SensorData(
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              record['timestamp'] as int,
            ),
            heartRate: (record['heartRate'] as num).toDouble(),
            breathingRate: (record['breathingRate'] as num).toDouble(),
            temperature: (record['temperature'] as num).toDouble(),
            noiseLevel: (record['noiseLevel'] as num).toDouble(),
            motion: (record['motion'] as num).toDouble(),
            stressScore: (record['stressScore'] as num).toDouble(),
          ),
        );
      });

      // Sort by timestamp (oldest to newest)
      sensorDataList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return sensorDataList;
    } catch (e) {
      print('Error fetching historical data: $e');
      return [];
    }
  }

  // Get average stress score for today
  Future<double> getTodayAverageStress(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final ref = _database.ref('users/$userId/sensor_data');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return 0.0;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final todayScores = <double>[];

      data.forEach((key, value) {
        final record = value as Map<dynamic, dynamic>;
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          record['timestamp'] as int,
        );

        if (timestamp.isAfter(startOfDay)) {
          todayScores.add((record['stressScore'] as num).toDouble());
        }
      });

      if (todayScores.isEmpty) return 0.0;

      return todayScores.reduce((a, b) => a + b) / todayScores.length;
    } catch (e) {
      print('Error calculating average stress: $e');
      return 0.0;
    }
  }

  // Track sensor data per day for aggregation
  void _trackDailySensorData(SensorData data) {
    final dateKey = _formatDateKey(data.timestamp);
    if (!_dailySensorData.containsKey(dateKey)) {
      _dailySensorData[dateKey] = [];
    }
    _dailySensorData[dateKey]!.add(data);

    // Limit per-day data to prevent memory issues (keep last 1000 readings per day)
    if (_dailySensorData[dateKey]!.length > 1000) {
      _dailySensorData[dateKey]!.removeAt(0);
    }
  }

  // Start timer to periodically aggregate and store daily stats
  void _startDailyAggregationTimer() {
    // Run aggregation every hour
    _dailyAggregationTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _aggregateAndStoreDailyStats(),
    );

    // Also run immediately to process any existing data
    _aggregateAndStoreDailyStats();
  }

  // Aggregate and store daily stats for all tracked days
  Future<void> _aggregateAndStoreDailyStats() async {
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);

    // Process all days that have data
    for (final entry in _dailySensorData.entries) {
      final dateKey = entry.key;
      final sensorDataList = entry.value;

      if (sensorDataList.isEmpty) continue;

      // Parse date from key
      final date = _parseDateKey(dateKey);
      if (date == null) continue;

      // Calculate aggregates for this day
      await _weeklyStatsService.calculateAndStoreDailyStats(
        date,
        sensorDataList,
      );
    }

    // Clean up old data (keep only last 7 days)
    final cutoffDate = now.subtract(const Duration(days: 7));
    final cutoffKey = _formatDateKey(cutoffDate);
    _dailySensorData.removeWhere((key, _) => key.compareTo(cutoffKey) < 0);

    _lastAggregationDate = now;
  }

  // Format date as YYYY-MM-DD for use as map key
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Parse date from YYYY-MM-DD format
  DateTime? _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (e) {
      return null;
    }
  }

  // Clean up resources
  void dispose() {
    stopMonitoring();
    _sensorDataController.close();
    _alertController.close();
  }
}
