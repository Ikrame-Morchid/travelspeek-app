import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';

class ConversationDatabase {
  static final ConversationDatabase instance = ConversationDatabase._init();
  static Database? _database;

  ConversationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('conversations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // ✅ version 2 pour migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL DEFAULT 0,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        messages TEXT NOT NULL
      )
    ''');

    // ✅ Index pour filtrer par user_id rapidement
    await db.execute('''
      CREATE INDEX idx_user_id ON conversations(user_id)
    ''');
  }

  // ✅ Migration v1 → v2 : ajouter colonne user_id
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE conversations ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0'
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_id ON conversations(user_id)'
      );
    }
  }

  // ✅ Récupérer userId courant depuis SharedPreferences
  Future<int> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  /// Créer une nouvelle conversation
  Future<Conversation> create(Conversation conversation) async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    await db.insert(
      'conversations',
      {
        'id': conversation.id,
        'user_id': userId, // ✅
        'title': conversation.title,
        'createdAt': conversation.createdAt.toIso8601String(),
        'updatedAt': conversation.updatedAt.toIso8601String(),
        'messages': jsonEncode(
          conversation.messages.map((m) => m.toJson()).toList(),
        ),
      },
    );

    return conversation;
  }

  /// Lire toutes les conversations de l'utilisateur courant
  Future<List<Conversation>> readAll() async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    final result = await db.query(
      'conversations',
      where: 'user_id = ?', // ✅ filtrer par userId
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );

    return result.map((json) => _conversationFromMap(json)).toList();
  }

  /// Lire une conversation par ID
  Future<Conversation?> read(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    final maps = await db.query(
      'conversations',
      where: 'id = ? AND user_id = ?', // ✅ sécurité
      whereArgs: [id, userId],
    );

    if (maps.isNotEmpty) {
      return _conversationFromMap(maps.first);
    }
    return null;
  }

  /// Mettre à jour une conversation
  Future<int> update(Conversation conversation) async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    return db.update(
      'conversations',
      {
        'title': conversation.title,
        'updatedAt': DateTime.now().toIso8601String(),
        'messages': jsonEncode(
          conversation.messages.map((m) => m.toJson()).toList(),
        ),
      },
      where: 'id = ? AND user_id = ?', // ✅ sécurité
      whereArgs: [conversation.id, userId],
    );
  }

  /// Supprimer une conversation
  Future<int> delete(String id) async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    return await db.delete(
      'conversations',
      where: 'id = ? AND user_id = ?', // ✅ sécurité
      whereArgs: [id, userId],
    );
  }

  /// Rechercher dans les conversations de l'utilisateur courant
  Future<List<Conversation>> search(String query) async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    final result = await db.query(
      'conversations',
      where: 'user_id = ? AND (title LIKE ? OR messages LIKE ?)', // ✅
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
    );

    return result.map((json) => _conversationFromMap(json)).toList();
  }

  /// Supprimer toutes les conversations de l'utilisateur courant
  Future<int> deleteAll() async {
    final db = await database;
    final userId = await _getCurrentUserId(); // ✅

    return await db.delete(
      'conversations',
      where: 'user_id = ?', // ✅ seulement cet utilisateur
      whereArgs: [userId],
    );
  }

  /// ✅ Supprimer toutes les conversations d'un userId spécifique
  /// Appelé au delete account
  Future<int> deleteAllForUser(int userId) async {
    final db = await database;
    return await db.delete(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Conversation _conversationFromMap(Map<String, dynamic> map) {
    final messagesJson = jsonDecode(map['messages'] as String) as List;
    final messages = messagesJson
        .map((m) => ConversationMessage.fromJson(m))
        .toList();

    return Conversation(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      messages: messages,
    );
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}