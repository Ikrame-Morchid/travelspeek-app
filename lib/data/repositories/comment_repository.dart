// lib/data/repositories/comment_repository.dart

import 'dart:convert';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../../core/constants/api_constants.dart';

class CommentRepository {
  static final CommentRepository instance = CommentRepository._();
  CommentRepository._();

  final ApiService _apiService = ApiService.instance;
  final TokenService _tokenService = TokenService.instance;

  //GET comments 
  // Retourne JSON brut pour garder username, id API réel, etc.
  Future<List<Map<String, dynamic>>> getMonumentComments(int monumentId) async {
    try {
      final response = await _apiService.get(
        ApiConstants.monumentComments(monumentId),
        requiresAuth: false,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ADD comment 
  Future<Map<String, dynamic>?> addComment({
    required int monumentId,
    required String texte,
    int? note,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.addComment,
        {
          'monument_id': monumentId,
          'texte': texte,                    // ✅ backend attend 'texte'
          if (note != null) 'note': note,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ Utilise l'ID API (du JSON), pas l'ID Isar local
  Future<bool> deleteComment(int apiCommentId) async {
    try {
      final response = await _apiService.delete(
        ApiConstants.deleteComment(apiCommentId),
      );
      return response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // GET current userId
  Future<int?> getCurrentUserId() async {
    return await _tokenService.getUserId();
  }
}