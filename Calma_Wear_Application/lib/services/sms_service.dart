// services/sms_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/keys.dart';
import '../models/sensor_data.dart';

class SmsService {
  // Using Twilio for SMS (you'll need to add credentials to env.dart)
  // Alternative: use any SMS gateway API you prefer

  static String get twilioAccountSid => ApiKeys.twilioAccountSid;
  static String get twilioAuthToken => ApiKeys.twilioAuthToken;
  static String get twilioPhoneNumber => ApiKeys.twilioPhoneNumber;

  /// Check if SMS service is configured
  bool get isConfigured => ApiKeys.isTwilioConfigured;

  /// Send stress alert SMS to teacher contacts
  Future<bool> sendStressAlertToTeachers({
    required List<String> teacherPhoneNumbers,
    required String childName,
    required SensorData sensorData,
  }) async {
    if (!isConfigured) {
      print(
        '⚠️  Twilio SMS not configured. Add credentials to lib/config/env.dart',
      );
      return false;
    }

    if (teacherPhoneNumbers.isEmpty) {
      print('No teacher phone numbers configured');
      return false;
    }
    bool allSuccessful = true;

    for (final phoneNumber in teacherPhoneNumbers) {
      final success = await _sendSms(
        to: phoneNumber,
        message: _buildAlertMessage(childName, sensorData),
      );

      if (!success) {
        allSuccessful = false;
      }
    }

    return allSuccessful;
  }

  /// Build alert message text
  String _buildAlertMessage(String childName, SensorData sensorData) {
    return '''
🚨 CalmaWear Alert

Student: $childName
Status: HIGH STRESS DETECTED

Stress Level: ${sensorData.stressScore.round()}%
Heart Rate: ${sensorData.heartRate.round()} BPM
Time: ${_formatTime(sensorData.timestamp)}

Please check on the student.
''';
  }

  /// Format timestamp for message
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Send SMS using Twilio API
  Future<bool> _sendSms({required String to, required String message}) async {
    try {
      // Validate phone number format (should include country code, e.g., +1234567890)
      if (!to.startsWith('+')) {
        print('Invalid phone number format: $to (must include country code)');
        return false;
      }

      final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Messages.json',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$twilioAccountSid:$twilioAuthToken'))}',
        },
        body: {'From': twilioPhoneNumber, 'To': to, 'Body': message},
      );

      if (response.statusCode == 201) {
        print('✅ SMS sent successfully to $to');
        return true;
      } else {
        print('❌ Failed to send SMS to $to: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending SMS to $to: $e');
      return false;
    }
  }

  /// Test SMS sending (for debugging)
  Future<bool> sendTestSms(String phoneNumber) async {
    return await _sendSms(
      to: phoneNumber,
      message:
          'Test message from CalmaWear. SMS alerts are configured successfully!',
    );
  }
}
