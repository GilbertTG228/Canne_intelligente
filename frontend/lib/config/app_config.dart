import 'package:latlong2/latlong.dart';

/// Configuration centrale de l'application.
///
/// Les deux URL peuvent être remplacées à la compilation sans toucher au code :
///   flutter run --dart-define=API_URL=https://mon-serveur.tg
///   flutter build apk --dart-define=API_URL=https://mon-serveur.tg
class AppConfig {
  AppConfig._();

  /// URL de base du serveur Node.js/Express (sans « / » final).
  static const String apiBaseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://api.exemple.com');

  /// Service de routage piéton (OSRM, instance publique d'OpenStreetMap
  /// Allemagne, profil « à pied »). Usage raisonnable uniquement : pour un
  /// déploiement réel, héberger sa propre instance OSRM (même format d'URL).
  static const String routageBaseUrl = String.fromEnvironment('ROUTAGE_URL',
      defaultValue: 'https://routing.openstreetmap.de/routed-foot');

  /// Tuiles OpenStreetMap (gratuit, sans clé, usage modéré).
  static const String tuilesUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identifiant de l'application, envoyé aux serveurs de tuiles (User-Agent).
  static const String packageName = 'com.exemple.canne_proche';

  /// Centre de la carte quand aucune position n'est connue (Lomé).
  static const LatLng centreParDefaut = LatLng(6.1319, 1.2228);

  /// Délai maximal d'une requête HTTP.
  static const Duration delaiRequete = Duration(seconds: 15);

  /// Fréquence d'actualisation de la position (le serveur n'offre pas de
  /// WebSocket dans l'API décrite : on interroge régulièrement).
  static const Duration intervalleRafraichissement = Duration(seconds: 10);

  /// Les alertes sont rechargées une fois sur N rafraîchissements.
  static const int rafraichissementsParRechargementAlertes = 3;

  /// Délai d'inactivité par défaut (minutes) et choix proposés.
  static const int delaiInactiviteParDefautMin = 15;
  static const List<int> delaisInactiviteMin = [5, 10, 15, 30, 60];

  /// Si le serveur envoie déjà une notification push « canne inactive »,
  /// mettre false pour éviter le doublon avec la détection locale.
  static const bool notificationLocaleInactivite = true;

  /// Découpage de l'historique en trajets : un écart plus grand entre deux
  /// positions ouvre un nouveau trajet.
  static const Duration ecartEntreTrajets = Duration(minutes: 10);

  /// Un trajet de moins de N mètres est ignoré (bruit GPS à l'arrêt).
  static const double distanceMinimaleTrajetM = 30;
}
