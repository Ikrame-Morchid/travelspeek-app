import 'dart:convert';
import '../models/favorite_model.dart';
import '../models/monument_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/token_service.dart';
import '../../core/constants/api_constants.dart';

class FavoriteRepository {
  final ApiService _apiService = ApiService.instance;
  final StorageService _storageService = StorageService.instance;
  final TokenService _tokenService = TokenService.instance;

  // === GET USER FAVORITES ===
  Future<List<Monument>> getUserFavorites() async {
    try {
      final int? userId = await _tokenService.getUserId();
      if (userId == null) {
        print(' getUserFavorites: userId NULL');
        return [];
      }

      print('GET /favoris pour userId: $userId');
      final response = await _apiService.get(ApiConstants.favorites);
      print('GET /favoris status: ${response.statusCode}');
      print('GET /favoris body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Monument> monuments = [];
        for (final favoriteJson in data) {
          if (favoriteJson['monument'] != null) {
            monuments.add(Monument.fromJson(favoriteJson['monument']));
          }
        }
        print(' ${monuments.length} favoris chargés');
        return monuments;
      }
      return [];
    } catch (e) {
      print(' Exception getUserFavorites: $e');
      // Fallback local
      try {
        final int? userId = await _tokenService.getUserId();
        if (userId == null) return [];
        final favorites = await _storageService.getUserFavorites(userId);
        final List<Monument> monuments = [];
        for (final fav in favorites) {
          final Monument? monument =
              await _storageService.getMonument(fav.monumentId);
          if (monument != null) monuments.add(monument);
        }
        print(' ${monuments.length} favoris depuis cache local');
        return monuments;
      } catch (_) {
        return [];
      }
    }
  }

  // === ADD TO FAVORITES ===
  Future<bool> addToFavorites(int monumentId) async {
    try {
      final int? userId = await _tokenService.getUserId();
      if (userId == null) {
        print(' addToFavorites: userId NULL');
        return false;
      }

      final token = await _tokenService.getAccessToken();
      print('TOKEN: $token');
      print(' POST /favoris avec monument_id: $monumentId');

      final response = await _apiService.post(
        ApiConstants.favorites,
        {'monument_id': monumentId},
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Favoris favorite = Favoris.create(
          userId: userId,
          monumentId: monumentId,
        );
        await _storageService.addFavorite(favorite);
        print('Favori ajouté: monumentId=$monumentId');
        return true;
      }
      return false;
    } catch (e) {
      print('Exception addToFavorites: $e');
      return false;
    }
  }

  // === REMOVE FROM FAVORITES ===
  Future<bool> removeFromFavorites(int monumentId) async {
    try {
      final int? userId = await _tokenService.getUserId();
      if (userId == null) {
        print('removeFromFavorites: userId NULL');
        return false;
      }

      print('DELETE /favoris/$monumentId');
      final response = await _apiService.delete(
        ApiConstants.removeFavorite(monumentId),
      );

      print('DELETE status: ${response.statusCode}');
      print('DELETE body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _storageService.removeFavorite(userId, monumentId);
        print('Favori supprimé: monumentId=$monumentId');
        return true;
      }
      return false;
    } catch (e) {
      print('Exception removeFromFavorites: $e');
      return false;
    }
  }

  // CHECK IF FAVORITE 
  Future<bool> isFavorite(int monumentId) async {
    try {
      final int? userId = await _tokenService.getUserId();
      if (userId == null) return false;
      return await _storageService.isFavorite(userId, monumentId);
    } catch (e) {
      print('Exception isFavorite: $e');
      return false;
    }
  }

  // === TOGGLE FAVORITE ===
  Future<bool> toggleFavorite(int monumentId) async {
    final bool isFav = await isFavorite(monumentId);
    print('toggleFavorite: isFav=$isFav pour monumentId=$monumentId');
    if (isFav) {
      return await removeFromFavorites(monumentId);
    } else {
      return await addToFavorites(monumentId);
    }
  }
}