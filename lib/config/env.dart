class Env {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyB6g_XamVGoHeOZ638xzeDSGHume1sWnCQ',
  );

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
}
