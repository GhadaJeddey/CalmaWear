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
  app_models.User? _currentUser; // Cache user data for SMS

  // Data source mode (default to synthetic for demonstration)
  SensorDataMode _currentMode = SensorDataMode.SYNTHETIC_DATA;

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
  }

  // Start synthetic data generation (demo mode)
  void _startSyntheticDataGeneration(String userId) {
    _generatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final sensorData = _generateSyntheticSensorData();

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
        // Calculate stress score for hardware data
        sensorData.stressScore = _calculateStressScore(sensorData);

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

    // Disconnect vest if in hardware mode
    if (_currentMode == SensorDataMode.HARDWARE_BLUETOOTH) {
      await _vestService.disconnect();
    }

    _isMonitoring = false;
  }

  // Generate realistic synthetic sensor data
  SensorData _generateSyntheticSensorData() {
    final now = DateTime.now();

    // Base values with realistic variations
    double baseHeartRate = 70 + _random.nextInt(30).toDouble(); // 70-100 BPM
    double baseTemperature = 36.5 + (_random.nextDouble() * 0.9); // 36.5-37.4°C
    double baseNoise = 40 + _random.nextInt(50).toDouble(); // 40-90 dB
    double baseAgitation = 20 + _random.nextInt(60).toDouble(); // 20-80%
    double baseBreathingRate =
        20 + _random.nextInt(15).toDouble(); // 20-35 resp/min

    // Simulate occasional stress spikes (10% chance - reduced frequency)
    if (_random.nextDouble() < 0.10) {
      baseHeartRate += 15 + _random.nextInt(10).toDouble();
      baseAgitation += 15 + _random.nextInt(15).toDouble();
      baseNoise += 15 + _random.nextInt(15).toDouble();
      baseBreathingRate += 3 + _random.nextInt(7).toDouble();
      baseTemperature += 0.2 + (_random.nextDouble() * 0.3);
    }

    final sensorData = SensorData(
      timestamp: now,
      heartRate: baseHeartRate.clamp(60, 140),
      breathingRate: baseBreathingRate.clamp(15, 45),
      temperature: baseTemperature.clamp(36.0, 38.5),
      noiseLevel: baseNoise.clamp(30, 120),
      motion: baseAgitation.clamp(0, 100),
      stressScore: 0, // Will be calculated
    );

    // Calculate stress score
    sensorData.stressScore = _calculateStressScore(sensorData);

    return sensorData;
  }

  // Calculate stress score based on sensor data
  double _calculateStressScore(SensorData data) {
    double score = 0;

    // Heart rate (weight: 30%)
    if (data.heartRate > 100) {
      score += 30;
    } else if (data.heartRate > 90) {
      score += 20;
    } else if (data.heartRate > 80) {
      score += 10;
    }

    // Breathing rate (weight: 20%)
    if (data.breathingRate > 35) {
      score += 20;
    } else if (data.breathingRate > 30) {
      score += 15;
    } else if (data.breathingRate > 25) {
      score += 5;
    }

    // Temperature (weight: 15%)
    if (data.temperature > 37.5) {
      score += 15;
    } else if (data.temperature > 37.2) {
      score += 8;
    }

    // Noise level (weight: 15%)
    if (data.noiseLevel > 80) {
      score += 15;
    } else if (data.noiseLevel > 65) {
      score += 8;
    }

    // Motion/Agitation (weight: 20%)
    if (data.motion > 70) {
      score += 20;
    } else if (data.motion > 50) {
      score += 10;
    }

    return score.clamp(0, 100);
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

  // Clean up resources
  void dispose() {
    stopMonitoring();
    _sensorDataController.close();
    _alertController.close();
  }
}
