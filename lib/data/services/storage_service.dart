import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/monument_model.dart';
import '../models/favorite_model.dart';
import '../models/comment_model.dart';
import '../models/historique_model.dart';
import '../models/translation_model.dart';
import '../models/message_model.dart';

class StorageService {
  static StorageService? _instance;
  static Isar? _isar;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    if (_isar != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        UserSchema,
        MonumentSchema,
        FavorisSchema,
        CommentaireSchema,
        HistoriqueSchema,
        TranslationSchema,
        MessageSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
  }

  Isar get db {
    if (_isar == null) {
      throw Exception('Isar not initialized. Call init() first.');
    }
    return _isar!;
  }

  // ✅ FIX : Login autre user — vider seulement les données de l'ancien userId
  // Ne prend plus userId=0 par défaut → toujours passer l'userId explicitement
  // monuments GARDÉS (cache global partagé)
  Future<void> clearUserData({int? userId}) async {
    if (userId != null && userId != 0) {
      // ✅ Effacer seulement les données de cet utilisateur
      debugPrint('🧹 clearUserData pour userId=$userId');
      await db.writeTxn(() async {
        // Favoris de cet user
        final favs = await db.favoris
            .filter()
            .userIdEqualTo(userId)
            .findAll();
        await db.favoris.deleteAll(favs.map((e) => e.id).toList());

        // Historique de cet user
        final history = await db.historiques
            .filter()
            .userIdEqualTo(userId)
            .findAll();
        await db.historiques.deleteAll(history.map((e) => e.id).toList());

        // Translations (pas de userId → vider tout)
        await db.translations.clear();

        // Commentaires (garder — données publiques)
        // Messages chatbot (pas de userId direct → vider tout)
        await db.messages.clear();

        // User local
        await db.users.filter().idEqualTo(userId).deleteFirst();
      });
    } else {
      // Fallback si userId inconnu : vider tout sauf monuments
      debugPrint('⚠️ clearUserData sans userId → fallback clear tout');
      await db.writeTxn(() async {
        await db.favoris.clear();
        await db.messages.clear();
        await db.historiques.clear();
        await db.translations.clear();
        await db.users.clear();
      });
    }
  }

  // ✅ Delete account — vider ABSOLUMENT TOUT
  Future<void> clearAll() async {
    await db.writeTxn(() async {
      await db.clear();
    });
  }

  // ========================
  // USERS
  // ========================

  Future<void> saveUser(User user) async {
    await db.writeTxn(() async {
      await db.users.put(user);
    });
  }

  Future<User?> getUser(int id) async {
    return await db.users.get(id);
  }

  Future<User?> getUserByEmail(String email) async {
    return await db.users.filter().emailEqualTo(email).findFirst();
  }

  Future<void> deleteUser(int id) async {
    await db.writeTxn(() async {
      await db.users.delete(id);
    });
  }

  // ========================
  // MONUMENTS
  // ========================

  Future<void> saveMonument(Monument monument) async {
    await db.writeTxn(() async {
      await db.monuments.put(monument);
    });
  }

  Future<void> saveMonuments(List<Monument> monuments) async {
    await db.writeTxn(() async {
      for (var monument in monuments) {
        await db.monuments.put(monument);
      }
    });
  }

  Future<Monument?> getMonument(int id) async {
    return await db.monuments.get(id);
  }

  Future<List<Monument>> getAllMonuments() async {
    return await db.monuments.where().findAll();
  }

  Future<List<Monument>> searchMonuments(String query) async {
    return await db.monuments
        .filter()
        .nomContains(query, caseSensitive: false)
        .or()
        .villeContains(query, caseSensitive: false)
        .findAll();
  }

  // ========================
  // FAVORIS
  // ========================

  Future<void> addFavorite(Favoris favorite) async {
    await db.writeTxn(() async {
      await db.favoris.put(favorite);
    });
  }

