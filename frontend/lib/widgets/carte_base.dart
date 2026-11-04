import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Carte OpenStreetMap (flutter_map) avec l'attribution obligatoire.
/// Les couches (cercles, tracés, marqueurs) sont passées par l'écran.
class CarteBase extends StatelessWidget {
  const CarteBase({
    super.key,
    required this.controleur,
    required this.centre,
    required this.libelle,
    this.zoom = 16,
    this.couches = const [],
    this.surTouche,
    this.surDeplacement,
    this.interactive = true,
  });

  final MapController controleur;
  final LatLng centre;
  final double zoom;
  final List<Widget> couches;
  final void Function(LatLng point)? surTouche;

  /// (a bougé à la main ?) — permet d'arrêter le suivi automatique.
  final void Function(bool geste)? surDeplacement;
  final bool interactive;

  /// Description lue par les lecteurs d'écran.
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: libelle,
      container: true,
      child: FlutterMap(
        mapController: controleur,
        options: MapOptions(
          initialCenter: centre,
          initialZoom: zoom,
          minZoom: 3,
          maxZoom: 19,
          onTap: surTouche == null ? null : (_, point) => surTouche!(point),
          onPositionChanged: surDeplacement == null
              ? null
              : (camera, geste) => surDeplacement!(geste),
          interactionOptions: InteractionOptions(
            flags: interactive
                ? InteractiveFlag.all & ~InteractiveFlag.rotate
                : InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: AppConfig.tuilesUrl,
            userAgentPackageName: AppConfig.packageName,
          ),
          ...couches,
          RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            showFlutterMapAttribution: false,
            attributions: [
              TextSourceAttribution(
                '© contributeurs OpenStreetMap',
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Déplacement sans erreur si la carte n'est pas encore affichée.
extension MapControllerSur on MapController {
  void deplacerSur(LatLng point, {double? zoom}) {
    try {
      move(point, zoom ?? camera.zoom);
    } catch (_) {}
  }

  void ajusterSur(List<LatLng> points, {double zoomMax = 17}) {
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        move(points.first, zoomMax);
        return;
      }
      fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
        maxZoom: zoomMax,
      ));
    } catch (_) {}
  }
}

/// Marqueur rond avec icône (canne, domicile, arrivée…).
class MarqueurRond extends StatelessWidget {
  const MarqueurRond({
    super.key,
    required this.icone,
    required this.couleur,
    this.taille = 44,
    this.libelle,
  });

  final IconData icone;
  final Color couleur;
  final double taille;
  final String? libelle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: libelle,
      child: Container(
        decoration: BoxDecoration(
          color: couleur,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icone, color: Colors.white, size: taille * 0.55),
      ),
    );
  }
}
