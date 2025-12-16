import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class StressPredictionService {
  // IMPORTANT: Change this based on where you're testing
  // For Android emulator: http://10.0.2.2:8000
  // For iOS simulator: http://localhost:8000
  // For Web (Chrome/Edge): http://localhost:8000
  // For physical device on same WiFi: http://YOUR_COMPUTER_IP:8000
  static const String apiUrl = 'http://localhost:8000/predict';

  /// Predicts stress using LSTM model
  /// Requires at least 3-5 recent sensor readings
  Future<Map<String, dynamic>?> predictStress(
    List<SensorData> recentReadings,
  ) async {
    try {
      // Need minimum readings for LSTM
      if (recentReadings.length < 3) {
        print(
          ' Not enough data for LSTM prediction (need at least 3 readings)',
        );
        return null;
      }

      // Prepare sequence: [[HR, BR, Temp, Motion], [HR, BR, Temp, Motion], ...]
      List<List<double>> sequence = recentReadings.map((data) {
        return [
          data.heartRate.toDouble(), // Feature 1: Heart Rate
          data.breathingRate.toDouble(), // Feature 2: Breathing Rate
          data.temperature, // Feature 3: Temperature
          data.motion.toDouble(), // Feature 4: Motion Level
        ];
      }).toList();

      print('📤 Sending ${sequence.length} readings to LSTM API...');
      print('📊 Sample reading: HR=${sequence.last[0].toStringAsFixed(1)}, BR=${sequence.last[1].toStringAsFixed(1)}, Temp=${sequence.last[2].toStringAsFixed(2)}, Motion=${sequence.last[3].toStringAsFixed(1)}');

      // Make HTTP POST request
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sequence': sequence}),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('API request timed out');
            },
          );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print(
          ' LSTM Prediction: ${result['stress_percent'].toStringAsFixed(1)}% (Level ${result['level']})',
        );
        return result;
      } else {
        print(' API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on TimeoutException {
      print('API timeout - using fallback calculation');
      return null;
    } catch (e) {
      print(' Error calling stress API: $e');
      return null;
    }
  }

  /// Get human-readable stress level description
  /// Level 0: < 20% (Calm)
  /// Level 1: 20-40% (Mild stress)
  /// Level 2: 40-70% (High stress)
  /// Level 3: > 70% (Crisis)
  String getStressLevelDescription(int level) {
    switch (level) {
      case 0:
        return 'Calm';
      case 1:
        return 'Mild Stress';
      case 2:
        return 'High Stress';
      case 3:
        return 'Crisis';
      default:
        return 'Unknown';
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
