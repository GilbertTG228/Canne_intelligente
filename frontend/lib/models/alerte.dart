import 'package:latlong2/latlong.dart';

import '../utils/json.dart';

enum TypeAlerte { entreeZone, sos, chute, batterieFaible, canneInactive, inconnu }

TypeAlerte typeAlerteDepuis(String? code) {
  switch (code?.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')) {
    case 'sos':
      return TypeAlerte.sos;
    case 'entree_zone':
    case 'entree_en_zone':
    case 'zone':
      return TypeAlerte.entreeZone;
    case 'chute':
      return TypeAlerte.chute;
    case 'batterie_faible':
    case 'batterie':
      return TypeAlerte.batterieFaible;
    case 'canne_inactive':
    case 'inactive':
    case 'inactivite':
      return TypeAlerte.canneInactive;
    default:
      return TypeAlerte.inconnu;
  }
}

String codeAlerte(TypeAlerte t) {
  switch (t) {
    case TypeAlerte.sos:
      return 'sos';
    case TypeAlerte.entreeZone:
      return 'entree_zone';
    case TypeAlerte.chute:
      return 'chute';
    case TypeAlerte.batterieFaible:
      return 'batterie_faible';
    case TypeAlerte.canneInactive:
      return 'canne_inactive';
    case TypeAlerte.inconnu:
      return 'inconnu';
  }
}

/// Une entrée du journal d'alertes.
class Alerte {
  const Alerte({
    required this.id,
    required this.type,
    required this.horodatage,
    required this.traitee,
    this.canneId,
    this.zoneNom,
    this.latitude,
    this.longitude,
    this.message,
  });

  final String id;
  final String? canneId;
  final TypeAlerte type;
  final DateTime horodatage;
  final bool traitee;
  final String? zoneNom;
  final double? latitude;
  final double? longitude;
  final String? message;

  LatLng? get position =>
      (latitude != null && longitude != null) ? LatLng(latitude!, longitude!) : null;

  /// SOS et chute : rouge. Le reste : orange.
  bool get critique => type == TypeAlerte.sos || type == TypeAlerte.chute;

  /// SOS et entrée en zone déclenchent l'écran « alerte en cours ».
  bool get urgente => type == TypeAlerte.sos || type == TypeAlerte.entreeZone;

  Alerte copyWith({bool? traitee}) => Alerte(
        id: id,
        canneId: canneId,
        type: type,
        horodatage: horodatage,
        traitee: traitee ?? this.traitee,
        zoneNom: zoneNom,
        latitude: latitude,
        longitude: longitude,
        message: message,
      );

  /// Sert aussi à lire la charge utile (data) d'une notification push,
  /// dont toutes les valeurs sont des chaînes.
  factory Alerte.fromJson(Map<String, dynamic> json) {
    final zone = json['zone'];
    String? zoneNom = json['zoneNom']?.toString();
    if (zoneNom == null && zone is Map) zoneNom = zone['nom']?.toString();
    if (zoneNom == null && zone is String) zoneNom = zone;
    final pos = json['position'];
    return Alerte(
      id: (json['id'] ?? json['alerteId'] ?? '').toString(),
      canneId: (json['cannesId'] ?? json['canneId'] ?? json['cannes_id'])?.toString(),
      type: typeAlerteDepuis(json['type']?.toString()),
      horodatage: versDate(json['horodatage'] ?? json['date']) ?? DateTime.now(),
      traitee: versBool(json['traitee']),
      zoneNom: zoneNom,
      latitude: versDouble(json['latitude'] ?? (pos is Map ? pos['latitude'] : null)),
      longitude: versDouble(json['longitude'] ?? (pos is Map ? pos['longitude'] : null)),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cannesId': canneId,
        'type': codeAlerte(type),
        'horodatage': horodatage.toUtc().toIso8601String(),
        'traitee': traitee,
        'zoneNom': zoneNom,
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
      };
}
