
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  // JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List)
          .map((m) => ConversationMessage.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  //  Copie avec modifications 
  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ConversationMessage>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  //Preview (premier message user)
  String get preview {
    final userMsg = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ConversationMessage(
        text: 'Nouvelle conversation',
        isUser: true,
        timestamp: createdAt,
      ),
    );
    return userMsg.text.length > 60
        ? '${userMsg.text.substring(0, 60)}...'
        : userMsg.text;
  }
}

class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, dynamic>? weather;
  final Map<String, dynamic>? monument;
  final Map<String, dynamic>? location;
  final String? source;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.weather,
    this.monument,
    this.location,
    this.source,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrl: json['imageUrl'] as String?,
      weather: json['weather'] as Map<String, dynamic>?,
      monument: json['monument'] as Map<String, dynamic>?,
      location: json['location'] as Map<String, dynamic>?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'weather': weather,
      'monument': monument,
      'location': location,
      'source': source,
    };
  }
}