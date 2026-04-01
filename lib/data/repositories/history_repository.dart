import 'package:shared_preferences/shared_preferences.dart';
import '../models/historique_model.dart';
import '../services/storage_service.dart';

class HistoryRepository {
  final StorageService _storage = StorageService.instance;

  // ✅ Récupérer userId depuis SharedPreferences
  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  Future<bool> addToHistory(Historique item) async {
    try {
      // ✅ Toujours associer l'item au user courant
      final userId = await _getCurrentUserId();
      item.userId = userId;
      await _storage.saveHistoryItem(item);
      return true;
    } catch (e) {
      print('Error adding to history: $e');
      return false;
    }
  }

  Future<bool> addTranslationToHistory({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
    bool isImageTranslation = false,
  }) async {
    final userId = await _getCurrentUserId();
    final item = Historique.create(
      type: ActivityType.translation,
      userId: userId,
      title: sourceText,
      subtitle: isImageTranslation
          ? '$sourceLang → $targetLang [IMG]'
          : '$sourceLang → $targetLang',
      details: translatedText,
    );
    return await addToHistory(item);
  }

  Future<bool> addMonumentToHistory({
    required int monumentId,
    required String monumentName,
    required String location,
    String? imageUrl,
  }) async {
    final userId = await _getCurrentUserId();
    final item = Historique.create(
      type: ActivityType.monument,
      userId: userId,
      title: monumentName,
      subtitle: location,
      resourceId: monumentId,
      imageUrl: imageUrl,
    );
    return await addToHistory(item);
  }

  Future<bool> addSearchToHistory({
    required String query,
    int? resultCount,
  }) async {
    final userId = await _getCurrentUserId();
    final item = Historique.create(
      type: ActivityType.search,
      userId: userId,
      title: query,
      subtitle: resultCount != null ? '$resultCount results' : null,
    );
    return await addToHistory(item);
  }

  // ✅ Toutes les méthodes filtrent par userId
  Future<List<Historique>> getAllHistory() async {
    try {
      final userId = await _getCurrentUserId();
      final items = await _storage.getHistoryByUser(userId);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  Future<List<Historique>> getHistoryByType(ActivityType type) async {
    try {
      final all = await getAllHistory();
      return all.where((item) => item.type == type).toList();
    } catch (e) {
      print('Error filtering history: $e');
      return [];
    }
  }

  Future<Map<String, List<Historique>>> getGroupedHistory() async {
    try {
      final all = await getAllHistory();
      final Map<String, List<Historique>> grouped = {};
      for (final item in all) {
        final section = item.dateSection;
        if (!grouped.containsKey(section)) grouped[section] = [];
        grouped[section]!.add(item);
      }
      return grouped;
    } catch (e) {
      print('Error grouping history: $e');
      return {};
    }
  }

  Future<List<Historique>> getRecentHistory({int limit = 10}) async {
    try {
      final all = await getAllHistory();
      return all.take(limit).toList();
    } catch (e) {
      print('Error getting recent history: $e');
      return [];
    }
  }

  Future<List<Historique>> searchHistory(String query) async {
    try {
      final all = await getAllHistory();
      final lowerQuery = query.toLowerCase();
      return all.where((item) {
        return item.title.toLowerCase().contains(lowerQuery) ||
            (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching history: $e');
      return [];
    }
  }

  Future<bool> toggleFavorite(Historique item) async {
    try {
      item.isFavorite = !item.isFavorite;
      await _storage.saveHistoryItem(item);
      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<bool> deleteHistoryItem(int id) async {
    try {
      await _storage.deleteHistoryItem(id);
      return true;
    } catch (e) {
      print('Error deleting history item: $e');
      return false;
    }
  }

  Future<bool> clearHistoryByType(ActivityType type) async {
    try {
      final items = await getHistoryByType(type);
      for (final item in items) {
        await _storage.deleteHistoryItem(item.id);
      }
      return true;
    } catch (e) {
      print('Error clearing history by type: $e');
      return false;
    }
  }

  Future<bool> clearAllHistory() async {
    try {
      // ✅ Vider seulement l'historique du user courant
      final userId = await _getCurrentUserId();
      await _storage.clearHistoryByUser(userId);
      return true;
    } catch (e) {
      print('Error clearing all history: $e');
      return false;
    }
  }

  Future<Map<String, int>> getHistoryStatistics() async {
    try {
      final all = await getAllHistory();
      return {
        'total': all.length,
        'translations': all.where((i) => i.type == ActivityType.translation).length,
        'monuments': all.where((i) => i.type == ActivityType.monument).length,
        'searches': all.where((i) => i.type == ActivityType.search).length,
        'favorites': all.where((i) => i.isFavorite).length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }
}