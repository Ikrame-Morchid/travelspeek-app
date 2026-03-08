import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/audio_recorder_service.dart';
import '../services/audio_player_service.dart';



const String kBaseUrl = "http://192.168.11.102:8000";


class HateSpeechResult {
  final bool         isHateSpeech;
  final double       confidence;
  final String       level;          // 'safe' | 'warning' | 'danger'
  final List<String> categories;
  final List<String> offensiveWords;
  final String       censoredText;
  final String       message;

  const HateSpeechResult({
    required this.isHateSpeech,
    required this.confidence,
    required this.level,
    required this.categories,
    required this.offensiveWords,
    required this.censoredText,
    required this.message,
  });

  /// Depuis /api/image/test-toxicity
  factory HateSpeechResult.fromJson(Map<String, dynamic> json) {
    final isOffensive = json['is_offensive'] ?? false;
    final mainCat     = json['main_category'] ?? 'none';
    return HateSpeechResult(
      isHateSpeech:  isOffensive,
      level:         isOffensive ? 'danger' : 'safe',
      confidence:    (json['toxicity'] as num?)?.toDouble()
                         ?? (isOffensive ? 0.95 : 0.02),
      message:       json['message'] ?? (isOffensive
          ? ' Ce texte contient du contenu haineux.'
          : 'Le texte ne contient aucun contenu haineux.'),
      categories:    (mainCat != 'none' && mainCat.isNotEmpty)
          ? [mainCat] : [],
      offensiveWords: List<String>.from(json['offensive_words'] ?? []),
      censoredText:   json['censored_text'] ?? '',
    );
  }

  factory HateSpeechResult.safe() => const HateSpeechResult(
    isHateSpeech:   false,
    level:          'safe',
    confidence:     0.02,
    categories:     [],
    offensiveWords: [],
    censoredText:   '',
    message:        'Le texte ne contient aucun contenu haineux.',
  );

  bool get isSafe    => level == 'safe';
  bool get isWarning => level == 'warning';
  bool get isDanger  => level == 'danger';
}

class VoiceTranslationResult {
  final String       originalText;
  final String       translatedText;
  final String       detectedLanguage;
  final String       targetLanguage;
  final String?      audioUrl;
  final HateSpeechResult?             hateSpeech;
  final List<Map<String, dynamic>>    segments;

  const VoiceTranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.detectedLanguage,
    required this.targetLanguage,
    this.audioUrl,
    this.hateSpeech,
    this.segments = const [],
  });

  factory VoiceTranslationResult.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['audio_url'] as String?;
    final fullUrl = rawUrl != null
        ? (rawUrl.startsWith('http') ? rawUrl : '$kBaseUrl$rawUrl')
        : null;
    return VoiceTranslationResult(
      originalText:     json['original_text']     ?? '',
      translatedText:   json['translated_text']   ?? '',
      detectedLanguage: json['detected_language'] ?? 'unknown',
      targetLanguage:   json['target_language']   ?? 'fr',
      audioUrl:         fullUrl,
      hateSpeech:       json['hate_speech'] != null
          ? HateSpeechResult.fromJson(json['hate_speech'])
          : null,
      segments: List<Map<String, dynamic>>.from(json['segments'] ?? []),
    );
  }
}


class VoiceTranslationRepository {
  final AudioRecorderService _recorder = AudioRecorderService();
  final AudioPlayerService   _player   = AudioPlayerService();

  final Dio _dio = Dio(BaseOptions(
    baseUrl:        kBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  // Enregistrement 

  Future<void> startRecording() async {
    await _recorder.startRecording();
  }

  Future<File?> stopRecording() async {
    final path = await _recorder.stopRecording();
    if (path == null) return null;
    return File(path);
  }

  //  Pipeline complet 

  Future<VoiceTranslationResult> stopAndTranslate(
    String targetLang, {
    bool checkHateSpeech = false,
    bool censorOutput    = false,
  }) async {
    final audioFile = await stopRecording();
    if (audioFile == null || !audioFile.existsSync()) {
      throw Exception('Aucun fichier audio enregistré.');
    }

    // 1. Traduction vocale
    final result = await translateAudio(
      audioFilePath:   audioFile.path,
      targetLang:      targetLang,
      checkHateSpeech: checkHateSpeech,
      censorOutput:    censorOutput,
    );

    if (result == null) {
      throw Exception('Échec de la traduction vocale.');
    }

    return result;
  }

  // Envoi audio au backend 

  Future<VoiceTranslationResult?> translateAudio({
    required String audioFilePath,
    required String targetLang,
    String sourceLang       = 'auto',
    bool   checkHateSpeech  = false,
    bool   censorOutput     = false,
  }) async {
    try {
      debugPrint('Envoi audio : $audioFilePath');

      if (!await File(audioFilePath).exists()) {
        debugPrint('Fichier audio inexistant');
        return null;
      }

      final formData = FormData.fromMap({
        'audio':             await MultipartFile.fromFile(
                                 audioFilePath, filename: 'audio.m4a'),
        'target_lang':       targetLang,
        'source_lang':       sourceLang,
        'return_audio':      'true',
        'check_hate_speech': checkHateSpeech.toString(),
        'censor_output':     censorOutput.toString(),
      });

      final response =
          await _dio.post('/api/voice/translate', data: formData);

      debugPrint('Réponse : ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = VoiceTranslationResult.fromJson(
            response.data as Map<String, dynamic>);

        // Analyse hate speech si demandée et pas encore faite par le backend
        if (checkHateSpeech && result.hateSpeech == null) {
          final hate = await _analyzeHateSpeech(result.translatedText);
          String finalText = result.translatedText;
          if (censorOutput && hate.isHateSpeech &&
              hate.censoredText.isNotEmpty) {
            finalText = hate.censoredText;
          }
          return VoiceTranslationResult(
            originalText:     result.originalText,
            translatedText:   finalText,
            detectedLanguage: result.detectedLanguage,
            targetLanguage:   result.targetLanguage,
            audioUrl:         result.audioUrl,
            hateSpeech:       hate,
            segments:         result.segments,
          );
        }

        return result;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('DioException : ${e.message}');
      debugPrint('Response : ${e.response?.data}');
      rethrow;
    }
  }

  // ── Analyse hate speech ──────────────────────────────────────

  Future<HateSpeechResult> _analyzeHateSpeech(String text) async {
    try {
      final response = await _dio.post(
        '/api/image/test-toxicity',
        data:        {'text': text},
        options:     Options(contentType: 'application/x-www-form-urlencoded'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return HateSpeechResult.fromJson(
            response.data as Map<String, dynamic>);
      }
      return HateSpeechResult.safe();
    } catch (_) {
      return HateSpeechResult.safe();
    }
  }

  // Lecture audio 

  Future<void> playAudio(String audioUrl) async {
    final fullUrl = audioUrl.startsWith('http')
        ? audioUrl
        : '$kBaseUrl$audioUrl';
    debugPrint('🔊 Lecture : $fullUrl');
    await _player.playFromUrl(fullUrl);
  }

  Future<void> stopAudio() async => _player.stop();

  //  Health check 

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/voice/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}