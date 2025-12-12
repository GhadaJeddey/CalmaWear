import 'env.dart';

class ApiKeys {
  // Gemini API Configuration
  // Priorité: Variable d'environnement > Clé de développement
  static final String geminiApiKey = Env.geminiApiKey.isNotEmpty
      ? Env.geminiApiKey
      : 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  static bool get isConfigured =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  static const String geminiModel = 'gemini-2.5-flash';
  static const bool debugMode = true;

  // Cloudinary API Configuration
  static String get cloudinaryCloudName => Env.cloudinaryCloudName;
  static String get cloudinaryApiKey => Env.cloudinaryApiKey;
  static String get cloudinaryApiSecret => Env.cloudinaryApiSecret;
  static bool get isCloudinaryConfigured => Env.isCloudinaryConfigured;

  // Twilio SMS Configuration (for teacher alerts)
  // Get these from: https://console.twilio.com/
  static String get twilioAccountSid => Env.twilioAccountSid;
  static String get twilioAuthToken => Env.twilioAuthToken;
  static String get twilioPhoneNumber => Env.twilioPhoneNumber;
  static bool get isTwilioConfigured => Env.isTwilioConfigured;
}
