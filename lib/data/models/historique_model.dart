import 'package:isar/isar.dart';

part 'historique_model.g.dart';

enum ActivityType {
  translation,
  monument,
  search,
  chatbot,
}

@collection
class Historique {
  Id id = Isar.autoIncrement;

  // ✅ userId pour filtrer par utilisateur
  @Index()
  int userId = 0;

  @Enumerated(EnumType.name)
  late ActivityType type;

  late String title;
  String? subtitle;
  String? details;
  String? imageUrl;
  
  int? resourceId;
  
  bool isFavorite = false;
  
  @Index()  
  late DateTime createdAt;

  Historique();

  factory Historique.create({
    required ActivityType type,
    required String title,
    required int userId,
    String? subtitle,
    String? details,
    String? imageUrl,
    int? resourceId,
    bool isFavorite = false,
  }) {
    return Historique()
      ..type = type
      ..userId = userId
      ..title = title
      ..subtitle = subtitle
      ..details = details
      ..imageUrl = imageUrl
      ..resourceId = resourceId
      ..isFavorite = isFavorite
      ..createdAt = DateTime.now();
  }

  String get icon {
    switch (type) {
      case ActivityType.translation:
        return '🔄';
      case ActivityType.monument:
        return '🏛️';
      case ActivityType.search:
        return '🔍';
      case ActivityType.chatbot:
        return '💬';
    }
  }

  String get dateSection {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (itemDate == today) return 'TODAY';
    else if (itemDate == yesterday) return 'YESTERDAY';
    else if (now.difference(createdAt).inDays < 7) return 'THIS WEEK';
    else if (now.difference(createdAt).inDays < 30) return 'THIS MONTH';
    else return 'OLDER';
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inSeconds < 60) return 'Just now';
    else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  Historique copyWith({
    ActivityType? type,
    int? userId,
    String? title,
    String? subtitle,
    String? details,
    String? imageUrl,
    int? resourceId,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Historique()
      ..id = id
      ..type = type ?? this.type
      ..userId = userId ?? this.userId
      ..title = title ?? this.title
      ..subtitle = subtitle ?? this.subtitle
      ..details = details ?? this.details
      ..imageUrl = imageUrl ?? this.imageUrl
      ..resourceId = resourceId ?? this.resourceId
      ..isFavorite = isFavorite ?? this.isFavorite
      ..createdAt = createdAt ?? this.createdAt;
  }

  @override
  String toString() {
    return 'Historique(id: $id, userId: $userId, type: $type, title: $title)';
  }
}