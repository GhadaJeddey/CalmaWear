// models/user.dart
import '../utils/constants.dart';
import 'package:flutter/material.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final List<String>
  teacherPhoneNumbers; // Teacher contact numbers for SMS alerts

  // Parent info
  final DateTime? dateOfBirth;
  final String? profileImageUrl;

  // Child info
  final String? childName;
  final DateTime? childDateOfBirth;
  final String? childGender; // 'male', 'female', 'other'
  final String? childAge;
  final String? childProfileImageUrl;
  final String? childVoiceMemoUrl; // Cloudinary URL for voice memo
  final List<ChildTrigger> childTriggers;

  final DateTime createdAt;
  final double stressThreshold;
  final bool notificationsEnabled;

  User({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.name,
    List<String>? teacherPhoneNumbers,

    // Parent
    this.dateOfBirth,
    this.profileImageUrl,

    // Child
    this.childName,
    this.childDateOfBirth,
    this.childGender,
    this.childAge,
    this.childProfileImageUrl,
    this.childVoiceMemoUrl,
    List<ChildTrigger>? childTriggers,

    required this.createdAt,
    double? stressThreshold,
    this.notificationsEnabled = true,
  }) : teacherPhoneNumbers = teacherPhoneNumbers ?? [],
       stressThreshold = stressThreshold ?? AppConstants.defaultStressThreshold,
       childTriggers =
           childTriggers ??
           [
             ChildTrigger(name: 'Noise', intensity: 0, icon: Icons.volume_up),
             ChildTrigger(
               name: 'Light',
               intensity: 0,
               icon: Icons.lightbulb_outline,
             ),
             ChildTrigger(
               name: 'Crowd',
               intensity: 0,
               icon: Icons.people_outline,
             ),
             ChildTrigger(
               name: 'Temperature',
               intensity: 0,
               icon: Icons.thermostat_outlined,
             ),
           ];

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    List<String>? teacherPhoneNumbers,

    // Parent
    DateTime? dateOfBirth,
    String? profileImageUrl,

    // Child
    String? childName,
    DateTime? childDateOfBirth,
    String? childGender,
    String? childAge,
    String? childProfileImageUrl,
    String? childVoiceMemoUrl,
    List<ChildTrigger>? childTriggers,

    DateTime? createdAt,
    double? stressThreshold,
    bool? notificationsEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      teacherPhoneNumbers: teacherPhoneNumbers ?? this.teacherPhoneNumbers,

      // Parent
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,

      // Child
      childName: childName ?? this.childName,
      childDateOfBirth: childDateOfBirth ?? this.childDateOfBirth,
      childGender: childGender ?? this.childGender,
      childAge: childAge ?? this.childAge,
      childProfileImageUrl: childProfileImageUrl ?? this.childProfileImageUrl,
      childVoiceMemoUrl: childVoiceMemoUrl ?? this.childVoiceMemoUrl,
      childTriggers: childTriggers ?? this.childTriggers,

      createdAt: createdAt ?? this.createdAt,
      stressThreshold: stressThreshold ?? this.stressThreshold,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'teacherPhoneNumbers': teacherPhoneNumbers,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'childName': childName,
      'childDateOfBirth': childDateOfBirth?.toIso8601String(),
      'childGender': childGender,
      'childAge': childAge,
      'childProfileImageUrl': childProfileImageUrl,
      'childVoiceMemoUrl': childVoiceMemoUrl,
      'childTriggers': childTriggers.map((t) => t.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'stressThreshold': stressThreshold,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      teacherPhoneNumbers: map['teacherPhoneNumbers'] != null
          ? List<String>.from(map['teacherPhoneNumbers'])
          : null,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      profileImageUrl: map['profileImageUrl'],
      childName: map['childName'],
      childDateOfBirth: map['childDateOfBirth'] != null
          ? DateTime.parse(map['childDateOfBirth'])
          : null,
      childGender: map['childGender'],
      childAge: map['childAge'],
      childProfileImageUrl: map['childProfileImageUrl'],
      childVoiceMemoUrl: map['childVoiceMemoUrl'],
      childTriggers: map['childTriggers'] != null
          ? (map['childTriggers'] as List)
                .map((t) => ChildTrigger.fromMap(t))
                .toList()
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      stressThreshold:
          map['stressThreshold']?.toDouble() ??
          AppConstants.defaultStressThreshold,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
    );
  }
}

class ChildTrigger {
  final String id;
  final String name;
  final int intensity; // 0-10 scale
  final IconData icon;

  ChildTrigger({
    String? id,
    required this.name,
    required this.intensity,
    required this.icon,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ChildTrigger copyWith({
    String? id,
    String? name,
    int? intensity,
    IconData? icon,
  }) {
    return ChildTrigger(
      id: id ?? this.id,
      name: name ?? this.name,
      intensity: intensity ?? this.intensity,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'intensity': intensity,
      'iconCodePoint': icon.codePoint,
    };
  }

  factory ChildTrigger.fromMap(Map<String, dynamic> map) {
    return ChildTrigger(
      id: map['id'],
      name: map['name'],
      intensity: map['intensity'],
      icon: IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons'),
    );
  }
}
