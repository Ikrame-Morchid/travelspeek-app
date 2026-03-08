import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';


class SearchSuggestion {
  final String nom;
  final String ville;
  final String? image;

  SearchSuggestion({required this.nom, required this.ville, this.image});

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      nom:   json['nom']   ?? '',
      ville: json['ville'] ?? '',
      image: json['image'] as String?,
    );
  }
}

class SearchResult {
  final String nom;
  final String ville;
  final String description;
  final String? image;
  final String? localisation;
  final List<String> allImages;
  final double score;

  SearchResult({
    required this.nom,
    required this.ville,
    required this.description,
    this.image,
    this.localisation,
    this.allImages = const [],
    this.score = 0,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      nom:          json['nom']          ?? '',
      ville:        json['ville']        ?? '',
      description:  json['description']  ?? '',
      image:        json['image']        as String?,
      localisation: json['localisation'] as String?,
      allImages:    List<String>.from(json['all_images'] ?? []),
      score:        (json['score'] ?? 0).toDouble(),
    );
  }
}

class SearchRepository {
  static final SearchRepository _instance = SearchRepository._();
  static SearchRepository get instance => _instance;
  SearchRepository._();

  // ── Suggestions live (pendant la frappe) ──────────
  Future<List<SearchSuggestion>> getSuggestions(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/search/suggestions')
          .replace(queryParameters: {'q': query.trim(), 'limit': limit.toString()});
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List s = data['suggestions'] ?? [];
        return s.map((e) => SearchSuggestion.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  // Recherche complète
  Future<List<SearchResult>> searchMonuments(String query, {int limit = 20, String? ville}) async {
    if (query.trim().isEmpty) return [];
    try {
      final params = <String, String>{'q': query.trim(), 'limit': limit.toString()};
      if (ville != null) params['ville'] = ville;
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/search/monuments')
          .replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List r = data['results'] ?? [];
        return r.map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  // Liste des villes
  Future<List<String>> getVilles() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/api/search/villes'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return List<String>.from(data['villes'] ?? []);
      }
      return [];
    } catch (_) { return []; }
  }
}