import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../services/location_service.dart';
import '../widgets/carte_base.dart';

/// Sélection d'un point sur la carte (ex. domicile). Retourne un [LatLng].
class SelectionPointScreen extends StatefulWidget {
  const SelectionPointScreen({super.key, required this.titre, this.initial});

  final String titre;
  final LatLng? initial;

  @override
  State<SelectionPointScreen> createState() => _SelectionPointScreenState();
}

class _SelectionPointScreenState extends State<SelectionPointScreen> {
  final _carte = MapController();
  LatLng? _point;
  bool _localisation = false;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  Future<void> _utiliserMaPosition() async {
    final service = context.read<LocationService>();
    final messager = ScaffoldMessenger.of(context);
    setState(() => _localisation = true);
    try {
      final p = await service.positionActuelle();
      if (!mounted) return;
      setState(() => _point = p);
      _carte.deplacerSur(p, zoom: 17);
    } on LocalisationException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _localisation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Touchez la carte pour placer le point.', style: context.textes.bodyLarge),
            ),
            Expanded(
              child: CarteBase(
                controleur: _carte,
                centre: _point ?? AppConfig.centreParDefaut,
                zoom: _point == null ? 13 : 17,
                libelle: 'Carte. Touchez pour placer le point.',
                surTouche: (p) => setState(() => _point = p),
                couches: [
                  if (_point != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: _point!,
                        width: 48,
                        height: 48,
                        child: MarqueurRond(
                            icone: Icons.home_rounded,
                            couleur: c.primary,
                            taille: 48,
                            libelle: 'Point choisi'),
                      ),
                    ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _localisation ? null : _utiliserMaPosition,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Utiliser ma position actuelle'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _point == null ? null : () => Navigator.pop(context, _point),
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
