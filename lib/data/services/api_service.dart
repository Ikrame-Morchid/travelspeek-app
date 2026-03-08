// lib/data/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'token_service.dart';

class ApiService {
  static ApiService? _instance;
  final TokenService _tokenService = TokenService.instance;

  ApiService._();

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _tokenService.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String endpoint) => endpoint.startsWith('http')
      ? Uri.parse(endpoint)
      : Uri.parse('${ApiConstants.baseUrl}$endpoint');

  // ── Auto-refresh sur 401 ──────────────────────────
  // Si une requête retourne 401, on tente de refresh le token
  // puis on relance la requête une seule fois.
  Future<http.Response> _withAutoRefresh(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool requiresAuth = true,
  }) async {
    final headers = await _headers(requiresAuth: requiresAuth);
    var response = await request(headers);

    // Si 401 → essayer de refresh le token
    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Relancer la requête avec le nouveau token
        final newHeaders = await _headers(requiresAuth: true);
        response = await request(newHeaders);
      }
    }

    return response;
  }

  // Refresh token 
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;

      final url = _uri(ApiConstants.refreshToken);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(ApiConstants.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess  = data['access_token']  as String?;
        final newRefresh = data['refresh_token'] as String?;

        if (newAccess != null) {
          await _tokenService.saveTokens(
            accessToken:  newAccess,
            refreshToken: newRefresh ?? refreshToken,
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // GET 
  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final url = _uri(endpoint);
    return _withAutoRefresh(
      (headers) => http.get(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout),
      requiresAuth: requiresAuth,
    );
  }

  // POST 
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final url = _uri(endpoint);
    final encoded = jsonEncode(body);
    return _withAutoRefresh(
      (headers) => http.post(url, headers: headers, body: encoded)
          .timeout(ApiConstants.connectionTimeout),
      requiresAuth: requiresAuth,
    );
  }

  // PUT 
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    final url = _uri(endpoint);
    final encoded = jsonEncode(body);
    return _withAutoRefresh(
      (headers) => http.put(url, headers: headers, body: encoded)
          .timeout(ApiConstants.connectionTimeout),
      requiresAuth: requiresAuth,
    );
  }

  // DELETE 
  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    final url = _uri(endpoint);
    return _withAutoRefresh(
      (headers) => http.delete(url, headers: headers)
          .timeout(ApiConstants.connectionTimeout),
      requiresAuth: requiresAuth,
    );
  }

  // MULTIPART 
  Future<http.MultipartRequest> multipartRequest(
      String method, Uri uri) async {
    final request = http.MultipartRequest(method, uri);
    final token = await _tokenService.getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }

  // Error handling
  void handleError(http.Response response) {
    switch (response.statusCode) {
      case 400: throw Exception('Bad Request: ${response.body}');
      case 401: throw Exception('Unauthorized: Token invalide ou expiré');
      case 403: throw Exception('Forbidden: Accès refusé');
      case 404: throw Exception('Not Found: Ressource introuvable');
      case 500: throw Exception('Server Error: Erreur serveur');
      default:  throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Map<String, dynamic> parseJsonResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    handleError(response);
    return {};
  }

  List<dynamic> parseJsonListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    handleError(response);
    return [];
  }
}