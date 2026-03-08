import 'dart:convert';
import '../models/monument_model.dart';
import 'api_service.dart';

class MonumentService {
  static MonumentService? _instance;
  final ApiService _apiService = ApiService.instance;

  MonumentService._();

  static MonumentService get instance {
    _instance ??= MonumentService._();
    return _instance!;
  }

  // ✅ Récupérer tous les monuments avec langue
  Future<List<Monument>> getAllMonuments({String lang = 'fr'}) async {
    try {
      final response = await _apiService.get(
        '/monuments?lang=$lang',
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        // =============================
        // 🔍 DEBUG - À supprimer après
        // =============================
        print(' Total monuments reçus: ${data.length}');
        for (var item in data.take(5)) {
          print('─────────────────────────────');
          print('🏛️  nom       : ${item['nom']}');
          print('🖼️  image_url : ${item['image_url']}');
          print('📸  images    : ${item['images']}');
        }
        print('─────────────────────────────');
        // =============================

        return data.map((json) => Monument.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load monuments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading monuments: $e');
      return [];
    }
  }

  // ✅ Récupérer un monument par ID avec langue
  Future<Monument?> getMonumentById(int id, {String lang = 'fr'}) async {
    try {
      final response = await _apiService.get(
        '/monuments/$id?lang=$lang',
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // =============================
        // 🔍 DEBUG - À supprimer après
        // =============================
        print('─────────────────────────────');
        print('🏛️  nom       : ${data['nom']}');
        print('🖼️  image_url : ${data['image_url']}');
        print('📸  images    : ${data['images']}');
        print('─────────────────────────────');
        // =============================

        return Monument.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error loading monument: $e');
      return null;
    }
  }

  // ✅ Rechercher monuments avec langue
  Future<List<Monument>> searchMonuments(String query, {String lang = 'fr'}) async {
    try {
      final response = await _apiService.get(
        '/monuments/search?q=$query&lang=$lang',
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Monument.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print(' Error searching monuments: $e');
      return [];
    }
  }
}