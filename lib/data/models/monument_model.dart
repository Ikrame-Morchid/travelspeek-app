import 'package:isar/isar.dart';

part 'monument_model.g.dart';

@collection
class Monument {
  // ========================
  // 🔹 Primary Key
  // ========================
  late Id id;

  // ========================
  // 🔹 Champs métier
  // ========================
  @Index()
  late String nom;

  late String description;

  @Index()
  late String ville;

  // ✅ MODIFIÉ: Support pour plusieurs images
  String? image;  // Garde pour compatibilité locale
  List<String>? images;  // ✅ NOUVEAU: Liste d'images de l'API
  String? imageUrl;  // ✅ NOUVEAU: URL principale de l'image
  
  String? localisation;  // ✅ NOUVEAU: Lien Google Maps
  
  double? latitude;
  double? longitude;

  String? pays;
  String? categorie;

  double? noteGlobale;
  int nombreVisites;
  bool isFavorite;

  // ========================
  // 🔹 Dates
  // ========================
  late DateTime createdAt;
  DateTime? updatedAt;

  // ========================
  // 🔹 Constructor principal
  // ========================
  Monument({
    required this.id,
    required this.nom,
    required this.description,
    required this.ville,
    this.image,
    this.images,
    this.imageUrl,
    this.localisation,
    this.latitude,
    this.longitude,
    this.pays,
    this.categorie,
    this.noteGlobale,
    this.nombreVisites = 0,
    this.isFavorite = false,
    required this.createdAt,
    this.updatedAt,
  });

  // ========================
  // 🔹 Création locale
  // ========================
  Monument.create({
    required this.id,
    required this.nom,
    required this.description,
    required this.ville,
    this.image,
    this.images,
    this.imageUrl,
    this.localisation,
    this.latitude,
    this.longitude,
    this.pays,
    this.categorie,
  })  : createdAt = DateTime.now(),
        nombreVisites = 0,
        isFavorite = false;

  // ========================
  // 🔹 From API - ✅ CORRIGÉ
  // ========================
  factory Monument.fromJson(Map<String, dynamic> json) {
    // Extraire les images
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }
    
    // Prendre la première image comme image principale
    String? mainImage = json['image_url'] ?? 
                       (imagesList != null && imagesList.isNotEmpty 
                           ? imagesList[0] 
                           : null);
    
    return Monument(
      id: json['id'] as int,
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      ville: json['ville'] ?? '',
      
      // ✅ NOUVEAU: Support des images multiples
      image: mainImage,  // Garde l'ancienne propriété pour compatibilité
      images: imagesList,
      imageUrl: mainImage,
      localisation: json['localisation'],
      
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      pays: json['pays'],
      categorie: json['categorie'],
      noteGlobale: json['note_globale']?.toDouble(),
      nombreVisites: json['nombre_visites'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // ========================
  // 🔹 To API
  // ========================
  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'description': description,
        'ville': ville,
        'image': image,
        'images': images,
        'image_url': imageUrl,
        'localisation': localisation,
        'latitude': latitude,
        'longitude': longitude,
        'pays': pays,
        'categorie': categorie,
        'note_globale': noteGlobale,
        'nombre_visites': nombreVisites,
        'is_favorite': isFavorite,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null)
          'updated_at': updatedAt!.toIso8601String(),
      };

  // ========================
  // 🔹 Helpers UI
  // ========================
  String get location => pays != null ? '$ville, $pays' : ville;
  bool get hasCoordinates => latitude != null && longitude != null;
  
  // ✅ NOUVEAU: Helper pour obtenir l'image principale
  String? get mainImage => imageUrl ?? image ?? (images?.isNotEmpty == true ? images![0] : null);
  
  // ✅ NOUVEAU: Helper pour savoir si on a des images
  bool get hasImage => mainImage != null;
  
  // ✅ NOUVEAU: Helper pour le nombre d'images
  int get imageCount => images?.length ?? (image != null ? 1 : 0);
}