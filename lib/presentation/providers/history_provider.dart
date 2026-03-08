import 'package:flutter/foundation.dart';
import '../../data/models/historique_model.dart';
import '../../data/repositories/history_repository.dart';

class HistoryProvider with ChangeNotifier {
  final HistoryRepository _repository = HistoryRepository();

  List<Historique> _history = [];
  Map<String, List<Historique>> _groupedHistory = {};
  bool _isLoading = false;
  String? _errorMessage;
  ActivityType? _filterType;
  String _searchQuery = '';

  List<Historique> get history {
    var filtered = _history;
    if (_filterType != null) {
      filtered = filtered.where((h) => h.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((h) {
        return h.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (h.subtitle?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }
    return filtered;
  }

  Map<String, List<Historique>> get groupedHistory => _groupedHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ActivityType? get filterType => _filterType;
  String get searchQuery => _searchQuery;
  bool get hasHistory => _history.isNotEmpty;
  int get historyCount => _history.length;

  // ✅ Vider l'historique en mémoire (appelé au login autre user)
  void clearHistory() {
    _history = [];
    _groupedHistory = {};
    notifyListeners();
  }

  Future<void> loadHistory() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _history = await _repository.getAllHistory();
      _groupedHistory = await _repository.getGroupedHistory();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading history: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToHistory(Historique item) async {
    final success = await _repository.addToHistory(item);
    if (success) {
      _history.insert(0, item);
      await _updateGroupedHistory();
      notifyListeners();
    }
    return success;
  }

  Future<bool> addTranslationToHistory({
    required String sourceText,
    required String translatedText,
    required String sourceLang,
    required String targetLang,
  }) async {
    final success = await _repository.addTranslationToHistory(
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
    if (success) await loadHistory();
    return success;
  }

  Future<bool> addMonumentToHistory({
    required int monumentId,
    required String monumentName,
    required String location,
    String? imageUrl,
  }) async {
    final success = await _repository.addMonumentToHistory(
      monumentId: monumentId,
      monumentName: monumentName,
      location: location,
      imageUrl: imageUrl,
    );
    if (success) await loadHistory();
    return success;
  }

  Future<bool> addSearchToHistory({
    required String query,
    int? resultCount,
  }) async {
    final success = await _repository.addSearchToHistory(
      query: query,
      resultCount: resultCount,
    );
    if (success) await loadHistory();
    return success;
  }

  Future<List<Historique>> getRecentHistory({int limit = 5}) async {
    try {
      return await _repository.getRecentHistory(limit: limit);
    } catch (e) {
      debugPrint('Error getting recent history: $e');
      return [];
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setFilter(ActivityType? type) {
    _filterType = type;
    notifyListeners();
  }

  void clearFilter() {
    _filterType = null;
    notifyListeners();
  }

  Future<bool> toggleFavorite(Historique item) async {
    final success = await _repository.toggleFavorite(item);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteItem(Historique item) async {
    final success = await _repository.deleteHistoryItem(item.id);
    if (success) {
      _history.remove(item);
      await _updateGroupedHistory();
      notifyListeners();
    }
    return success;
  }

  Future<bool> clearByType(ActivityType type) async {
    final success = await _repository.clearHistoryByType(type);
    if (success) {
      _history.removeWhere((item) => item.type == type);
      await _updateGroupedHistory();
      notifyListeners();
    }
    return success;
  }

  Future<bool> clearAll() async {
    final success = await _repository.clearAllHistory();
    if (success) {
      _history.clear();
      _groupedHistory.clear();
      notifyListeners();
    }
    return success;
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      return await _repository.getHistoryStatistics();
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  Future<void> _updateGroupedHistory() async {
    _groupedHistory = await _repository.getGroupedHistory();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}