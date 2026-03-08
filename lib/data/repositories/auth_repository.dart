import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final ApiService _apiService = ApiService.instance;
  final TokenService _tokenService = TokenService.instance;
  final StorageService _storageService = StorageService.instance;

  // === LOGIN ===
  Future<Map> login({
    required String email,
    required String password,
  }) async {
    try {
      // ✅ Vider les données de l'ancien utilisateur AVANT login
      await _tokenService.logout();
      await _storageService.clearAll();

      final response = await _apiService.post(
        ApiConstants.login,
        {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _tokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );

        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        await _tokenService.saveUserInfo(
          userId: user.id,
          email: user.email,
        );

        return {
          'success': true,
          'user': user,
          'message': 'Connexion réussie',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  // === REGISTER ===
  Future<Map> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // ✅ Vider les données de l'ancien utilisateur AVANT register
      await _tokenService.logout();
      await _storageService.clearAll();

      final response = await _apiService.post(
        ApiConstants.register,
        {
          'email': email,
          'username': username,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _tokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );

        final user = User.fromJson(data['user']);
        await _storageService.saveUser(user);
        await _tokenService.saveUserInfo(
          userId: user.id,
          email: user.email,
        );

        return {
          'success': true,
          'user': user,
          'message': 'Inscription réussie',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Erreur d\'inscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  // === LOGOUT ===
  Future logout() async {
    // ✅ Pas d'appel API — juste supprimer les données locales
    await _tokenService.logout();
    await _storageService.clearAll();
  }

  // === GET CURRENT USER ===
  Future getCurrentUser() async {
    try {
      final userId = await _tokenService.getUserId();
      if (userId == null) return null;

      // D'abord chercher en local
      final localUser = await _storageService.getUser(userId);
      if (localUser != null) return localUser;

      // Sinon récupérer depuis l'API
      final response = await _apiService.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        await _storageService.saveUser(user);
        return user;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // === CHECK IF LOGGED IN ===
  Future isLoggedIn() async {
    return await _tokenService.isLoggedIn();
  }

  // === REFRESH TOKEN ===
  Future refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiService.post(
        ApiConstants.refreshToken,
        {'refresh_token': refreshToken},
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _tokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}