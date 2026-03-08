// lib/presentation/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/token_service.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final TokenService   _tokenService   = TokenService.instance;
  final ApiService     _apiService     = ApiService.instance;

  AuthState _state        = AuthState.initial;
  User?     _currentUser  = null;
  String?   _errorMessage = null;
  bool      _isLoading    = false;

  AuthState get state          => _state;
  User?     get currentUser    => _currentUser;
  String?   get errorMessage   => _errorMessage;
  bool      get isLoading      => _isLoading;
  bool      get isAuthenticated => _state == AuthState.authenticated;


  Future<void> checkAuthStatus() async {
    try {
      _state = AuthState.loading;
      notifyListeners();

      final isLoggedIn = await _tokenService.isLoggedIn();

      if (!isLoggedIn) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      // Essayer de récupérer l'utilisateur avec le token actuel
      User? user = await _authRepository.getCurrentUser();

      if (user != null) {
        // Token valide
        _currentUser = user;
        _state = AuthState.authenticated;
      } else {
        // Token invalide → essayer le refresh
        debugPrint('Token invalide, tentative de refresh...');
        final refreshed = await _tryRefreshToken();

        if (refreshed) {
          // Réessayer avec le nouveau token
          user = await _authRepository.getCurrentUser();
          if (user != null) {
            _currentUser = user;
            _state = AuthState.authenticated;
            debugPrint('Reconnexion automatique réussie');
          } else {
            await _tokenService.logout();
            _state = AuthState.unauthenticated;
          }
        } else {
          // Refresh échoué → déconnecter proprement
          await _tokenService.logout();
          _state = AuthState.unauthenticated;
          debugPrint('Refresh échoué, déconnexion');
        }
      }
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
      _state = AuthState.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiService.post(
        ApiConstants.refreshToken,
        {'refresh_token': refreshToken},
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = response.body;
        // Parser le JSON
        final json = jsonDecode(data) as Map<String, dynamic>;
        final newAccess  = json['access_token']  as String?;
        final newRefresh = json['refresh_token'] as String?;

        if (newAccess != null) {
          await _tokenService.saveTokens(
            accessToken:  newAccess,
            refreshToken: newRefresh ?? refreshToken,
          );
          debugPrint('Token refreshé avec succès');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint(' _tryRefreshToken error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _currentUser = result['user'];
        _state = AuthState.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur de connexion';
        _state = AuthState.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur réseau: $e';
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.register(
        email: email,
        username: username,
        password: password,
      );

      if (result['success'] == true) {
        _currentUser = result['user'];
        _state = AuthState.authenticated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur d\'inscription';
        _state = AuthState.error;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur réseau: $e';
      _state = AuthState.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authRepository.logout();

      _currentUser  = null;
      _state        = AuthState.unauthenticated;
      _errorMessage = null;
      _isLoading    = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur refresh user: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _currentUser != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  void resetState() {
    _state        = AuthState.initial;
    _currentUser  = null;
    _errorMessage = null;
    _isLoading    = false;
    notifyListeners();
  }
}