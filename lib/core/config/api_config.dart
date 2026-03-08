// lib/core/config/api_config.dart

class ApiConfig {
  /// REMPLACEZ par l'IP de votre ordinateur
  static const String baseUrl = 'http://192.168.11.102:8000';
  
  // ===== AUTH ENDPOINTS =====
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String verifyEmail = '$baseUrl/auth/verify-email';
  static const String resendVerification = '$baseUrl/auth/resend-verification';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String deleteAccount = '$baseUrl/auth/delete-account';
  
  // ===== HEADERS =====
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}