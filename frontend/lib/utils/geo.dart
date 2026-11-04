import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/position_canne.dart';
import '../models/trajet.dart';

const _calcul = Distance();

/// Distance en mètres entre deux points (formule de Vincenty de latlong2).
double distanceEntre(LatLng a, LatLng b) => _calcul.distance(a, b);

double longueurChemin(List<LatLng> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += distanceEntre(points[i - 1], points[i]);
  }
  return total;
}

/// Découpe une liste de positions (triée ou non) en trajets : un écart
/// supérieur à [ecart] entre deux positions consécutives ouvre un nouveau
/// trajet. Les trajets trop courts (bruit GPS à l'arrêt) sont ignorés.
List<Trajet> decouperEnTrajets(
  List<PositionCanne> positions, {
  Duration ecart = AppConfig.ecartEntreTrajets,
  double distanceMin = AppConfig.distanceMinimaleTrajetM,
}) {
  if (positions.length < 2) return const [];
  final triees = [...positions]..sort((a, b) => a.horodatage.compareTo(b.horodatage));

  final groupes = <List<PositionCanne>>[];
  var courant = <PositionCanne>[triees.first];
  for (var i = 1; i < triees.length; i++) {
    final ecartReel = triees[i].horodatage.difference(triees[i - 1].horodatage);
    if (ecartReel > ecart) {
      groupes.add(courant);
      courant = <PositionCanne>[];
    }
    courant.add(triees[i]);
  }
  groupes.add(courant);

  final trajets = <Trajet>[];
  for (final g in groupes) {
    if (g.length < 2) continue;
    final d = longueurChemin(g.map((p) => p.latLng).toList());
    if (d < distanceMin) continue;
    trajets.add(Trajet(positions: g, distanceM: d));
  }
  return trajets;
}
