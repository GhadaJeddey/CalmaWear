import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_data.dart';

/// Service to store and retrieve weekly statistics from Firestore
/// Stores daily aggregates: max heart rate, avg breathing rate, max noise, max movement
class WeeklyStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Store or update daily aggregates for a specific date
  /// Date format: YYYY-MM-DD (e.g., "2024-01-15")
  Future<void> updateDailyStats({
    required DateTime date,
    double? maxHeartRate,
    double? avgBreathingRate,
    double? maxNoise,
    double? maxMovement,
  }) async {
    if (currentUserId == null) {
      print(' No user logged in, cannot store daily stats');
      return;
    }

    try {
      final dateKey = _formatDate(date);
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('daily_stats')
          .doc(dateKey);

      // Get existing document to merge with new values
      final doc = await docRef.get();
      // Ensure we always work with a non-null map
      final Map<String, dynamic> existingData =
          (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

      // Update only provided values, keeping existing ones if not provided
      final updateData = <String, dynamic>{
        'date': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (maxHeartRate != null) {
        final existingMax = existingData['maxHeartRate'] as double?;
        updateData['maxHeartRate'] = existingMax != null
            ? (maxHeartRate > existingMax ? maxHeartRate : existingMax)
            : maxHeartRate;
      } else if (existingData['maxHeartRate'] != null) {
        updateData['maxHeartRate'] = existingData['maxHeartRate'];
      }

      if (avgBreathingRate != null) {
        // For average, we need to recalculate from all readings of the day
        // For now, we'll store the latest average or max if we're tracking max
        // This will be handled by the aggregation logic
        final existingAvg = existingData['avgBreathingRate'] as double?;
        if (existingAvg != null) {
          // If we have existing data, we'd need to recalculate properly
          // For simplicity, we'll update it (caller should handle aggregation)
          updateData['avgBreathingRate'] = avgBreathingRate;
        } else {
          updateData['avgBreathingRate'] = avgBreathingRate;
        }
      } else if (existingData['avgBreathingRate'] != null) {
        updateData['avgBreathingRate'] = existingData['avgBreathingRate'];
      }

      if (maxNoise != null) {
        final existingMax = existingData['maxNoise'] as double?;
        updateData['maxNoise'] = existingMax != null
            ? (maxNoise > existingMax ? maxNoise : existingMax)
            : maxNoise;
      } else if (existingData['maxNoise'] != null) {
        updateData['maxNoise'] = existingData['maxNoise'];
      }

      if (maxMovement != null) {
        final existingMax = existingData['maxMovement'] as double?;
        updateData['maxMovement'] = existingMax != null
            ? (maxMovement > existingMax ? maxMovement : existingMax)
            : maxMovement;
      } else if (existingData['maxMovement'] != null) {
        updateData['maxMovement'] = existingData['maxMovement'];
      }

      await docRef.set(updateData, SetOptions(merge: true));
    } catch (e) {
      print(' Error storing daily stats: $e');
    }
  }

  /// Store complete daily aggregates (called after processing all data for a day)
  Future<void> setDailyStats({
    required DateTime date,
    required double maxHeartRate,
    required double avgBreathingRate,
    required double maxNoise,
    required double maxMovement,
  }) async {
    if (currentUserId == null) {
      print('⚠️ No user logged in, cannot store daily stats');
      return;
    }

    try {
      final dateKey = _formatDate(date);
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('daily_stats')
          .doc(dateKey)
          .set({
            'date': Timestamp.fromDate(date),
            'maxHeartRate': maxHeartRate,
            'avgBreathingRate': avgBreathingRate,
            'maxNoise': maxNoise,
            'maxMovement': maxMovement,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print(' Error storing daily stats: $e');
    }
  }

  /// Get daily stats for a specific date
  Future<Map<String, double>?> getDailyStats(DateTime date) async {
    if (currentUserId == null) return null;

    try {
      final dateKey = _formatDate(date);
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('daily_stats')
          .doc(dateKey)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return {
        'maxHeartRate': (data['maxHeartRate'] as num?)?.toDouble() ?? 0.0,
        'avgBreathingRate':
            (data['avgBreathingRate'] as num?)?.toDouble() ?? 0.0,
        'maxNoise': (data['maxNoise'] as num?)?.toDouble() ?? 0.0,
        'maxMovement': (data['maxMovement'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print(' Error fetching daily stats: $e');
      return null;
    }
  }

  Future<void> saveStressAlert(double stressScore) async {
    if (currentUserId == null || stressScore <= 75) {
      return; // Only save if stress > 75
    }

    try {
      final alertData = {
        'stressScore': stressScore,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('alerts')
          .add(alertData);

      print('📢 Alert saved: $stressScore% stress');
    } catch (e) {
      print('❌ Error saving alert: $e');
    }
  }

  /// Get daily alert counts for the last 7 days
  Future<List<double>> getWeeklyAlertCounts() async {
    if (currentUserId == null) {
      return List.filled(7, 0.0);
    }

    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7));

      // Get all alerts from last 7 days
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('alerts')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .get();

      // Initialize counts for last 7 days
      final weeklyCounts = List<double>.filled(7, 0.0);

      // Count alerts by day
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp != null) {
          final daysDiff = now.difference(timestamp).inDays;
          if (daysDiff < 7) {
            final index = 6 - daysDiff; // Most recent day at index 6
            weeklyCounts[index] += 1.0;
          }
        }
      }

      print('📊 Weekly alerts: $weeklyCounts');
      return weeklyCounts;
    } catch (e) {
      print('❌ Error getting alert counts: $e');
      return List.filled(7, 0.0);
    }
  }

  /// Get total alert count
  /// Get total alert count
  Future<int> getTotalAlertCount() async {
    if (currentUserId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('alerts')
          .count()
          .get();

      // Use ?? operator to provide default value if null
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting total alert count: $e');
      return 0;
    }
  }

  /// Get recent alerts for display
  Future<List<Map<String, dynamic>>> getRecentAlerts({int limit = 10}) async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'stressScore': (data['stressScore'] as num?)?.toDouble() ?? 0.0,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting recent alerts: $e');
      return [];
    }
  }

  /// Get weekly stats for the last 7 days
  /// Returns a list of 7 maps (one per day), ordered from oldest to newest
  /// Each map contains: maxHeartRate, avgBreathingRate, maxNoise, maxMovement
  Future<List<Map<String, double>>> getWeeklyStats() async {
    if (currentUserId == null) {
      print('⚠️ No user logged in');
      return _getDefaultWeeklyStats();
    }

    try {
      print('📊 Getting weekly stats for user: $currentUserId');

      // Get ALL daily_stats documents, sorted by date (newest first)
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('daily_stats')
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      final stats = <Map<String, double>>[];

      print('📄 Found ${querySnapshot.docs.length} documents');

      // Get the 7 most recent documents
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        stats.add({
          'maxHeartRate': (data['maxHeartRate'] as num?)?.toDouble() ?? 0.0,
          'avgBreathingRate':
              (data['avgBreathingRate'] as num?)?.toDouble() ?? 0.0,
          'maxNoise': (data['maxNoise'] as num?)?.toDouble() ?? 0.0,
          'maxMovement': (data['maxMovement'] as num?)?.toDouble() ?? 0.0,
        });
        print(
          '✅ Added: HR=${data['maxHeartRate']}, BR=${data['avgBreathingRate']}',
        );
      }

      // If we have fewer than 7 days, fill with defaults
      while (stats.length < 7) {
        print('➕ Adding default data (missing ${7 - stats.length} days)');
        stats.add(_getDefaultDayStats());
      }

      return stats;
    } catch (e) {
      print('❌ Error in getWeeklyStats: $e');
      return _getDefaultWeeklyStats();
    }
  }

  /// Get weekly stats as separate lists for each metric
  /// Returns a map with keys: maxHeartRate, avgBreathingRate, maxNoise, maxMovement
  /// Each value is a List<double> of 7 values (one per day, oldest to newest)
  Future<Map<String, List<double>>> getWeeklyStatsAsLists() async {
    final weeklyStats = await getWeeklyStats();

    return {
      'maxHeartRate': weeklyStats.map((s) => s['maxHeartRate'] ?? 0.0).toList(),
      'avgBreathingRate': weeklyStats
          .map((s) => s['avgBreathingRate'] ?? 0.0)
          .toList(),
      'maxNoise': weeklyStats.map((s) => s['maxNoise'] ?? 0.0).toList(),
      'maxMovement': weeklyStats.map((s) => s['maxMovement'] ?? 0.0).toList(),
    };
  }

  /// Calculate and store daily aggregates from sensor data
  /// Processes all sensor data for a specific day
  Future<void> calculateAndStoreDailyStats(
    DateTime date,
    List<SensorData> sensorDataForDay,
  ) async {
    if (sensorDataForDay.isEmpty) return;

    double maxHeartRate = 0.0;
    double totalBreathingRate = 0.0;
    double maxNoise = 0.0;
    double maxMovement = 0.0;
    int breathingRateCount = 0;

    for (final data in sensorDataForDay) {
      if (data.heartRate > maxHeartRate) {
        maxHeartRate = data.heartRate;
      }

      totalBreathingRate += data.breathingRate;
      breathingRateCount++;

      if (data.noiseLevel > maxNoise) {
        maxNoise = data.noiseLevel;
      }

      if (data.motion > maxMovement) {
        maxMovement = data.motion;
      }
    }

    final avgBreathingRate = breathingRateCount > 0
        ? totalBreathingRate / breathingRateCount
        : 0.0;

    await setDailyStats(
      date: date,
      maxHeartRate: maxHeartRate,
      avgBreathingRate: avgBreathingRate,
      maxNoise: maxNoise,
      maxMovement: maxMovement,
    );
  }

  /// Helper: Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Default stats for a day with no data
  Map<String, double> _getDefaultDayStats() {
    return {
      'maxHeartRate': 75.0,
      'avgBreathingRate': 18.0,
      'maxNoise': 45.0,
      'maxMovement': 30.0,
    };
  }

  /// Default weekly stats (7 days of default values)
  List<Map<String, double>> _getDefaultWeeklyStats() {
    return List.generate(7, (_) => _getDefaultDayStats());
  }
}
