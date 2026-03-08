// lib/presentation/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/services/auth_service.dart';

class User {
  final int id;
  final String username;
  final String email;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isEmailVerified: json['is_email_verified'] ?? false,
    );
  }
}

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  
  String get username => _user?.username ?? 'User';
  String get email => _user?.email ?? 'user@example.com';
  int get userId => _user?.id ?? 0;
  bool get isEmailVerified => _user?.isEmailVerified ?? false;

  UserProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      debugPrint('Chargement données utilisateur...');
      
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // 1. Charger depuis cache local rapidement
        final userData = await _authService.getUserData();
        if (userData != null) {
          _user = User.fromJson(userData);
          debugPrint('Utilisateur chargé depuis cache : ${_user?.username}');
          notifyListeners();
        }
        
        // 2. Rafraîchir depuis API
        try {
          await fetchUserProfile();
        } catch (e) {
          debugPrint('Erreur fetch API (cache utilisé) : $e');
        }
      } else {
        // Pas connecté → vider immédiatement
        debugPrint('Utilisateur non connecté');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur loadUserData : $e');
      _user = null; // Sécurité
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    // Vider le user précédent immédiatement
    _user = null;
    notifyListeners();

    try {
      debugPrint('Tentative de connexion : $email');
      
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        await loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Erreur de connexion';
        debugPrint('Erreur : $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur : $e';
      debugPrint('Exception login : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    // Vider le user précédent immédiatement
    _user = null;
    notifyListeners();

    try {
      debugPrint('Tentative d\'inscription : $email');
      
      final result = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        await loadUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Erreur d\'inscription';
        debugPrint('Erreur : $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur : $e';
      debugPrint('Exception register : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchUserProfile() async {
    try {
      debugPrint('Récupération du profil utilisateur depuis API');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        debugPrint('Pas de token pour récupérer le profil');
        return false;
      }

      final result = await _authService.getUserInfo(token);

      if (result['success'] == true) {
        final userData = result['data'];
        _user = User.fromJson(userData);
        debugPrint('Profil mis à jour depuis API : ${_user?.username}');
        notifyListeners();
        return true;
      } else {
        debugPrint('Erreur récupération profil : ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception fetchUserProfile : $e');
      return false;
    }
  }

  Future<bool> updateProfile({String? username, String? email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Mise à jour du profil : username=$username, email=$email');
      
      final result = await _authService.updateProfile(
        username: username ?? _user?.username ?? '',
        email: email,
      );

      if (result['success'] == true) {
        final userData = result['user'];
        if (userData != null) {
          _user = User.fromJson(userData);
        }
        debugPrint('Profil mis à jour : ${_user?.username}');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Erreur de mise à jour';
        debugPrint('Erreur : $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur : $e';
      debugPrint('Exception updateProfile : $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyEmail(
        email: email,
        code: code,
      );

      if (result['success'] == true) {
        if (_user != null) {
          _user = User(
            id: _user!.id,
            username: _user!.username,
            email: _user!.email,
            isEmailVerified: true,
          );
        }
        debugPrint('Email vérifié');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Code invalide';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur : $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resendVerificationCode(email);

      if (result['success'] == true) {
        debugPrint('Code renvoyé');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Erreur';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur : $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('Déconnexion utilisateur');
    
    // Vider immédiatement en mémoire
    _user = null;
    _error = null;
    notifyListeners();

    await _authService.logout();
    
    debugPrint('Déconnexion effectuée');
  }

  Future<bool> deleteAccount() async {
    try {
      final result = await _authService.deleteAccount();

      if (result['success'] == true) {
        _user = null;
        _error = null;
        debugPrint('Compte supprimé');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur suppression : $e');
      return false;
    }
  }

  Future<void> refresh() async {
    await loadUserData();
  }

  Future<bool> checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await loadUserData();
      return _user != null;
    }
    return false;
  }
}