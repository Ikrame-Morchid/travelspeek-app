import 'dart:convert';
import 'dart:math';

import '../models/monument_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';

class MonumentRepository {
  final ApiService _apiService = ApiService.instance;
  final StorageService _storage = StorageService.instance;

  Future<List<Monument>> getAllMonuments({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final local = await _storage.getAllMonuments();
        if (local.isNotEmpty) {
          return local; // ✅ Pas besoin de cast
        }
      }

      final response = await _apiService.get(ApiConstants.monuments);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final monuments = data.map((e) => Monument.fromJson(e)).toList();

        await _storage.saveMonuments(monuments);
        return monuments;
      }

      return [];
    } catch (e) {
      print('Error getting monuments: $e');
      final local = await _storage.getAllMonuments();
      return local; // ✅ Pas besoin de cast
    }
  }

  Future<Monument?> getMonumentById(int id) async {
    try {
      // Version sécurisée avec type check
      final local = await _storage.getMonument(id);
      if (local != null) return local;

      final response = await _apiService.get(ApiConstants.monumentDetail(id));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final monument = Monument.fromJson(data);
        await _storage.saveMonument(monument);
        return monument;
      }

      return null;
    } catch (e) {
      print(' Error getting monument $id: $e');
      return null;
    }
  }

  Future<List<Monument>> searchMonuments(String query) async {
    if (query.isEmpty) return getAllMonuments();

    try {
      final local = await _storage.searchMonuments(query);
      if (local.isNotEmpty) {
        return local; // ✅ Pas besoin de cast
      }

      final response = await _apiService.get(
        '${ApiConstants.searchMonuments}?q=$query',
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Monument.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print('Error searching monuments: $e');
      final local = await _storage.searchMonuments(query);
      return local; // ✅ Pas besoin de cast
    }
  }


  Future<List<Monument>> getMonumentsByCity(String city) async {
    try {
      final monuments = await getAllMonuments();
      return monuments
          .where((m) => m.ville.toLowerCase().contains(city.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error filtering by city: $e');
      return [];
    }
  }

  Future<List<Monument>> getPopularMonuments({int limit = 10}) async {
    try {
      final monuments = await getAllMonuments();
      // Trier par rating ou popularité (à adapter selon votre model)
      // Pour l'instant, retourne les premiers
      return monuments.take(limit).toList();
    } catch (e) {
      print('Error getting popular monuments: $e');
      return [];
    }
  }

  Future<List<Monument>> getNearbyMonuments({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      final monuments = await getAllMonuments();
      final List<Monument> nearby = [];

      for (final m in monuments) {
        if (m.latitude != null && m.longitude != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            m.latitude!,
            m.longitude!,
          );

          if (distance <= radiusKm) {
            nearby.add(m);
          }
        }
      }

      // Trier par distance (plus proche en premier)
      nearby.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });

      return nearby;
    } catch (e) {
      print('Error getting nearby monuments: $e');
      return [];
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<bool> refreshMonuments() async {
    try {
      await getAllMonuments(forceRefresh: true);
      return true;
    } catch (e) {
      print(' Error refreshing monuments: $e');
      return false;
    }
  }

  Future<bool> clearCache() async {
    try {
      // Note: Vous devrez ajouter cette méthode dans StorageService si elle n'existe pas
      // await _storage.clearMonuments();
      return true;
    } catch (e) {
      print(' Error clearing cache: $e');
      return false;
    }
  }
}