  Future<void> removeFavorite(int userId, int monumentId) async {
    await db.writeTxn(() async {
      final favorite = await db.favoris
          .filter()
          .userIdEqualTo(userId)
          .and()
          .monumentIdEqualTo(monumentId)
          .findFirst();
      if (favorite != null) {
        await db.favoris.delete(favorite.id);
      }
    });
  }

  Future<List<Favoris>> getUserFavorites(int userId) async {
    return await db.favoris.filter().userIdEqualTo(userId).findAll();
  }

  Future<bool> isFavorite(int userId, int monumentId) async {
    final favorite = await db.favoris
        .filter()
        .userIdEqualTo(userId)
        .and()
        .monumentIdEqualTo(monumentId)
        .findFirst();
    return favorite != null;
  }

  // ========================
  // COMMENTAIRES
  // ========================

  Future<void> saveComment(Commentaire comment) async {
    await db.writeTxn(() async {
      await db.commentaires.put(comment);
    });
  }

  Future<List<Commentaire>> getMonumentComments(int monumentId) async {
    return await db.commentaires
        .filter()
        .monumentIdEqualTo(monumentId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> deleteComment(int commentId) async {
    await db.writeTxn(() async {
      await db.commentaires.delete(commentId);
    });
  }

  // ========================
  // TRANSLATIONS
  // ========================

  Future<void> saveTranslation(Translation translation) async {
    await db.writeTxn(() async {
      await db.translations.put(translation);
    });
  }

  Future<List<Translation>> getAllTranslations() async {
    final items = await db.translations.where().findAll();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<Translation?> getTranslation(int id) async {
    return await db.translations.get(id);
  }

  Future<void> deleteTranslation(int id) async {
    await db.writeTxn(() async {
      await db.translations.delete(id);
    });
  }

  Future<void> clearAllTranslations() async {
    await db.writeTxn(() async {
      await db.translations.clear();
    });
  }

  // ========================
  // HISTORIQUE
  // ========================

  Future<void> saveHistoryItem(Historique item) async {
    await db.writeTxn(() async {
      await db.historiques.put(item);
    });
  }

  // ✅ Récupérer historique d'un user spécifique
  Future<List<Historique>> getHistoryByUser(int userId) async {
    final items = await db.historiques
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  // Gardé pour compatibilité — retourne TOUT (à éviter, utiliser getHistoryByUser)
  Future<List<Historique>> getAllHistory() async {
    final items = await db.historiques.where().findAll();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> deleteHistoryItem(int id) async {
    await db.writeTxn(() async {
      await db.historiques.delete(id);
    });
  }

  // ✅ Vider historique d'un user spécifique
  Future<void> clearHistoryByUser(int userId) async {
    await db.writeTxn(() async {
      final items = await db.historiques
          .filter()
          .userIdEqualTo(userId)
          .findAll();
      final ids = items.map((e) => e.id).toList();
      await db.historiques.deleteAll(ids);
      debugPrint('✅ Historique effacé pour user $userId (${ids.length} items)');
    });
  }

  // Vider tout l'historique
  Future<void> clearAllHistory() async {
    await db.writeTxn(() async {
      await db.historiques.clear();
    });
  }

  // ========================
  // MESSAGES (chatbot)
  // ========================

  Future<void> saveMessage(Message message) async {
    await db.writeTxn(() async {
      await db.messages.put(message);
    });
  }

  Future<List<Message>> getAllMessages() async {
    final items = await db.messages.where().findAll();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<List<Message>> getConversationMessages(String conversationId) async {
    final items = await db.messages
        .filter()
        .conversationIdEqualTo(conversationId)
        .findAll();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<void> deleteMessage(int id) async {
    await db.writeTxn(() async {
      await db.messages.delete(id);
    });
  }

  Future<void> clearAllMessages() async {
    await db.writeTxn(() async {
      await db.messages.clear();
    });
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}