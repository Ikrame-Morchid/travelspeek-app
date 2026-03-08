import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_constants.dart';

class ImageTranslationService {
  /// Traduire une image complète (OCR + Détection haine + Traduction)
  Future<Map<String, dynamic>> translateImage({
    required File imageFile,
    required String sourceLang,
    required String targetLang,
    bool enhance = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/image/translate');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Ajouter l'image
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      // Ajouter les paramètres
      request.fields['source_lang'] = sourceLang;
      request.fields['target_lang'] = targetLang;
      request.fields['enhance'] = enhance.toString();
      
      print('Envoi image pour traduction...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Traduction image réussie');
        return data;
      } else {
        print('Erreur ${response.statusCode}: ${response.body}');
        throw Exception('Erreur traduction image: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception traduction image: $e');
      rethrow;
    }
  }

  /// Test OCR uniquement (sans traduction)
  Future<Map<String, dynamic>> testOCR({
    required File imageFile,
    String sourceLang = 'auto',
    bool enhance = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/image/test-ocr');
      
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.fields['source_lang'] = sourceLang;
      request.fields['enhance'] = enhance.toString();
      
      print('🔍 Test OCR...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ OCR réussi: ${data['full_text']}');
        return data;
      } else {
        throw Exception('Erreur OCR: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception OCR: $e');
      rethrow;
    }
  }

  /// Test détection de contenu haineux sur du texte
  Future<Map<String, dynamic>> testToxicity({
    required String text,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/image/test-toxicity');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': text},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Analyse toxicité: ${data['is_offensive']}');
        return data;
      } else {
        throw Exception('Erreur analyse: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception analyse: $e');
      rethrow;
    }
  }

  /// Test traduction de texte simple
  Future<Map<String, dynamic>> testTranslateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/image/test-translate-text');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'text': text,
          'source_lang': sourceLang,
          'target_lang': targetLang,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Traduction: ${data['translated_text']}');
        return data;
      } else {
        throw Exception('Erreur traduction: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception traduction: $e');
      rethrow;
    }
  }
}