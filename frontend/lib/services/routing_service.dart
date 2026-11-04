import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/itineraire.dart';
import 'api_client.dart';

/// Calcul d'itinéraire piéton avec OSRM (format d'API standard).
///
/// Requête : GET {routageBaseUrl}/route/v1/foot/{lon1},{lat1};{lon2},{lat2}
///           ?overview=full&geometries=geojson
/// Réponse : routes[0].geometry.coordinates = [[lon, lat], ...],
///           routes[0].distance (m), routes[0].duration (s).
class RoutingService {
  RoutingService([http.Client? client]) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Itineraire> calculer({
    required LatLng depart,
    required LatLng arrivee,
    required String libelleDestination,
  }) async {
    final url = '${AppConfig.routageBaseUrl}/route/v1/foot/'
        '${depart.longitude},${depart.latitude};${arrivee.longitude},${arrivee.latitude}'
        '?overview=full&geometries=geojson';
    try {
      final reponse = await _client.get(Uri.parse(url), headers: {
        'Accept': 'application/json',
        'User-Agent': AppConfig.packageName,
      }).timeout(AppConfig.delaiRequete);
      if (reponse.statusCode != 200) {
        throw ApiException('Calcul d\'itinéraire indisponible (code ${reponse.statusCode}).');
      }
      final json = jsonDecode(utf8.decode(reponse.bodyBytes)) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (json['code'] != 'Ok' || routes == null || routes.isEmpty) {
        throw ApiException('Aucun itinéraire à pied trouvé.');
      }
      final route = routes.first as Map<String, dynamic>;
      final coordonnees = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return Itineraire(
        points: coordonnees,
        distanceM: (route['distance'] as num).toDouble(),
        dureeS: (route['duration'] as num).toDouble(),
        destination: arrivee,
        libelleDestination: libelleDestination,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Impossible de calculer l\'itinéraire. Vérifiez votre connexion.',
          reseau: true);
    }
  }
}
