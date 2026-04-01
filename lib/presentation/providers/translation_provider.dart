import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Importez votre classe VoiceTranslationResult depuis le cubit
// Si vous séparez les modèles, créez un fichier models/voice_translation_result.dart
class VoiceTranslationResult {
  final String originalText;
  final String translatedText;
  final String detectedLanguage;
  final String targetLanguage;
  final String? audioUrl;

  VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.detectedLanguage,
    required this.targetLanguage,
    this.audioUrl,
  });

  factory VoiceTranslationResult.fromJson(Map<String, dynamic> json) {
    return VoiceTranslationResult(
      originalText: json['original_text'] ?? '',
      translatedText: json['translated_text'] ?? '',
      detectedLanguage: json['detected_language'] ?? 'unknown',
      targetLanguage: json['target_language'] ?? 'unknown',
      audioUrl: json['audio_url'],
    );
  }
}

class TranslationRepository {

  static const String BASE_URL = "http://100.81.116.14:8000";
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: BASE_URL,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Traduire un fichier audio
  Future<VoiceTranslationResult?> translateAudio({
    required String audioFilePath,
    required String targetLang,
  }) async {
    try {
      debugPrint("Envoi de l'audio : $audioFilePath");
      debugPrint("Langue cible : $targetLang");

      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint("Fichier audio inexistant");
        return null;
      }

      final formData = FormData.fromMap({
        'audio_file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.wav',
        ),
        'target_lang': targetLang,
      });

      final response = await _dio.post(
        '/api/voice/translate',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      debugPrint("Réponse backend : ${response.statusCode}");
      debugPrint("Données : ${response.data}");

      if (response.statusCode == 200) {
        final result = VoiceTranslationResult.fromJson(response.data);
        
        // Convertir l'URL relative en URL complète
        if (result.audioUrl != null && !result.audioUrl!.startsWith('http')) {
          final fullAudioUrl = '$BASE_URL${result.audioUrl}';
          return VoiceTranslationResult(
            originalText: result.originalText,
            translatedText: result.translatedText,
            detectedLanguage: result.detectedLanguage,
            targetLanguage: result.targetLanguage,
            audioUrl: fullAudioUrl,
          );
        }
        
        return result;
      }

      return null;
    } on DioException catch (e) {
      debugPrint("Erreur Dio : ${e.message}");
      debugPrint("Type : ${e.type}");
      if (e.response != null) {
        debugPrint("Réponse erreur : ${e.response?.data}");
      }
      rethrow;
    } catch (e) {
      debugPrint("Erreur inconnue : $e");
      rethrow;
    }
  }

  /// Récupérer les langues supportées
  Future<List<Map<String, String>>> getSupportedLanguages() async {
    try {
      final response = await _dio.get('/api/voice/languages');
      
      if (response.statusCode == 200) {
        final List<dynamic> langs = response.data['languages'];
        return langs.map((lang) => {
          'code': lang['code'] as String,
          'name': lang['name'] as String,
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint(" Erreur chargement langues : $e");
      return [];
    }
  }

  /// Vérifier la santé du backend
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/voice/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint(" Backend non accessible : $e");
      return false;
    }
  }
}