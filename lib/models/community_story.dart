// models/community_story.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityStory {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likes;
  final int readTime; // in minutes
  final List<String> likedBy; // List of user IDs who liked

  CommunityStory({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likes,
    required this.readTime,
    required this.likedBy,
  });

  factory CommunityStory.fromFirestore(Map<String, dynamic> data, String id) {
    return CommunityStory(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      readTime: data['readTime'] ?? 5,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'readTime': readTime,
      'likedBy': likedBy,
    };
  }

  CommunityStory copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    int? likes,
    int? readTime,
    List<String>? likedBy,
  }) {
    return CommunityStory(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      readTime: readTime ?? this.readTime,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  static int calculateReadTime(String content) {
    // Average reading speed: 200 words per minute
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
