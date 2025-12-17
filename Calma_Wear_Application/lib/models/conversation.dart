// models/conversation.dart
import 'package:intl/intl.dart';
import 'chat_message.dart';

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final int messageCount;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.messageCount,
  });

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final conversationDay = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (conversationDay == today) {
      return 'Aujourd\'hui';
    } else if (conversationDay == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(updatedAt);
  }

  String get preview {
    if (messages.isEmpty) return 'Aucun message';
    final lastMessage = messages.last;
    return lastMessage.text.length > 50
        ? '${lastMessage.text.substring(0, 50)}...'
        : lastMessage.text;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Nouvelle conversation',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((msg) => ChatMessage.fromJson(msg))
              .toList() ??
          [],
      messageCount: json['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'messageCount': messageCount,
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    int? messageCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  String toString() {
    return 'Conversation{id: $id, title: $title, messageCount: $messageCount}';
  }
}
