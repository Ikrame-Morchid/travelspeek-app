import 'package:isar/isar.dart';

part 'translation_model.g.dart';

/// Type de traduction
enum TranslationType {
  voice,    // Traduction vocale
  image,    // Traduction d'image (texte dans image)
  text,     // Traduction de texte simple
}

@collection
class Translation {
  // ========================
  // 🔹 Primary Key
  // ========================
  Id id = Isar.autoIncrement;

  // ========================
  // 🔹 Champs métier
  // ========================
  
  /// Type de traduction (voice, image, text)
  @Enumerated(EnumType.name)
  late TranslationType type;
  
  /// Texte original (source)
  late String sourceText;
  
  /// Langue source (ex: "en", "fr", "ar")
  late String sourceLanguage;
  
  /// Texte traduit
  late String translatedText;
  
  /// Langue cible (ex: "fr", "en", "ar")
  late String targetLanguage;
  
  /// URL de l'image (si type = image)
  String? imageUrl;
  
  /// Path local de l'image (si type = image)
  String? imageLocalPath;
  
  /// URL audio (si type = voice)
  String? audioUrl;
  
  /// Durée audio en secondes (si type = voice)
  double? audioDuration;
  
  /// Est-ce un favori ?
  bool isFavorite;
  
  /// Détection de contenu offensant ?
  bool hasOffensiveContent;
  
  // ========================
  // 🔹 Dates
  // ========================
  late DateTime createdAt;
  
  // ========================
  // 🔹 Constructors
  // ========================
  Translation({
    this.id = Isar.autoIncrement,
    required this.type,
    required this.sourceText,
    required this.sourceLanguage,
    required this.translatedText,
    required this.targetLanguage,
    this.imageUrl,
    this.imageLocalPath,
    this.audioUrl,
    this.audioDuration,
    this.isFavorite = false,
    this.hasOffensiveContent = false,
    required this.createdAt,
  });
  
  Translation.create({
    required this.type,
    required this.sourceText,
    required this.sourceLanguage,
    required this.translatedText,
    required this.targetLanguage,
    this.imageUrl,
    this.imageLocalPath,
    this.audioUrl,
    this.audioDuration,
  })  : createdAt = DateTime.now(),
        isFavorite = false,
        hasOffensiveContent = false;
  
  // ========================
  // 🔹 From/To JSON
  // ========================
  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      type: TranslationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TranslationType.text,
      ),
      sourceText: json['source_text'] ?? '',
      sourceLanguage: json['source_language'] ?? 'en',
      translatedText: json['translated_text'] ?? '',
      targetLanguage: json['target_language'] ?? 'fr',
      imageUrl: json['image_url'],
      imageLocalPath: json['image_local_path'],
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration']?.toDouble(),
      isFavorite: json['is_favorite'] ?? false,
      hasOffensiveContent: json['has_offensive_content'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'source_text': sourceText,
        'source_language': sourceLanguage,
        'translated_text': translatedText,
        'target_language': targetLanguage,
        if (imageUrl != null) 'image_url': imageUrl,
        if (imageLocalPath != null) 'image_local_path': imageLocalPath,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (audioDuration != null) 'audio_duration': audioDuration,
        'is_favorite': isFavorite,
        'has_offensive_content': hasOffensiveContent,
        'created_at': createdAt.toIso8601String(),
      };
  
  // ========================
  // 🔹 Helpers UI
  // ========================
  String get typeIcon {
    switch (type) {
      case TranslationType.voice:
        return '🎤';
      case TranslationType.image:
        return '📷';
      case TranslationType.text:
        return '📝';
    }
  }
  
  String get typeLabel {
    switch (type) {
      case TranslationType.voice:
        return 'Voice';
      case TranslationType.image:
        return 'Image';
      case TranslationType.text:
        return 'Text';
    }
  }
  
  String get languagePair => '$sourceLanguage → $targetLanguage';
  
  String get shortText {
    if (sourceText.length <= 50) return sourceText;
    return '${sourceText.substring(0, 50)}...';
  }
}