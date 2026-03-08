import 'package:flutter/foundation.dart';
import '../../data/models/monument_model.dart';
import '../../data/repositories/favorite_repository.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteRepository _favoriteRepository = FavoriteRepository();

  List<Monument> _favorites = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Monument> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get favoritesCount => _favorites.length;
  bool get hasFavorites => _favorites.isNotEmpty;

  bool isFavorite(int monumentId) {
    return _favoriteIds.contains(monumentId);
  }

  Future<void> loadFavorites() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final List<Monument> favorites =
          await _favoriteRepository.getUserFavorites();

      _favorites = favorites;
      _favoriteIds = favorites.map((m) => m.id).toSet();
    } catch (e) {
      _errorMessage = 'Erreur de chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToFavorites(Monument monument) async {
    if (_favoriteIds.contains(monument.id)) return true;

    _favorites.add(monument);
    _favoriteIds.add(monument.id);
    notifyListeners();

    final bool success =
        await _favoriteRepository.addToFavorites(monument.id);

    if (!success) {
      _favorites.removeWhere((m) => m.id == monument.id);
      _favoriteIds.remove(monument.id);
      _errorMessage = 'Impossible d\'ajouter aux favoris';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> removeFromFavorites(int monumentId) async {
    Monument? removedMonument;

    for (final m in _favorites) {
      if (m.id == monumentId) {
        removedMonument = m;
        break;
      }
    }

    _favorites.removeWhere((m) => m.id == monumentId);
    _favoriteIds.remove(monumentId);
    notifyListeners();

    final bool success =
        await _favoriteRepository.removeFromFavorites(monumentId);

    if (!success) {
      if (removedMonument != null) {
        _favorites.add(removedMonument);
        _favoriteIds.add(monumentId);
      }
      _errorMessage = 'Impossible de retirer des favoris';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> toggleFavorite(Monument monument) async {
    if (isFavorite(monument.id)) {
      return await removeFromFavorites(monument.id);
    } else {
      return await addToFavorites(monument);
    }
  }

  Future<void> refreshFavoriteStatus(int monumentId) async {
    try {
      final bool isFav =
          await _favoriteRepository.isFavorite(monumentId);

      if (isFav && !_favoriteIds.contains(monumentId)) {
        _favoriteIds.add(monumentId);
        notifyListeners();
      } else if (!isFav && _favoriteIds.contains(monumentId)) {
        _favoriteIds.remove(monumentId);
        _favorites.removeWhere((m) => m.id == monumentId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur refresh favorite status: $e');
    }
  }

  void clearFavorites() {
    _favorites.clear();
    _favoriteIds.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadFavorites();
  }
}
