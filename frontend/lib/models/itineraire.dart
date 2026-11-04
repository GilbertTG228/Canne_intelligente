import 'package:latlong2/latlong.dart';

/// Résultat d'un calcul d'itinéraire piéton.
class Itineraire {
  const Itineraire({
    required this.points,
    required this.distanceM,
    required this.dureeS,
    required this.destination,
    required this.libelleDestination,
  });

  final List<LatLng> points;
  final double distanceM;
  final double dureeS;
  final LatLng destination;
  final String libelleDestination;

  Duration get duree => Duration(seconds: dureeS.round());
}
