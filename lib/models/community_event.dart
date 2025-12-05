// models/community_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time; // e.g., "7:00 PM EST"
  final String type; // e.g., "AMA With Dr. Jennifer Smith"
  final int registeredCount;
  final List<String> registeredUsers; // List of user IDs
  final String? imageUrl; // Cloudinary image URL

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.type,
    required this.registeredCount,
    required this.registeredUsers,
    this.imageUrl,
  });

  String get dateFormatted {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  factory CommunityEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return CommunityEvent(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      type: data['type'] ?? '',
      registeredCount: data['registeredCount'] ?? 0,
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'type': type,
      'registeredCount': registeredCount,
      'registeredUsers': registeredUsers,
      'imageUrl': imageUrl,
    };
  }

  CommunityEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? type,
    int? registeredCount,
    List<String>? registeredUsers,
    String? imageUrl,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      registeredCount: registeredCount ?? this.registeredCount,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
