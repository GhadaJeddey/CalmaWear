import '../utils/constants.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? childName;

  final String? childAge;
  final DateTime createdAt;
  final double stressThreshold;
  final bool notificationsEnabled;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.childName,
    this.childAge,
    required this.createdAt,
    double? stressThreshold, //  Paramètre optionnel
    this.notificationsEnabled = true,
  }) : stressThreshold = stressThreshold ?? AppConstants.defaultStressThreshold;
  //  SI stressThreshold est null, utilise la constante

  // Le reste du code reste identique...
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? childName,
    String? childAge,
    DateTime? createdAt,
    double? stressThreshold,
    bool? notificationsEnabled,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      createdAt: createdAt ?? this.createdAt,
      stressThreshold: stressThreshold ?? this.stressThreshold,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
