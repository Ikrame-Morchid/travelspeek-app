import 'package:isar/isar.dart';

part 'message_model.g.dart';

/// Type de message
enum MessageType {
  text,      // Message texte simple
  image,     // Message avec image
  suggestion, // Suggestion du bot
  location,  // Localisation
}

/// Rôle du message
enum MessageRole {
  user,      // Message de l'utilisateur
  assistant, // Message du bot
  system,    // Message système
}

@collection
class Message {
  // ========================
  // 🔹 Primary Key
  // ========================
  Id id = Isar.autoIncrement;

  // ========================
  // 🔹 Champs métier
  // ========================
  
  /// Rôle (user, assistant, system)
  @Enumerated(EnumType.name)
  late MessageRole role;
  
  /// Type de message (text, image, suggestion, etc.)
  @Enumerated(EnumType.name)
  late MessageType type;
  
  /// Contenu du message
  late String content;
  
  /// URL d'image (si type = image)
  String? imageUrl;
  
  /// ID du monument lié (si le bot suggère un monument)
  int? monumentId;
  
  /// Latitude (si type = location)
  double? latitude;
  
  /// Longitude (si type = location)
  double? longitude;
  
  /// Métadonnées supplémentaires en JSON string
  String? metadata;
  
  /// Est-ce un message favori/épinglé ?
  bool isPinned;
  
  /// Conversation ID (pour grouper les messages)
  String? conversationId;
  
  // ========================
  // 🔹 Dates
  // ========================
  late DateTime createdAt;
  
  // ========================
  // 🔹 Constructors
  // ========================
  Message({
    this.id = Isar.autoIncrement,
    required this.role,
    required this.type,
    required this.content,
    this.imageUrl,
    this.monumentId,
    this.latitude,
    this.longitude,
    this.metadata,
    this.isPinned = false,
    this.conversationId,
    required this.createdAt,
  });
  
  Message.user({
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    this.conversationId,
  })  : role = MessageRole.user,
        isPinned = false,
        createdAt = DateTime.now();
  
  Message.assistant({
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    this.monumentId,
    this.conversationId,
  })  : role = MessageRole.assistant,
        isPinned = false,
        createdAt = DateTime.now();
  
  // ========================
  // 🔹 From/To JSON
  // ========================
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      monumentId: json['monument_id'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      metadata: json['metadata'],
      isPinned: json['is_pinned'] ?? false,
      conversationId: json['conversation_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
        'role': role.name,
        'type': type.name,
        'content': content,
        if (imageUrl != null) 'image_url': imageUrl,
        if (monumentId != null) 'monument_id': monumentId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (metadata != null) 'metadata': metadata,
        'is_pinned': isPinned,
        if (conversationId != null) 'conversation_id': conversationId,
        'created_at': createdAt.toIso8601String(),
      };
  
  // ========================
  // 🔹 Helpers UI
  // ========================
  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasMonument => monumentId != null;
  
  String get timeLabel {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Copier avec modifications
  Message copyWith({
    MessageRole? role,
    MessageType? type,
    String? content,
    String? imageUrl,
    int? monumentId,
    double? latitude,
    double? longitude,
    String? metadata,
    bool? isPinned,
    String? conversationId,
  }) {
    return Message(
      id: id,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      monumentId: monumentId ?? this.monumentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      metadata: metadata ?? this.metadata,
      isPinned: isPinned ?? this.isPinned,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt,
    );
  }
}