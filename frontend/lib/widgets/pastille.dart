import 'package:flutter/material.dart';

import '../config/theme.dart';

enum TypePastille { nominal, avertissement, critique, neutre }

/// Pastille de statut en forme de gélule (« En ligne », « Canne inactive »…).
class Pastille extends StatelessWidget {
  const Pastille(this.texte, {super.key, this.type = TypePastille.neutre, this.icone, this.point = false});

  final String texte;
  final TypePastille type;
  final IconData? icone;
  final bool point;

  @override
  Widget build(BuildContext context) {
    final s = context.statut;
    final c = context.couleurs;
    final (Color fond, Color texteCouleur, Color bord) = switch (type) {
      TypePastille.nominal => (s.nominalFond, s.nominalTexte, s.nominal),
      TypePastille.avertissement => (s.avertFond, s.avertTexte, s.avert),
      TypePastille.critique => (s.critiqueFond, s.critiqueTexte, s.critique),
      TypePastille.neutre => (c.surfaceContainerHigh, c.onSurfaceVariant, c.outlineVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bord.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (point) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: bord, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icone != null) ...[
            Icon(icone, size: 16, color: texteCouleur),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texte,
              style: context.textes.labelMedium?.copyWith(color: texteCouleur),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
