import 'package:calma_wear/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_models;

// ✅ app_models.User = NOTRE modèle
// ✅ User? user = Firebase User (pas d'alias)

// Service d'authentification (Operations avec Firebase)
// Ce Qu'il Fait:
// -Parle directement à Firebase
// -Gère les opérations techniques (connexion, inscription)
// -Convertit les données Firebase → Notre format

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convertir Firebase User en notre User Model
  app_models.User? _userFromFirebase(User? user) {
    // 👈 'User' = Firebase, 'app_models.User' = Notre modèle
    if (user == null) return null;

    return app_models.User(
      // 👈 Notre modèle avec alias
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? 'Utilisateur',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      stressThreshold: AppConstants.defaultStressThreshold,
      notificationsEnabled: AppConstants.defaultNotificationsEnabled,
    );
  }

  // Stream pour écouter les changements d'authentification
  Stream<app_models.User?> get user {
    return _auth.authStateChanges().asyncMap(_userFromFirebase);
  }

  Future<app_models.User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? childName,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le profil avec le nom
      await result.user!.updateDisplayName(name);

      // Créer le document utilisateur dans Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'id': result.user!.uid,
        'email': email,
        'name': name,
        'childName': childName,
        'createdAt': Timestamp.now(),
        'stressThreshold': AppConstants.defaultStressThreshold,
        'notificationsEnabled': AppConstants.defaultNotificationsEnabled,
      });

      return _userFromFirebase(result.user);
    } catch (e) {
      print('Erreur inscription: $e');
      rethrow;
    }
  }

  // Connexion avec email/mot de passe
  Future<app_models.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sauvegarder la session localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      return _userFromFirebase(result.user);
    } catch (e) {
      print('Erreur connexion: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await _auth.signOut();
    } catch (e) {
      print('Erreur déconnexion: $e');
      rethrow;
    }
  }

  // Vérifier si l'utilisateur est connecté au démarrage
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Récupérer l'utilisateur actuel avec TOUTES les données Firestore
  Future<app_models.User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Récupérer les données supplémentaires depuis Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Parse dates correctly (handle both Timestamp and String)
        DateTime? parseDate(dynamic value) {
          if (value == null) return null;
          if (value is Timestamp) return value.toDate();
          if (value is String) return DateTime.tryParse(value);
          return null;
        }

        // Parse child triggers
        List<app_models.ChildTrigger>? parseTriggers(dynamic value) {
          if (value == null) return null;
          if (value is List) {
            return value
                .map(
                  (t) => app_models.ChildTrigger.fromMap(
                    t as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
          return null;
        }

        return app_models.User(
          id: data['id'] ?? user.uid,
          email: data['email'] ?? user.email ?? '',
          name: data['name'] ?? user.displayName ?? 'User',
          phoneNumber: data['phoneNumber'],
          dateOfBirth: parseDate(data['dateOfBirth']),
          profileImageUrl: data['profileImageUrl'],
          childName: data['childName'],
          childDateOfBirth: parseDate(data['childDateOfBirth']),
          childGender: data['childGender'],
          childAge: data['childAge'],
          childProfileImageUrl: data['childProfileImageUrl'],
          childTriggers: parseTriggers(data['childTriggers']),
          createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
          stressThreshold: data['stressThreshold']?.toDouble() ?? 70.0,
          notificationsEnabled: data['notificationsEnabled'] ?? true,
        );
      }
    }
    return _userFromFirebase(user);
  }

  // Mettre à jour le profil utilisateur dans Firestore
  Future<void> updateUserProfile(app_models.User updatedUser) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Prepare data for Firestore (convert dates to ISO strings)
      final Map<String, dynamic> data = {
        'id': updatedUser.id,
        'email': updatedUser.email,
        'name': updatedUser.name,
        'phoneNumber': updatedUser.phoneNumber,
        'dateOfBirth': updatedUser.dateOfBirth?.toIso8601String(),
        'profileImageUrl': updatedUser.profileImageUrl,
        'childName': updatedUser.childName,
        'childDateOfBirth': updatedUser.childDateOfBirth?.toIso8601String(),
        'childGender': updatedUser.childGender,
        'childAge': updatedUser.childAge,
        'childProfileImageUrl': updatedUser.childProfileImageUrl,
        'childTriggers': updatedUser.childTriggers
            .map((t) => t.toMap())
            .toList(),
        'stressThreshold': updatedUser.stressThreshold,
        'notificationsEnabled': updatedUser.notificationsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update(data);

      // Also update Firebase Auth display name if changed
      if (user.displayName != updatedUser.name) {
        await user.updateDisplayName(updatedUser.name);
      }

      print('✅ User profile updated in Firestore');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Erreur reset password: $e');
      rethrow;
    }
  }
}
