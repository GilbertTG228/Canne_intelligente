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
import '../widgets/etat_vide.dart';
import '../widgets/pastille.dart';
import 'zone_edition_screen.dart';

/// Onglet « Zones » : zones à éviter de la canne.
class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final _carte = MapController();

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  void _ouvrirEdition(String canneId, [Zone? zone]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ZoneEditionScreen(zone: zone)),
    );
  }

  Future<void> _supprimer(Zone zone) async {
    final zones = context.read<ZonesController>();
    final messager = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette zone ?'),
        content: Text('La zone « ${zone.nom} » ne déclenchera plus d\'alerte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.statut.critique),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await zones.supprimer(zone);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _basculer(Zone zone, bool actif) async {
    final zones = context.read<ZonesController>();
    final messager = ScaffoldMessenger.of(context);
    try {
      await zones.basculer(zone, actif);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final zones = context.watch<ZonesController>();
    final canneId = suivi.canneId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ZonesController>().synchroniser(canneId);
    });
    final c = context.couleurs;
    final s = context.statut;
    final position = suivi.position;

    final couches = <Widget>[
      CircleLayer(circles: [
        for (final z in zones.zones)
          CircleMarker(
            point: z.centre,
            radius: z.rayon,
            useRadiusInMeter: true,
            color: (z.actif ? s.critique : c.outline).withValues(alpha: 0.22),
            borderColor: z.actif ? s.critique : c.outline,
            borderStrokeWidth: 2,
          ),
      ]),
      MarkerLayer(markers: [
        for (final z in zones.zones)
          Marker(
            point: z.centre,
            width: 36,
            height: 36,
            child: MarqueurRond(
              icone: Icons.block_rounded,
              couleur: z.actif ? s.critique : c.outline,
              taille: 36,
              libelle: 'Zone ${z.nom}',
            ),
          ),
        if (position != null)
          Marker(
            point: position.latLng,
            width: 40,
            height: 40,
            child: MarqueurRond(
                icone: Icons.directions_walk_rounded,
                couleur: c.primary,
                taille: 40,
                libelle: 'Position de la canne'),
          ),
      ]),
    ];
    final centre = position?.latLng ??
        (zones.zones.isNotEmpty ? zones.zones.first.centre : AppConfig.centreParDefaut);

    return RefreshIndicator(
      onRefresh: () => context.read<ZonesController>().charger(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Zones à éviter', style: context.textes.headlineLarge),
                ),
              ),
              Pastille('${zones.nombreActives} active${zones.nombreActives > 1 ? 's' : ''}',
                  type: TypePastille.nominal, point: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'La canne alerte lorsque la personne entre dans une zone active.',
            style: context.textes.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 240,
              child: CarteBase(
                controleur: _carte,
                centre: centre,
                zoom: 14,
                couches: couches,
                libelle: 'Carte des zones à éviter. ${zones.zones.length} zones.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canneId == null ? null : () => _ouvrirEdition(canneId),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Créer une nouvelle zone'),
          ),
          if (zones.depuisCache) ...[
            const SizedBox(height: 12),
            Text('Liste enregistrée sur ce téléphone (hors ligne).',
                style: context.textes.bodySmall?.copyWith(color: s.avertTexte)),
          ],
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text('Zones enregistrées', style: context.textes.headlineMedium),
          ),
          const SizedBox(height: 12),
          if (zones.chargement)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (zones.erreur != null && zones.zones.isEmpty)
            SizedBox(
              height: 220,
              child: EtatVide(
                icone: Icons.error_outline_rounded,
                titre: 'Chargement impossible',
                message: zones.erreur,
                libelleBouton: 'Réessayer',
                surBouton: () => context.read<ZonesController>().charger(),
              ),
            )
          else if (zones.zones.isEmpty)
            const SizedBox(
              height: 200,
              child: EtatVide(
                icone: Icons.shield_outlined,
                titre: 'Aucune zone',
                message: 'Créez une zone pour être alerté quand la canne s\'approche d\'un endroit dangereux.',
              ),
            )
          else
            for (final zone in zones.zones) ...[
              _TuileZone(
                zone: zone,
                surCentrer: () => _carte.deplacerSur(zone.centre, zoom: 16),
                surBasculer: (v) => _basculer(zone, v),
                surModifier: () => _ouvrirEdition(canneId!, zone),
                surSupprimer: () => _supprimer(zone),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _TuileZone extends StatelessWidget {
  const _TuileZone({
    required this.zone,
    required this.surCentrer,
    required this.surBasculer,
    required this.surModifier,
    required this.surSupprimer,
  });

  final Zone zone;
  final VoidCallback surCentrer;
  final ValueChanged<bool> surBasculer;
  final VoidCallback surModifier;
  final VoidCallback surSupprimer;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final s = context.statut;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: surCentrer,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: zone.actif ? s.critiqueFond : c.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.block_rounded, color: zone.actif ? s.critique : c.outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.nom, style: context.textes.titleMedium),
                        Text('Rayon ${zone.rayon.round()} m',
                            style: context.textes.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Zone ${zone.nom} : ${zone.actif ? 'active' : 'désactivée'}',
                    child: Switch(value: zone.actif, onChanged: surBasculer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: surModifier,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Supprimer la zone ${zone.nom}',
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: surSupprimer,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: s.critique,
                      ),
                      child: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
