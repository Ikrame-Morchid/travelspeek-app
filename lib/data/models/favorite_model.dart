import 'package:isar/isar.dart';

part 'favorite_model.g.dart';

@collection
class Favoris {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  @Index()
  late int monumentId;

  late DateTime createdAt;

  Favoris({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.monumentId,
    required this.createdAt,
  });

  /// Constructor
  Favoris.create({
    this.id = Isar.autoIncrement,
    required this.userId,
    required this.monumentId,
  }) : createdAt = DateTime.now();

  /// 🔁 API → Local
  factory Favoris.fromJson(Map<String, dynamic> json) {
    return Favoris(
      id: json['id'] ?? Isar.autoIncrement,
      userId: json['user_id'] ?? 0,
      monumentId: json['monument_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// 🔁 Local → API
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'monument_id': monumentId,
        'created_at': createdAt.toIso8601String(),
      };
}
