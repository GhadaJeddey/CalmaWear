// models/chat_message.dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final String? messageId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
    this.messageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      conversationId: json['conversationId'],
      messageId: json['messageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
      'messageId': messageId,
    };
  }

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? conversationId,
    String? messageId,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  String toString() {
    return 'ChatMessage{text: $text, isUser: $isUser, timestamp: $timestamp}';
  }
}
