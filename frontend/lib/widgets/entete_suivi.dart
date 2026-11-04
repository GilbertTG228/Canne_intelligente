import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/alertes_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/suivi_controller.dart';
import '../models/canne.dart';

/// En-tête commun aux quatre onglets : sélecteur de canne, batterie, accès
/// aux alertes et aux paramètres.
class EnteteSuivi extends StatelessWidget {
  const EnteteSuivi({super.key, required this.surProfil});

  final VoidCallback surProfil;

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final nonTraitees = context.watch<AlertesController>().nonTraitees;
    final c = context.couleurs;
    final s = context.statut;

    return Material(
      color: c.surfaceContainerLowest,
      elevation: 1,
      shadowColor: Colors.black26,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(child: _SelecteurCanne(suivi: suivi)),
              const SizedBox(width: 8),
              _PuceBatterie(niveau: suivi.batterie),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: nonTraitees > 0
                    ? 'Voir les alertes, $nonTraitees non traitées'
                    : 'Voir les alertes',
                child: Material(
                  color: s.critiqueFond,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.read<NavigationController>().aller(3),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.error_outline_rounded, color: s.critique, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Paramètres et profil',
                child: Material(
                  color: c.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: surProfil,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.person_rounded, color: c.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelecteurCanne extends StatelessWidget {
  const _SelecteurCanne({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final canne = suivi.canne;
    final c = context.couleurs;
    final s = context.statut;
    final plusieurs = suivi.cannes.length > 1;
    final horsLigne = suivi.canneHorsLigne;
    final etat = horsLigne ? 'Hors ligne' : 'En ligne';
    final couleurEtat = horsLigne ? c.outline : s.nominal;

    return Semantics(
      button: plusieurs,
      label: canne == null
          ? 'Aucune canne'
          : 'Canne ${canne.nom}, $etat${plusieurs ? '. Toucher pour changer de canne' : ''}',
      excludeSemantics: true,
      child: Material(
        color: c.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: plusieurs ? () => _ouvrirChoix(context) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: couleurEtat, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          canne?.nom ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textes.titleSmall,
                        ),
                        Text(
                          etat,
                          style: context.textes.labelMedium?.copyWith(
                            color: horsLigne ? c.onSurfaceVariant : s.nominalTexte,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plusieurs) Icon(Icons.expand_more_rounded, color: c.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirChoix(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text('Choisir une canne', style: ctx.textes.titleLarge),
              ),
              for (final Canne canne in suivi.cannes)
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(
                    canne.id == suivi.canneId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: ctx.couleurs.primary,
                  ),
                  title: Text(canne.nom, style: ctx.textes.bodyLarge),
                  subtitle: Text(canne.identifiant),
                  onTap: () {
                    Navigator.pop(ctx);
                    suivi.selectionner(canne.id);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _PuceBatterie extends StatelessWidget {
  const _PuceBatterie({required this.niveau});
  final int? niveau;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final s = context.statut;
    final faible = niveau != null && niveau! < 20;
    final couleur = niveau == null ? c.outline : (faible ? s.critique : s.nominal);
    final icone = niveau == null
        ? Icons.battery_unknown_rounded
        : (faible ? Icons.battery_alert_rounded : Icons.battery_full_rounded);
    return Semantics(
      label: niveau == null ? 'Batterie inconnue' : 'Batterie de la canne : $niveau pour cent',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: couleur, size: 22),
            const SizedBox(width: 2),
            Text(
              niveau == null ? '—' : '$niveau%',
              style: context.textes.labelMedium?.copyWith(
                color: faible ? s.critiqueTexte : c.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
