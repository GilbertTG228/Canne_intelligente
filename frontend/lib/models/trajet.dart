import 'package:latlong2/latlong.dart';

import 'position_canne.dart';

/// Un déplacement reconstitué à partir de l'historique des positions.
class Trajet {
  const Trajet({required this.positions, required this.distanceM});

  final List<PositionCanne> positions;
  final double distanceM;

  DateTime get debut => positions.first.horodatage;
  DateTime get fin => positions.last.horodatage;
  Duration get duree => fin.difference(debut);
  List<LatLng> get points => positions.map((p) => p.latLng).toList();
}
