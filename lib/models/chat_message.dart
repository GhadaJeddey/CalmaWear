class ChatMessage {
  final String text;
  final bool
  isUser; // true if the message is from the user, false if from the AI model
  final DateTime timestamp;

  // Constructor
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
