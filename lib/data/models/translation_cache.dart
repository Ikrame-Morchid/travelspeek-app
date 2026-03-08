import 'package:isar/isar.dart';

part 'translation_cache.g.dart';

@collection
class TranslationCache {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String key;
  
  late String translatedText;
  
  late DateTime lastUpdated;
}