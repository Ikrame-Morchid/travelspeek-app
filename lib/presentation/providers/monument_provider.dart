import 'package:flutter/material.dart';
import '../../data/models/monument_model.dart';
import '../../data/services/monument_service.dart';
import '../../data/repositories/search_repository.dart';

class MonumentProvider with ChangeNotifier {
  List<Monument> _allMonuments = [];
  List<Monument> _filteredMonuments = [];

  bool _isLoading = false;
  bool _isFuzzySearching = false;
  String? _errorMessage;
  String? _currentFilter;
  String? _searchQuery;
  String currentLanguage = 'fr';

  // État recherche fuzzy
  List<SearchSuggestion> _suggestions = [];
  List<SearchResult> _searchResults = [];
  bool _fuzzyActive = false;

  // Getters standards
  List<Monument> get monuments => _filteredMonuments;
  List<Monument> get allMonuments => _allMonuments;
  bool get isLoading => _isLoading;
  bool get hasMonuments => _allMonuments.isNotEmpty;
  String? get errorMessage => _errorMessage;

  // Getters fuzzy
  bool get isFuzzySearching => _isFuzzySearching;
  bool get fuzzyActive => _fuzzyActive;
  List<SearchSuggestion> get suggestions => _suggestions;
  List<SearchResult> get searchResults => _searchResults;

  // Charger monuments depuis API 
  Future<void> loadMonuments({String lang = 'fr'}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    currentLanguage = lang;
    notifyListeners();

    try {
      final data = await MonumentService.instance.getAllMonuments(lang: lang);
      _allMonuments = data;
      _filteredMonuments = data;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String lang) async {
    if (currentLanguage != lang) await loadMonuments(lang: lang);
  }

  Future<void> refresh() async {
    await loadMonuments(lang: currentLanguage);
  }

  // Recherche locale simple (filtre provider)
  void searchMonuments(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCity(String? city) {
    _currentFilter = city;
    _applyFilters();
  }

  void _applyFilters() {
    List<Monument> result = List.from(_allMonuments);
    if (_currentFilter != null && _currentFilter!.isNotEmpty) {
      result = result.where((m) =>
        m.ville.toLowerCase() == _currentFilter!.toLowerCase()).toList();
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      result = result.where((m) =>
        m.nom.toLowerCase().contains(q) ||
        m.ville.toLowerCase().contains(q) ||
        m.description.toLowerCase().contains(q)).toList();
    }
    _filteredMonuments = result;
    notifyListeners();
  }

  void resetFilters() {
    _currentFilter = null;
    _searchQuery = null;
    _filteredMonuments = List.from(_allMonuments);
    notifyListeners();
  }

  //Recherche fuzzy via API RapidFuzz 
  Future<void> fuzzySearch(String query) async {
    if (query.trim().isEmpty) {
      clearFuzzySearch();
      return;
    }

    // Suggestions live
    _isFuzzySearching = true;
    notifyListeners();

    try {
      final suggestions = await SearchRepository.instance.getSuggestions(query);
      _suggestions = suggestions;
      notifyListeners();

      // Résultats complets
      final results = await SearchRepository.instance.searchMonuments(query);
      _searchResults = results;
      _fuzzyActive = true;
    } catch (_) {
      _fuzzyActive = false;
    } finally {
      _isFuzzySearching = false;
      notifyListeners();
    }
  }

  void selectSuggestion(String nom) async {
    _suggestions = [];
    notifyListeners();
    final results = await SearchRepository.instance.searchMonuments(nom);
    _searchResults = results;
    _fuzzyActive = true;
    notifyListeners();
  }

  void clearFuzzySearch() {
    _suggestions = [];
    _searchResults = [];
    _fuzzyActive = false;
    _isFuzzySearching = false;
    notifyListeners();
  }

  //  Helpers 
  List<String> get cities {
    final Set<String> citySet = {};
    for (var m in _allMonuments) { citySet.add(m.ville); }
    return citySet.toList()..sort();
  }

  Map<String, int> get monumentsByCity {
    final Map<String, int> stats = {};
    for (var m in _allMonuments) {
      stats[m.ville] = (stats[m.ville] ?? 0) + 1;
    }
    return stats;
  }
}