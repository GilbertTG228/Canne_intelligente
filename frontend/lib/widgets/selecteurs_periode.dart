import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../utils/format.dart';

/// Choix d'un mois (retourne le 1er jour du mois) dans une boîte de dialogue.
Future<DateTime?> choisirMois(BuildContext context, DateTime initial) {
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      var annee = initial.year;
      final maintenant = DateTime.now();
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Année précédente',
                onPressed: () => setState(() => annee--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('$annee', style: ctx.textes.titleLarge),
              IconButton(
                tooltip: 'Année suivante',
                onPressed: annee < maintenant.year ? () => setState(() => annee++) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (var m = 1; m <= 12; m++)
                  _CaseChoix(
                    libelle: capitaliser(DateFormat('MMM', 'fr_FR').format(DateTime(2000, m))),
                    selectionnee: annee == initial.year && m == initial.month,
                    active: DateTime(annee, m, 1).isBefore(maintenant),
                    surTouche: () => Navigator.pop(ctx, DateTime(annee, m, 1)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ],
        ),
      );
    },
  );
}

/// Choix d'une année (retourne le 1er janvier).
Future<DateTime?> choisirAnnee(BuildContext context, DateTime initial) {
  final courante = DateTime.now().year;
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Choisir une année'),
      content: SizedBox(
        width: 280,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var a = courante - 5; a <= courante; a++)
              _CaseChoix(
                libelle: '$a',
                selectionnee: a == initial.year,
                active: true,
                surTouche: () => Navigator.pop(ctx, DateTime(a, 1, 1)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
      ],
    ),
  );
}

class _CaseChoix extends StatelessWidget {
  const _CaseChoix({
    required this.libelle,
    required this.selectionnee,
    required this.active,
    required this.surTouche,
  });

  final String libelle;
  final bool selectionnee;
  final bool active;
  final VoidCallback surTouche;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Semantics(
      button: true,
      selected: selectionnee,
      enabled: active,
      label: libelle,
      excludeSemantics: true,
      child: Material(
        color: selectionnee ? c.primary : c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: active ? surTouche : null,
          child: Center(
            child: Text(
              libelle,
              style: context.textes.labelLarge?.copyWith(
                color: selectionnee
                    ? c.onPrimary
                    : (active ? c.onSurface : c.onSurface.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
