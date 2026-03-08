import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenService {
  static TokenService? _instance;

  static TokenService get instance {
    _instance ??= TokenService._();
    return _instance!;
  }

  TokenService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _accessTokenKey  = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey       = 'user_id';
  static const String _userEmailKey    = 'user_email';


  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      // Secure storage
      await _storage.write(key: _accessTokenKey,  value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      // SharedPreferences en double
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token',  accessToken);
      await prefs.setString('refresh_token', refreshToken);
      debugPrint('Tokens sauvegardés (secure + prefs)');
    } catch (e) {
      debugPrint('Secure storage failed, using SharedPreferences only: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token',  accessToken);
        await prefs.setString('refresh_token', refreshToken);
        debugPrint('Tokens sauvegardés dans SharedPreferences');
      } catch (e2) {
        debugPrint('Erreur sauvegarde tokens: $e2');
      }
    }
  }

  Future<String?> getAccessToken() async {
    try {
      // 1. Essayer secure storage
      final secureToken = await _storage.read(key: _accessTokenKey);
      if (secureToken != null && secureToken.isNotEmpty) {
        debugPrint('Token lu depuis SecureStorage');
        return secureToken;
      }
    } catch (e) {
      debugPrint('SecureStorage read failed: $e');
    }

    // 2. Fallback SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        debugPrint('Token lu depuis SharedPreferences');
        return token;
      }
    } catch (e) {
      debugPrint('SharedPreferences read failed: $e');
    }

    debugPrint('Aucun token trouvé');
    return null;
  }

  Future<String?> getRefreshToken() async {
    try {
      final secureToken = await _storage.read(key: _refreshTokenKey);
      if (secureToken != null && secureToken.isNotEmpty) return secureToken;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (_) {}

    return null;
  }

  Future<void> deleteTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (_) {}

    debugPrint('✅ Tokens supprimés');
  }

  Future<void> saveUserInfo({
    required int userId,
    required String email,
  }) async {
    try {
      await _storage.write(key: _userIdKey,    value: userId.toString());
      await _storage.write(key: _userEmailKey, value: email);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id',      userId);
      await prefs.setString('user_email', email);
    } catch (_) {}

    debugPrint('✅ User info sauvegardées: userId=$userId');
  }

  Future<int?> getUserId() async {
    try {
      final str = await _storage.read(key: _userIdKey);
      if (str != null && str.isNotEmpty) return int.tryParse(str);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id != null) return id;

      // Essayer depuis string
      final idStr = prefs.getString('user_id');
      if (idStr != null) return int.tryParse(idStr);
    } catch (_) {}

    debugPrint(' getUserId: aucun userId trouvé');
    return null;
  }

  Future<String?> getUserEmail() async {
    try {
      final email = await _storage.read(key: _userEmailKey);
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (_) {}

    return null;
  }

  Future<void> deleteUserInfo() async {
    try {
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userEmailKey);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
    } catch (_) {}

    debugPrint(' User info supprimées');
  }


  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await deleteTokens();
    await deleteUserInfo();
    debugPrint('Déconnexion complète');
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    debugPrint(' Tout le storage effacé');
  }
}