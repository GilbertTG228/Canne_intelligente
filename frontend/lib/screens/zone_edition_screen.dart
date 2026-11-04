import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/suivi_controller.dart';
import '../controllers/zones_controller.dart';
import '../models/zone.dart';
import '../services/api_client.dart';
import '../widgets/carte_base.dart';

/// Création ou modification d'une zone : on touche la carte pour placer le
/// centre, un curseur règle le rayon, un champ donne le nom.
class ZoneEditionScreen extends StatefulWidget {
  const ZoneEditionScreen({super.key, this.zone});

  /// null = création.
  final Zone? zone;

  @override
  State<ZoneEditionScreen> createState() => _ZoneEditionScreenState();
}

class _ZoneEditionScreenState extends State<ZoneEditionScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _carte = MapController();
  LatLng? _centre;
  double _rayon = 75;
  bool _actif = true;
  bool _envoi = false;

  bool get _modification => widget.zone != null;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    if (z != null) {
      _nom.text = z.nom;
      _centre = z.centre;
      _rayon = z.rayon.clamp(25, 500).toDouble();
      _actif = z.actif;
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _carte.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final messager = ScaffoldMessenger.of(context);
    if (!_formulaire.currentState!.validate()) return;
    if (_centre == null) {
      messager.showSnackBar(
          const SnackBar(content: Text('Touchez la carte pour placer le centre de la zone.')));
      return;
    }
    final zones = context.read<ZonesController>();
    final navigateur = Navigator.of(context);
    setState(() => _envoi = true);
    try {
      final zone = Zone(
        id: widget.zone?.id ?? '',
        nom: _nom.text.trim(),
        latitude: _centre!.latitude,
        longitude: _centre!.longitude,
        rayon: _rayon,
        actif: _actif,
      );
      if (_modification) {
        await zones.modifier(zone);
      } else {
        await zones.creer(zone);
      }
      navigateur.pop();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final c = context.couleurs;
    final s = context.statut;
    final positionCanne = suivi.position?.latLng;
    final centreCarte = _centre ?? positionCanne ?? AppConfig.centreParDefaut;

    return Scaffold(
      appBar: AppBar(title: Text(_modification ? 'Modifier la zone' : 'Nouvelle zone')),
      body: SafeArea(
        child: Form(
          key: _formulaire,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _centre == null
                    ? 'Touchez la carte pour placer le centre de la zone.'
                    : 'Touchez la carte pour déplacer le centre.',
                style: context.textes.bodyLarge,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 300,
                  child: CarteBase(
                    controleur: _carte,
                    centre: centreCarte,
                    zoom: 16,
                    libelle: _centre == null
                        ? 'Carte. Touchez pour placer le centre de la zone.'
                        : 'Carte. Centre de la zone placé. Rayon ${_rayon.round()} mètres.',
                    surTouche: (p) => setState(() => _centre = p),
                    couches: [
                      if (_centre != null)
                        CircleLayer(circles: [
                          CircleMarker(
                            point: _centre!,
                            radius: _rayon,
                            useRadiusInMeter: true,
                            color: s.critique.withValues(alpha: 0.22),
                            borderColor: s.critique,
                            borderStrokeWidth: 2,
                          ),
                        ]),
                      MarkerLayer(markers: [
                        if (positionCanne != null)
                          Marker(
                            point: positionCanne,
                            width: 36,
                            height: 36,
                            child: MarqueurRond(
                                icone: Icons.directions_walk_rounded,
                                couleur: c.primary,
                                taille: 36,
                                libelle: 'Position de la canne'),
                          ),
                        if (_centre != null)
                          Marker(
                            point: _centre!,
                            width: 40,
                            height: 40,
                            child: MarqueurRond(
                                icone: Icons.block_rounded,
                                couleur: s.critique,
                                taille: 40,
                                libelle: 'Centre de la zone'),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              if (positionCanne != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _centre = positionCanne);
                      _carte.deplacerSur(positionCanne, zoom: 17);
                    },
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Utiliser la position de la canne'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.sentences,
                style: context.textes.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Nom de la zone',
                  hintText: 'Ex. Carrefour du marché',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Donnez un nom à la zone.' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Rayon de la zone', style: context.textes.titleSmall)),
                  Text('${_rayon.round()} mètres',
                      style: context.textes.titleMedium?.copyWith(color: c.primary)),
                ],
              ),
              Semantics(
                label: 'Rayon de la zone',
                value: '${_rayon.round()} mètres',
                child: Slider(
                  value: _rayon,
                  min: 25,
                  max: 500,
                  divisions: 95,
                  label: '${_rayon.round()} m',
                  onChanged: (v) => setState(() => _rayon = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('25 m', style: context.textes.labelMedium),
                  Text('500 m', style: context.textes.labelMedium),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Zone active', style: context.textes.titleSmall),
                subtitle: const Text('La canne alerte à l\'entrée de cette zone'),
                value: _actif,
                onChanged: (v) => setState(() => _actif = v),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
                onPressed: _envoi ? null : _enregistrer,
                icon: _envoi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_modification ? 'Enregistrer les modifications' : 'Enregistrer la zone'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
