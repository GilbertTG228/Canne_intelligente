import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/historique_controller.dart';
import '../controllers/suivi_controller.dart';
import '../models/trajet.dart';
import '../utils/format.dart';
import '../widgets/carte_base.dart';
import '../widgets/etat_vide.dart';
import '../widgets/selecteurs_periode.dart';

/// Onglet « Historique » : tracé des positions et liste des trajets.
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final _carte = MapController();
  int _versionAffichee = -1;

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  /// Recadre la carte quand les données ou la sélection changent.
  void _recadrerSiBesoin(HistoriqueController h) {
    if (_versionAffichee == h.version) return;
    _versionAffichee = h.version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selection = h.trajetSelectionne;
      final points = selection != null && selection < h.trajets.length
          ? h.trajets[selection].points
          : h.trajets.expand((t) => t.points).toList();
      _carte.ajusterSur(points);
    });
  }

  Future<void> _choisirDate(HistoriqueController h) async {
    DateTime? choix;
    switch (h.periode) {
      case Periode.jour:
        choix = await showDatePicker(
          context: context,
          initialDate: h.date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          helpText: 'Choisir un jour',
        );
      case Periode.mois:
        choix = await choisirMois(context, h.date);
      case Periode.annee:
        choix = await choisirAnnee(context, h.date);
    }
    if (choix != null) h.definirDate(choix);
  }

  String _libelleDate(HistoriqueController h) {
    switch (h.periode) {
      case Periode.jour:
        return dateLongue(h.date);
      case Periode.mois:
        return moisAnnee(h.date);
      case Periode.annee:
        return '${h.date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final h = context.watch<HistoriqueController>();
    final canneId = suivi.canneId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoriqueController>().synchroniser(canneId);
    });
    _recadrerSiBesoin(h);

    final c = context.couleurs;
    final s = context.statut;
    final selection = h.trajetSelectionne;
    final centre = suivi.position?.latLng ?? AppConfig.centreParDefaut;

    final polylines = <Polyline>[
      for (var i = 0; i < h.trajets.length; i++)
        Polyline(
          points: h.trajets[i].points,
          strokeWidth: selection == i ? 7 : 5,
          color: selection == null || selection == i
              ? c.primary
              : c.primary.withValues(alpha: 0.35),
        ),
    ];
    final trajetAffiche = selection != null && selection < h.trajets.length
        ? h.trajets[selection]
        : null;
    final debuts = trajetAffiche != null
        ? [trajetAffiche]
        : (h.trajets.isEmpty ? <Trajet>[] : [h.trajets.first, h.trajets.last]);

    return RefreshIndicator(
      onRefresh: () => context.read<HistoriqueController>().charger(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Filtre : jour / mois / année
          SegmentedButton<Periode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
            segments: const [
              ButtonSegment(value: Periode.jour, label: Text('Jour')),
              ButtonSegment(value: Periode.mois, label: Text('Mois')),
              ButtonSegment(value: Periode.annee, label: Text('Année')),
            ],
            selected: {h.periode},
            onSelectionChanged: (v) => h.changerPeriode(v.first),
          ),
          const SizedBox(height: 12),
          // Sélecteur de date
          Card(
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Période précédente',
                  iconSize: 28,
                  onPressed: h.precedent,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Choisir la date : ${_libelleDate(h)}',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => _choisirDate(h),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_outlined, color: c.primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _libelleDate(h),
                                style: context.textes.titleSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Période suivante',
                  iconSize: 28,
                  onPressed: h.peutAvancer ? h.suivant : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Carte
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CarteBase(
                      controleur: _carte,
                      centre: centre,
                      zoom: 14,
                      libelle: h.trajets.isEmpty
                          ? 'Carte de l\'historique. Aucun trajet sur cette période.'
                          : 'Carte de l\'historique. ${h.trajets.length} trajets, ${distanceLisible(h.distanceTotaleM)}.',
                      couches: [
                        PolylineLayer(polylines: polylines),
                        MarkerLayer(markers: [
                          for (final t in debuts) ...[
                            Marker(
                              point: t.positions.first.latLng,
                              width: 28,
                              height: 28,
                              child: MarqueurRond(
                                  icone: Icons.play_arrow_rounded,
                                  couleur: s.nominal,
                                  taille: 28,
                                  libelle: 'Départ ${heure(t.debut)}'),
                            ),
                            Marker(
                              point: t.positions.last.latLng,
                              width: 28,
                              height: 28,
                              child: MarqueurRond(
                                  icone: Icons.stop_rounded,
                                  couleur: c.primary,
                                  taille: 28,
                                  libelle: 'Arrivée ${heure(t.fin)}'),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  if (h.chargement)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x55FFFFFF),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (h.depuisCache)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Historique enregistré sur ce téléphone (hors ligne).',
                  style: context.textes.bodySmall?.copyWith(color: s.avertTexte)),
            ),
          const SizedBox(height: 16),
          if (h.erreur != null && h.trajets.isEmpty)
            SizedBox(
              height: 220,
              child: EtatVide(
                icone: Icons.error_outline_rounded,
                titre: 'Historique indisponible',
                message: h.erreur,
                libelleBouton: 'Réessayer',
                surBouton: h.charger,
              ),
            )
          else if (!h.chargement && h.trajets.isEmpty)
            const SizedBox(
              height: 200,
              child: EtatVide(
                icone: Icons.route_outlined,
                titre: 'Aucun trajet',
                message: 'Aucun déplacement enregistré sur cette période.',
              ),
            )
          else ...[
            _Resume(h: h),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text('Trajets enregistrés', style: context.textes.headlineMedium),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < h.trajets.length; i++) ...[
              _TuileTrajet(
                numero: i + 1,
                trajet: h.trajets[i],
                avecDate: h.periode != Periode.jour,
                selectionne: selection == i,
                surTouche: () => h.selectionnerTrajet(i),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _Resume extends StatelessWidget {
  const _Resume({required this.h});
  final HistoriqueController h;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: c.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Résumé', style: context.textes.titleMedium)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _Chiffre(
                        icone: Icons.directions_walk_rounded,
                        valeur: '${h.trajets.length}',
                        libelle: h.trajets.length > 1 ? 'Trajets' : 'Trajet')),
                const SizedBox(width: 8),
                Expanded(
                    child: _Chiffre(
                        icone: Icons.straighten_rounded,
                        valeur: distanceLisible(h.distanceTotaleM),
                        libelle: 'Distance')),
                const SizedBox(width: 8),
                Expanded(
                    child: _Chiffre(
                        icone: Icons.timer_outlined,
                        valeur: dureeLisible(h.dureeTotale),
                        libelle: 'En marche')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({required this.icone, required this.valeur, required this.libelle});
  final IconData icone;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$libelle : $valeur',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: context.statut.surfaceDouce,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icone, color: context.couleurs.primary),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(valeur, style: context.textes.titleMedium),
            ),
            Text(libelle,
                style: context.textes.labelMedium?.copyWith(color: context.couleurs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TuileTrajet extends StatelessWidget {
  const _TuileTrajet({
    required this.numero,
    required this.trajet,
    required this.avecDate,
    required this.selectionne,
    required this.surTouche,
  });

  final int numero;
  final Trajet trajet;
  final bool avecDate;
  final bool selectionne;
  final VoidCallback surTouche;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final titre = avecDate ? 'Trajet du ${dateCourte(trajet.debut)}' : 'Trajet $numero';
    final horaires = '${heure(trajet.debut)} – ${heure(trajet.fin)}';
    final duree = dureeLisible(trajet.duree);
    return Semantics(
      button: true,
      selected: selectionne,
      label:
          '$titre, de ${heure(trajet.debut)} à ${heure(trajet.fin)}, ${distanceLisible(trajet.distanceM)}, $duree. Toucher pour l\'afficher sur la carte.',
      excludeSemantics: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selectionne ? c.primary : context.statut.bordure,
            width: selectionne ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: surTouche,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.route_rounded, color: c.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titre, style: context.textes.titleSmall),
                      const SizedBox(height: 2),
                      Text('$horaires  •  $duree',
                          style: context.textes.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    distanceLisible(trajet.distanceM),
                    style: context.textes.labelMedium?.copyWith(color: c.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
