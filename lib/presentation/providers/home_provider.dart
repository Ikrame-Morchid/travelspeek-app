import 'package:flutter/material.dart';

class HomeProvider with ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;
  String _userName = 'User';
  List<Monument> _popularMonuments = [];
  List<Monument> _recentMonuments = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  List<Monument> get popularMonuments => _popularMonuments;
  List<Monument> get recentMonuments => _recentMonuments;

  Future<void> loadMockData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simuler un délai de chargement
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Données mock
      _userName = 'Imane';
      _popularMonuments = _getMockMonuments();
      _recentMonuments = _getMockMonuments().take(2).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================
  // 🔹 REFRESH
  // ========================
  Future<void> refresh() async {
    await loadMockData();
  }

  List<Monument> _getMockMonuments() {
    return [
      Monument(
        id: 1,
        name: 'Hassan II Mosque',
        location: 'Casablanca',
        imageUrl: 'https://images.unsplash.com/photo-1591604466107-ec97de577aff',
        rating: 4.8,
        category: 'Religious',
      ),
      Monument(
        id: 2,
        name: 'Koutoubia Mosque',
        location: 'Marrakech',
        imageUrl: 'https://images.unsplash.com/photo-1597212618440-806262de4f6b',
        rating: 4.7,
        category: 'Religious',
      ),
      Monument(
        id: 3,
        name: 'Ait Benhaddou',
        location: 'Ouarzazate',
        imageUrl: 'https://images.unsplash.com/photo-1570829460005-c840387bb1ca',
        rating: 4.9,
        category: 'Historical',
      ),
      Monument(
        id: 4,
        name: 'Kasbah of the Udayas',
        location: 'Rabat',
        imageUrl: 'https://images.unsplash.com/photo-1568322445389-f64ac2515020',
        rating: 4.6,
        category: 'Historical',
      ),
    ];
  }
}


class Monument {
  final int id;
  final String name;
  final String location;
  final String imageUrl;
  final double rating;
  final String category;

  Monument({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.category,
  });
}