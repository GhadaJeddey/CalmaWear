import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as app_models;

// Gestion de l'état d'authentification
// Gère l'état (utilisateur connecté? chargement? erreur?)
// Coordonne le Service
// Notifie l'UI quand l'état change
// Gère les erreurs pour l'utilisateur

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialiser l'état d'authentification au démarrage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier si l'utilisateur était connecté
      final wasLoggedIn = await _authService.isUserLoggedIn();
      if (wasLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Inscription
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? childName,
    List<String>? teacherPhoneNumbers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        childName: childName,
        teacherPhoneNumbers: teacherPhoneNumbers,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Connexion
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile(app_models.User updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Rafraîchir les données utilisateur depuis Firestore
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
