import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../controllers/alertes_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/suivi_controller.dart';
import '../models/alerte.dart';
import '../services/api_client.dart';
import '../utils/format.dart';
import '../widgets/alerte_visuel.dart';
import '../widgets/carte_base.dart';

/// Écran plein affiché lors d'un SOS ou d'une entrée en zone (ouvert par une
/// notification ou depuis le journal d'alertes).
class AlerteEnCoursScreen extends StatefulWidget {
  const AlerteEnCoursScreen({super.key, required this.alerte});

  final Alerte alerte;

  @override
  State<AlerteEnCoursScreen> createState() => _AlerteEnCoursScreenState();
}

class _AlerteEnCoursScreenState extends State<AlerteEnCoursScreen> {
  final _carte = MapController();
  bool _envoi = false;
  late bool _traitee = widget.alerte.traitee;

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  Future<void> _acquitter() async {
    final alertes = context.read<AlertesController>();
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    setState(() => _envoi = true);
    try {
      if (widget.alerte.id.isNotEmpty) {
        await alertes.marquerTraitee(widget.alerte.id);
      }
      if (mounted) setState(() => _traitee = true);
      navigateur.pop();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _appeler(String numero) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: numero));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le composeur.')));
    }
  }

  void _voirSurCarte() {
    final a = widget.alerte;
    final suivi = context.read<SuiviController>();
    final point = a.position ?? suivi.position?.latLng;
    final nav = context.read<NavigationController>();
    Navigator.of(context).popUntil((r) => r.isFirst);
    nav.aller(0, focus: point);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alerte;
    final suivi = context.watch<SuiviController>();
    final c = context.couleurs;
    final couleur = couleurAlerte(context, a);
    final fond = fondAlerte(context, a);
    final texte = texteAlerte(context, a);
    final canne = suivi.cannes.where((x) => x.id == a.canneId).firstOrNull ?? suivi.canne;
    final telephone = canne?.telephonePersonne;
    final point = a.position ?? suivi.position?.latLng;

    return Scaffold(
      backgroundColor: fond,
      appBar: AppBar(
        backgroundColor: fond,
        title: Text(a.critique ? 'Alerte' : 'Information'),
        leading: IconButton(
          tooltip: 'Fermer',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                          child: Icon(iconeAlerte(a.type), color: Colors.white, size: 56),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          titreAlerte(a),
                          style: context.textes.displayMedium?.copyWith(color: texte),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${canne?.nom ?? 'Canne'} • ${ilYa(a.horodatage)} (${heure(a.horodatage)})',
                          style: context.textes.bodyLarge?.copyWith(color: texte),
                          textAlign: TextAlign.center,
                        ),
                        if (a.zoneNom != null && a.zoneNom!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Zone : ${a.zoneNom}',
                              style: context.textes.titleMedium?.copyWith(color: texte)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (point != null)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 220,
                            child: CarteBase(
                              controleur: _carte,
                              centre: point,
                              zoom: 17,
                              interactive: false,
                              libelle: 'Carte. Position de l\'alerte.',
                              couches: [
                                MarkerLayer(markers: [
                                  Marker(
                                    point: point,
                                    width: 52,
                                    height: 52,
                                    child: MarqueurRond(
                                        icone: iconeAlerte(a.type),
                                        couleur: couleur,
                                        taille: 52,
                                        libelle: 'Position de l\'alerte'),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.place_outlined, color: c.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    coordonnees(point.latitude, point.longitude),
                                    style: context.textes.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Position non communiquée pour cette alerte.',
                            style: context.textes.bodyLarge),
                      ),
                    ),
                ],
              ),
            ),
            // Actions ancrées en bas : zone de pouce, hors de portée des erreurs.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceContainerLowest,
                border: Border(top: BorderSide(color: couleur, width: 4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.statut.critique,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 56),
                    ),
                    onPressed: (telephone == null || telephone.isEmpty)
                        ? null
                        : () => _appeler(telephone),
                    icon: const Icon(Icons.call_rounded),
                    label: Text(
                      (telephone == null || telephone.isEmpty)
                          ? 'Numéro de la personne indisponible'
                          : 'Appeler la personne',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _voirSurCarte,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Voir sur la carte'),
                  ),
                  const SizedBox(height: 12),
                  if (_traitee)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: context.statut.nominal),
                        const SizedBox(width: 8),
                        Text('Alerte traitée', style: context.textes.titleSmall),
                      ],
                    )
                  else
                    FilledButton.icon(
                      onPressed: _envoi ? null : _acquitter,
                      icon: _envoi
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Icon(Icons.done_all_rounded),
                      label: const Text('J\'ai pris en charge l\'alerte'),
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
