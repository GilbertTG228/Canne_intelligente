import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocalisationException implements Exception {
  LocalisationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Position du téléphone du proche (pour l'itinéraire de retour).
class LocationService {
  Future<LatLng> positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocalisationException('Activez la localisation de votre téléphone.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocalisationException('Autorisez l\'accès à votre position pour continuer.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocalisationException(
          'L\'accès à la position est bloqué. Autorisez-le dans les réglages du téléphone.');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      throw LocalisationException('Votre position n\'a pas pu être déterminée.');
    }
  }
}
