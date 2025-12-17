// models/todo_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItem {
  final String id;
  final String title;
  final String category;
  final bool isCompleted;
  final bool isUserDefault;
  final bool isAiSuggested;
  final DateTime createdAt;
  final DateTime? completedAt;
  bool? isSelectedForAddition;

  TodoItem({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.isUserDefault,
    required this.isAiSuggested,
    required this.createdAt,
    this.completedAt,
    this.isSelectedForAddition = false,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'isUserDefault': isUserDefault,
      'isAiSuggested': isAiSuggested,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  // Create from Firestore data
  factory TodoItem.fromFirestore(Map<String, dynamic> data) {
    return TodoItem(
      id: data['id'],
      title: data['title'],
      category: data['category'],
      isCompleted: data['isCompleted'],
      isUserDefault: data['isUserDefault'],
      isAiSuggested: data['isAiSuggested'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // For JSON serialization (backup)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'isCompleted': isCompleted,
      'isUserDefault': isUserDefault,
      'isAiSuggested': isAiSuggested,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      isCompleted: json['isCompleted'],
      isUserDefault: json['isUserDefault'],
      isAiSuggested: json['isAiSuggested'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  // Copy with method for updates
  TodoItem copyWith({
    String? id,
    String? title,
    String? category,
    bool? isCompleted,
    bool? isUserDefault,
    bool? isAiSuggested,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isSelectedForAddition,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isUserDefault: isUserDefault ?? this.isUserDefault,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isSelectedForAddition:
          isSelectedForAddition ?? this.isSelectedForAddition,
    );
  }
}
