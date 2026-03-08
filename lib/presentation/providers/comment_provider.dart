// lib/presentation/providers/comment_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/repositories/comment_repository.dart';

class CommentProvider with ChangeNotifier {
  final CommentRepository _repo = CommentRepository.instance;

  // State
  // ✅ Map<monumentId, List<JSON brut>> pour garder username + id API
  Map<int, List<Map<String, dynamic>>> _commentsByMonument = {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int? _currentUserId;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> getComments(int monumentId) =>
      _commentsByMonument[monumentId] ?? [];

  int getCommentsCount(int monumentId) =>
      _commentsByMonument[monumentId]?.length ?? 0;

  int? get currentUserId => _currentUserId;

  // Load
  Future<void> loadComments(int monumentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repo.getMonumentComments(monumentId);
      _commentsByMonument[monumentId] = data;
      _currentUserId = await _repo.getCurrentUserId();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh 
  Future<void> refresh(int monumentId) async {
    _commentsByMonument.remove(monumentId);
    await loadComments(monumentId);
  }

  // Add 
  Future<bool> addComment({
    required int monumentId,
    required String contenu,
    int? note,
  }) async {
    if (contenu.trim().isEmpty) {
      _errorMessage = 'Le commentaire ne peut pas être vide';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repo.addComment(
        monumentId: monumentId,
        texte: contenu.trim(),
        note: note,
      );

      if (result != null) {
        _commentsByMonument.putIfAbsent(monumentId, () => []);
        _commentsByMonument[monumentId]!.insert(0, result);
        notifyListeners();
        return true;
      }
      _errorMessage = 'Impossible d\'ajouter le commentaire';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Delete 
  // apiCommentId = comment['id'] du JSON (ID réel API, pas Isar)
  Future<bool> deleteComment({
    required int monumentId,
    required int apiCommentId,
  }) async {
    try {
      final success = await _repo.deleteComment(apiCommentId);
      if (success) {
        _commentsByMonument[monumentId]
            ?.removeWhere((c) => c['id'] == apiCommentId);
        notifyListeners();
      } else {
        _errorMessage = 'Impossible de supprimer';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Est-ce mon commentaire ?
  bool isMyComment(Map<String, dynamic> comment) =>
      comment['user_id'] == _currentUserId;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}