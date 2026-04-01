class ApiConstants {
  ApiConstants._();
 
  static const String baseUrl = 'http://100.81.116.14:8000';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // =========================
  // AUTH ENDPOINTS
  // =========================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String updateProfile = '/users/me';
  static const String changePassword = '/users/me/password';
  
  // =========================
  // MONUMENTS ENDPOINTS
  // =========================
  static const String monuments = '/monuments';
  static String monumentDetail(int id) => '/monuments/$id';
  static const String searchMonuments = '/monuments/search';
  
  // =========================
  // FAVORITES ENDPOINTS  
  // =========================
  static const String favorites = '/favoris';
  static String addFavorite(int monumentId) => '/favoris';
  static String removeFavorite(int monumentId) => '/favoris/$monumentId';
  static String checkFavorite(int monumentId) => '/favoris/$monumentId/check';
  
  // =========================
  // COMMENTS ENDPOINTS
  // =========================
  static String monumentComments(int monumentId) => '/commentaires/monument/$monumentId';
  static const String addComment = '/commentaires';
  static String updateComment(int commentId) => '/commentaires/$commentId';
  static String deleteComment(int commentId) => '/commentaires/$commentId';
  
  // =========================
  // TRANSLATION ENDPOINTS
  // =========================
  static const String translateText = '/translations';
  static const String translateVoice = '/translations';
  static const String translateImage = '/translations';
  static const String supportedLanguages = '/translation/languages';
  
  // =========================
  // CHATBOT ENDPOINTS
  // =========================
  static const String chatbot = '/chatbot/message';
  static const String chatbotSuggestions = '/chatbot/suggestions';
  static const String chatbotMonument = '/chatbot/monument';
  static const String chatbotRecommendations = '/chatbot/recommendations';
  
  // =========================
  // HISTORY ENDPOINTS
  // =========================
  static const String history = '/history';
  static String historyItem(int id) => '/history/$id';
  
  // =========================
  // ML ENDPOINTS (Future)
  // =========================
  static const String recognizeMonument = '/ml/recognize';
  static const String detectLanguage = '/ml/detect-language';
  
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}