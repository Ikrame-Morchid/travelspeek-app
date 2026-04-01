// lib/data/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'token_service.dart';
import 'storage_service.dart';
import '../database/conversation_database.dart';

class AuthService {

  static const String baseUrl = 'http://100.81.116.14:8000';
  
  final TokenService _tokenService = TokenService.instance;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ✅ FIX : Clear session sans toucher aux photos ni à last_user_id
  Future<void> _clearSessionOnly() async {
    await _tokenService.logout();
    final prefs = await SharedPreferences.getInstance();

    // Sauvegarder toutes les photos AVANT clear
    final Map<String, String> photosToKeep = {};
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('profile_image_path_')) {
        final val = prefs.getString(key);
        if (val != null) photosToKeep[key] = val;
      }
    }
    // Sauvegarder last_user_id
    final lastUserId = prefs.getInt('last_user_id');

    await prefs.clear();

    // Restaurer photos et last_user_id après clear
    for (final entry in photosToKeep.entries) {
      await prefs.setString(entry.key, entry.value);
    }
    if (lastUserId != null) {
      await prefs.setInt('last_user_id', lastUserId);
    }
  }

  Future<void> _clearEverything() async {
    await _tokenService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await StorageService.instance.clearAll();
    } catch (e) {
      debugPrint('Erreur clear Isar : $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Inscription : $email');

      final prefs = await SharedPreferences.getInstance();
      final oldUserId = prefs.getInt('user_id');

      await _clearSessionOnly();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newUserId = data['user']['id'] ?? 0;

        // ✅ FIX : Effacer seulement les données de l'ancien user, pas les photos
        if (oldUserId != null && oldUserId != newUserId) {
          await StorageService.instance.clearUserData(userId: oldUserId);
          await ConversationDatabase.instance.deleteAllForUser(oldUserId);
        }
        
        await _tokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? '',
        );
        await _tokenService.saveUserInfo(
          userId: newUserId,
          email: email,
        );

        final newPrefs = await SharedPreferences.getInstance();
        await newPrefs.setString('access_token', data['access_token']);
        await newPrefs.setString('user_email', email);
        await newPrefs.setString('username', username);
        await newPrefs.setInt('user_id', newUserId);
        await newPrefs.setBool('email_verified', false);
        
        debugPrint('✅ Inscription réussie');
        return {
          'success': true,
          'message': 'Account created successfully',
          'token': data['access_token'],
          'user': data['user'],
        };
      } else {
        final error = jsonDecode(response.body);
        debugPrint('❌ Erreur inscription : ${error['detail']}');
        return {
          'success': false,
          'message': error['detail'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      debugPrint('❌ Exception register : $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Connexion : $email');

      // ✅ FIX : _clearSessionOnly() préserve maintenant les photos automatiquement
      // Pas besoin de sauvegarder/restaurer manuellement ici
      await _clearSessionOnly();
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        await _tokenService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'] ?? '',
        );

        final userInfo = await getUserInfo(data['access_token']);
        
        if (userInfo['success']) {
          final userData = userInfo['data'];
          final newUserId = userData['id'] as int;

          // ✅ FIX : Lire last_user_id depuis prefs (préservé par _clearSessionOnly)
          final prefs = await SharedPreferences.getInstance();
          final oldUserId = prefs.getInt('last_user_id');

          // ✅ FIX CONVERSATIONS : Ne jamais effacer les conversations de l'ancien user !
          // SQLite filtre par user_id → les conversations de A restent quand B se connecte.
          // Chaque user retrouve ses propres conversations au login automatiquement.
          if (oldUserId != null && oldUserId != newUserId) {
            debugPrint('🔄 Autre user ($oldUserId → $newUserId) → données isolées par userId, rien à effacer');
          } else {
            debugPrint('✅ Même user → toutes données conservées');
          }

          await _tokenService.saveUserInfo(
            userId: newUserId,
            email: userData['email'],
          );

          await prefs.setString('access_token', data['access_token']);
          await prefs.setString('user_email', userData['email']);
          await prefs.setString('username', userData['username']);
          await prefs.setInt('user_id', newUserId);
          await prefs.setBool('email_verified', userData['is_email_verified'] ?? false);
          await prefs.remove('last_user_id');

          // ✅ Debug : vérifier que la photo est bien là
          final photo = prefs.getString('profile_image_path_$newUserId');
          debugPrint('📸 Photo après login pour user $newUserId : $photo');
          
          debugPrint('✅ Connexion réussie : ${userData['username']}');
          return {
            'success': true,
            'message': 'Login successful',
            'user': userData,
          };
        }
        
        return {'success': true, 'message': 'Login successful'};
      } else {
        debugPrint('❌ Erreur login : ${response.statusCode}');
        return {'success': false, 'message': 'Invalid email or password'};
      }
    } catch (e) {
      debugPrint('❌ Exception login : $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to get user info'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: headers,
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('email_verified', true);
        return {'success': true, 'message': 'Email verified successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Invalid or expired code'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Verification code sent'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Failed to send code'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String username,
    String? email,
  }) async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = <String, dynamic>{'username': username};
      if (email != null) body['email'] = email;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username']);
        await prefs.setString('user_email', data['email']);
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': data
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await _tokenService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: authHeaders(token),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final currentUserId = prefs.getInt('user_id') ?? 0;
        await ConversationDatabase.instance.deleteAllForUser(currentUserId);
        await _clearEverything();
        debugPrint('✅ Compte supprimé');
        return {'success': true, 'message': 'Account deleted successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Failed to delete account'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<String?> getToken() async {
    final secureToken = await _tokenService.getAccessToken();
    if (secureToken != null) return secureToken;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final email = prefs.getString('user_email');
      final userId = prefs.getInt('user_id');
      final emailVerified = prefs.getBool('email_verified');

      if (username == null || email == null) return null;

      return {
        'id': userId,
        'username': username,
        'email': email,
        'is_email_verified': emailVerified ?? false,
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('Déconnexion');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    // ✅ FIX : Sauvegarder TOUTES les photos de tous les users avant clear
    final Map<String, String> photosToKeep = {};
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('profile_image_path_')) {
        final val = prefs.getString(key);
        if (val != null) photosToKeep[key] = val;
      }
    }

    await _tokenService.logout();
    await prefs.clear();

    // ✅ Restaurer toutes les photos + last_user_id
    for (final entry in photosToKeep.entries) {
      await prefs.setString(entry.key, entry.value);
      debugPrint('✅ Photo conservée : ${entry.key}');
    }
    if (userId != 0) {
      await prefs.setInt('last_user_id', userId);
      debugPrint('✅ last_user_id conservé : $userId');
    }

    debugPrint('✅ Déconnexion complète');
  }
}