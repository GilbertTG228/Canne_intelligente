import 'package:latlong2/latlong.dart';

import '../utils/json.dart';

/// Une position GPS transmise par la canne.
class PositionCanne {
  const PositionCanne({
    required this.latitude,
    required this.longitude,
    required this.horodatage,
    this.precision,
    this.batterie,
  });

  final double latitude;
  final double longitude;
  final double? precision; // mètres
  final int? batterie; // pourcentage
  final DateTime horodatage;

  LatLng get latLng => LatLng(latitude, longitude);

  /// Retourne null si la latitude ou la longitude est absente/invalide.
  static PositionCanne? essayer(dynamic json) {
    if (json is! Map) return null;
    final lat = versDouble(json['latitude']);
    final lon = versDouble(json['longitude']);
    if (lat == null || lon == null) return null;
    return PositionCanne(
      latitude: lat,
      longitude: lon,
      precision: versDouble(json['precision']),
      batterie: versInt(json['batterie']),
      horodatage: versDate(json['horodatage']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'precision': precision,
        'batterie': batterie,
        'horodatage': horodatage.toUtc().toIso8601String(),
      };
}
