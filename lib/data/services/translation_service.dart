import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/translation_cache.dart';

class TranslationService {
  static const String _endpoint = 'https://libretranslate.com/translate';
  
  final Isar isar;
  
  TranslationService(this.isar);

  Future<String> translate({
    required String text,
    required String fromLang,
    required String toLang,
    String? cacheKey,
  }) async {
    if (text.isEmpty) return text;
    if (fromLang == toLang) return text;
    
    if (cacheKey != null) {
      final cached = await _getFromCache(cacheKey);
      if (cached != null) return cached;
    }
    
    final translated = await _callLibreTranslateAPI(text, fromLang, toLang);
    
    if (cacheKey != null && translated != null) {
      await _saveToCache(cacheKey, translated);
    }
    
    return translated ?? text;
  }

  Future<String?> _getFromCache(String key) async {
    final cached = await isar.translationCaches
        .filter()
        .keyEqualTo(key)
        .findFirst();
    
    return cached?.translatedText;
  }

  Future<void> _saveToCache(String key, String translatedText) async {
    final cache = TranslationCache()
      ..key = key
      ..translatedText = translatedText
      ..lastUpdated = DateTime.now();
    
    await isar.writeTxn(() async {
      await isar.translationCaches.put(cache);
    });
  }

  Future<String?> _callLibreTranslateAPI(String text, String from, String to) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': from,
          'target': to,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        return result['translatedText'];
      } else {
        print('LibreTranslate API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Translation error: $e');
      return null;
    }
  }

  Future<Map<String, String>> batchTranslate({
    required List<String> texts,
    required String fromLang,
    required String toLang,
    String? keyPrefix,
  }) async {
    final Map<String, String> results = {};
    
    for (int i = 0; i < texts.length; i++) {
      final cacheKey = keyPrefix != null ? '${keyPrefix}_$i' : null;
      results[texts[i]] = await translate(
        text: texts[i],
        fromLang: fromLang,
        toLang: toLang,
        cacheKey: cacheKey,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.translationCaches.clear();
    });
  }

  Future<int> getCacheSize() async {
    return await isar.translationCaches.count();
  }
}