import 'dart:io';
import '../services/image_translation_service.dart';


class ImageTranslationResult {
  final String extractedText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final bool hasOffensiveContent;
  final String hateSpeechMessage;
  final List<String> offensiveWords;
  final String censoredText;
  final int totalBlocks;
  final DateTime timestamp;

  ImageTranslationResult({
    required this.extractedText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.hasOffensiveContent,
    required this.hateSpeechMessage,
    required this.offensiveWords,
    required this.censoredText,
    required this.totalBlocks,
    required this.timestamp,
  });

  factory ImageTranslationResult.fromJson(Map<String, dynamic> json) {
    return ImageTranslationResult(
      extractedText:       json['extracted_text']        ?? '',
      translatedText:      json['translated_text']       ?? '',
      sourceLang:          json['source_lang']           ?? 'auto',
      targetLang:          json['target_lang']           ?? 'fr',
      hasOffensiveContent: json['has_offensive_content'] ?? false,
      hateSpeechMessage:   json['hate_speech_message']   ?? '',
      offensiveWords:      List<String>.from(json['offensive_words'] ?? []),
      censoredText:        json['censored_text']         ?? '',
      totalBlocks:         json['total_blocks']          ?? 0,
      timestamp:           DateTime.now(),
    );
  }
}


class ImageTranslationRepository {
  final ImageTranslationService _service = ImageTranslationService();

  final List<ImageTranslationResult> _history = [];
  List<ImageTranslationResult> get history => List.unmodifiable(_history);

  /// Pipeline complet : Image → OCR → Analyse haine → Traduction
  Future<ImageTranslationResult> translateImage({
    required File imageFile,
    required String sourceLang,
    required String targetLang,
    bool enhance = true,
  }) async {
    final response = await _service.translateImage(
      imageFile:  imageFile,
      sourceLang: sourceLang,
      targetLang: targetLang,
      enhance:    enhance,
    );

    final result = ImageTranslationResult.fromJson(response);

    _history.insert(0, result);
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }

    return result;
  }

  /// Test OCR uniquement
  Future<Map<String, dynamic>> testOCR({
    required File imageFile,
    String sourceLang = 'auto',
    bool enhance = true,
  }) async {
    return await _service.testOCR(
      imageFile:  imageFile,
      sourceLang: sourceLang,
      enhance:    enhance,
    );
  }

  void clearHistory() => _history.clear();

  void removeFromHistory(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
    }
  }
}