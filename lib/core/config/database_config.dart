import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/user_model.dart';
import '../../data/models/monument_model.dart';
import '../../data/models/favorite_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/historique_model.dart';

class DatabaseConfig {
  static Isar? _isar;

  static Future<Isar> get db async {
    if (_isar != null) return _isar!;
    _isar = await init();
    return _isar!;
  }

  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [
        UserSchema,
        MonumentSchema,
        FavorisSchema,
        CommentaireSchema,
        HistoriqueSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
  }

  static Future<void> clearAll() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}