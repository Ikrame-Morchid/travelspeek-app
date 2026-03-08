import 'package:isar/isar.dart';

part 'comment_model.g.dart';

@collection
class Commentaire {
  Id id = Isar.autoIncrement;

  /// ID de l'utilisateur
  @Index()
  late int userId;

  /// ✅ AJOUTÉ: Nom d'utilisateur
  late String username;

  /// ✅ AJOUTÉ: Email utilisateur (optionnel)
  String? userEmail;

  /// ✅ AJOUTÉ: Avatar utilisateur (optionnel)
  String? userAvatar;

  /// ID du monument
  @Index()
  late int monumentId;

  /// Contenu du commentaire
  late String contenu;

  /// Note de 1 à 5
  int? note;

  /// Dates
  late DateTime createdAt;
  DateTime? updatedAt;

  Commentaire({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.username,
    this.userEmail,
    this.userAvatar,
    required this.monumentId,
    required this.contenu,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  /// Créer un commentaire local
  Commentaire.create({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.username,
    this.userEmail,
    this.userAvatar,
    required this.monumentId,
    required this.contenu,
    this.note,
  })  : createdAt = DateTime.now(),
        updatedAt = null;

  /// ✅ API → Local (fromJson corrigé)
  factory Commentaire.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où l'utilisateur est dans un objet séparé
    String username = 'Utilisateur';
    String? email;
    String? avatar;

    if (json.containsKey('user') && json['user'] != null) {
      // Cas 1: Backend retourne { user: { id, username, email } }
      final user = json['user'] as Map<String, dynamic>;
      username = user['username'] ?? user['email']?.split('@')[0] ?? 'Utilisateur';
      email = user['email'];
      avatar = user['profile_picture'] ?? user['avatar'];
    } else if (json.containsKey('username')) {
      // Cas 2: Backend retourne { username, email, ... } directement
      username = json['username'] ?? 'Utilisateur';
      email = json['email'] ?? json['user_email'];
      avatar = json['avatar'] ?? json['user_avatar'] ?? json['profile_picture'];
    }

    return Commentaire(
      id: json['id'] ?? Isar.autoIncrement,
      userId: json['user_id'] ?? 0,
      username: username,
      userEmail: email,
      userAvatar: avatar,
      monumentId: json['monument_id'] ?? 0,
      contenu: json['contenu'] ?? json['texte'] ?? '',
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Local → API
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'username': username,
        'user_email': userEmail,
        'user_avatar': userAvatar,
        'monument_id': monumentId,
        'contenu': contenu,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  // ══════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════

  bool get hasRating => note != null;

  /// Nom à afficher dans l'UI
  String get displayName {
    if (username.isNotEmpty && username != 'Utilisateur') {
      return username;
    }
    if (userEmail != null && userEmail!.isNotEmpty) {
      return userEmail!.split('@')[0];
    }
    return 'Utilisateur #$userId';
  }

  /// Avatar à afficher (URL ou initiales)
  String get avatarUrl => userAvatar ?? 'https://i.pravatar.cc/150?u=$userId';

  /// Temps écoulé depuis la création
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return 'Il y a ${(diff.inDays / 365).floor()} an(s)';
    if (diff.inDays > 30) return 'Il y a ${(diff.inDays / 30).floor()} mois';
    if (diff.inDays > 0) return 'Il y a ${diff.inDays} jour(s)';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours} heure(s)';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes} minute(s)';
    return 'À l\'instant';
  }

  /// Formatage de la date
  String get formattedDate {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }
}