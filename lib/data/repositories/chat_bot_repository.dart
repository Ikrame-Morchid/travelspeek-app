import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final File? imageFile;
  final List<String>? suggestions;
  final Map<String, dynamic>? weather;
  final Map<String, dynamic>? monument;
  final Map<String, dynamic>? location;
  final String? source;
  final String? transcription;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.imageFile,
    this.suggestions,
    this.weather,
    this.monument,
    this.location,
    this.source,
    this.transcription,
  });
}


class ChatBotRepository {
  // Historique envoyé à chaque requête pour le contexte
  final List<Map<String, String>> _history = [];

  // ── Envoyer un message texte ────────────────────────
  Future<ChatMessage> sendMessage(
    String message, {
    String? city,
    String userId = 'default',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/chatbot/message');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'message': message,
              'city': city,
              'history': _history,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Mettre à jour l'historique
        _history.add({'role': 'user', 'content': message});
        _history.add({'role': 'assistant', 'content': data['reply'] ?? ''});
        if (_history.length > 20) _history.removeRange(0, 2);

        // Extraire image du monument si disponible
        String? monumentImage;
        final monument = data['monument'] as Map<String, dynamic>?;
        if (monument != null) {
          final images = monument['IMAGE'];
          if (images is List && images.isNotEmpty) {
            monumentImage = images[0] as String?;
          }
        }

        return ChatMessage(
          text: data['reply'] ?? 'Désolé, aucune réponse.',
          isUser: false,
          timestamp: DateTime.now(),
          imageUrl: monumentImage,
          weather: data['weather'] as Map<String, dynamic>?,
          monument: monument,
          location: data['location'] as Map<String, dynamic>?,
          source: data['source'] as String?,
        );
      }

      // Gérer les erreurs HTTP
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Impossible de joindre le serveur. Vérifiez votre connexion.');
    } on http.ClientException {
      throw Exception('Erreur réseau. Réessayez.');
    } catch (e) {
      rethrow;
    }
  }

  // Envoyer un fichier audio
  Future<ChatMessage> sendAudio(
    File audioFile, {
    String? city,
    String userId = 'default',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/chatbot/audio');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );
      if (city != null) request.fields['city'] = city;
      request.fields['user_id'] = userId;

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        String? monumentImage;
        final monument = data['monument'] as Map<String, dynamic>?;
        if (monument != null) {
          final images = monument['IMAGE'];
          if (images is List && images.isNotEmpty) {
            monumentImage = images[0] as String?;
          }
        }

        return ChatMessage(
          text: data['reply'] ?? 'Désolé, aucune réponse.',
          isUser: false,
          timestamp: DateTime.now(),
          imageUrl: monumentImage,
          transcription: data['transcription'] as String?,
          weather: data['weather'] as Map<String, dynamic>?,
          monument: monument,
          location: data['location'] as Map<String, dynamic>?,
          source: data['source'] as String?,
        );
      }

      throw Exception('Erreur audio ${response.statusCode}');
    } on SocketException {
      throw Exception('Impossible de joindre le serveur.');
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier quota utilisateur
  Future<Map<String, dynamic>> getUsage(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/chatbot/usage/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return {'remaining': 0, 'limit': 50, 'allowed': false};
    } catch (e) {
      return {'remaining': 0, 'limit': 50, 'allowed': false};
    }
  }

  // Vider l'historique
  void clearHistory() => _history.clear();
}