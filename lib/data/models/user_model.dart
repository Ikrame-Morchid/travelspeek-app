import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  late Id id;

  /// Email unique de l'utilisateur
  @Index(unique: true)
  late String email;

  /// Nom d'utilisateur affiché
  late String username;

  /// Photo de profil (URL ou chemin local)
  String? profilePicture;

  /// Date de création du compte
  late DateTime createdAt;

  /// Dernière mise à jour du profil
  DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
    required this.createdAt,
    this.updatedAt,
  });

  /// Création locale (inscription)
  User.create({
    required this.id,
    required this.email,
    required this.username,
    this.profilePicture,
  }) : createdAt = DateTime.now();

  /// API → Local
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profilePicture: json['profile_picture'],
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
        'email': email,
        'username': username,
        'profile_picture': profilePicture,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null)
          'updated_at': updatedAt!.toIso8601String(),
      };

  /// Nom affiché dans l'UI
  String get displayName =>
      username.isNotEmpty ? username : email.split('@').first;
}