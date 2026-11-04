import 'package:latlong2/latlong.dart';

import '../utils/json.dart';

/// Zone à éviter : un cercle (centre + rayon) autour duquel la canne alerte.
class Zone {
  const Zone({
    required this.id,
    required this.nom,
    required this.latitude,
    required this.longitude,
    required this.rayon,
    required this.actif,
  });

  final String id; // vide pour une zone pas encore créée
  final String nom;
  final double latitude;
  final double longitude;
  final double rayon; // mètres
  final bool actif;

  LatLng get centre => LatLng(latitude, longitude);

  Zone copyWith({
    String? nom,
    double? latitude,
    double? longitude,
    double? rayon,
    bool? actif,
  }) =>
      Zone(
        id: id,
        nom: nom ?? this.nom,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        rayon: rayon ?? this.rayon,
        actif: actif ?? this.actif,
      );

  static Zone? essayer(dynamic json) {
    if (json is! Map) return null;
    final lat = versDouble(json['latitude']);
    final lon = versDouble(json['longitude']);
    if (lat == null || lon == null) return null;
    return Zone(
      id: json['id'].toString(),
      nom: (json['nom'] ?? 'Zone sans nom').toString(),
      latitude: lat,
      longitude: lon,
      rayon: versDouble(json['rayon']) ?? 50,
      actif: json.containsKey('actif') ? versBool(json['actif']) : true,
    );
  }

  /// Corps envoyé à l'API pour la création et la modification.
  Map<String, dynamic> toApi() => {
        'nom': nom,
        'latitude': latitude,
        'longitude': longitude,
        'rayon': rayon.round(),
        'actif': actif,
      };

  Map<String, dynamic> toJson() => {'id': id, ...toApi()};
}
