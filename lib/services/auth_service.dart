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

  // Récupérer l'utilisateur actuel
  Future<app_models.User?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Récupérer les données supplémentaires depuis Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return app_models.User(
          id: data['id'],
          email: data['email'],
          name: data['name'],
          childName: data['childName'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          stressThreshold: data['stressThreshold']?.toDouble() ?? 70.0,
          notificationsEnabled: data['notificationsEnabled'] ?? true,
        );
      }
    }
    return _userFromFirebase(user);
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
