import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/suivi_controller.dart';
import '../utils/format.dart';

/// Bandeau affiché en haut de l'écran quand le serveur est injoignable
/// (les données affichées viennent alors du stockage local).
class BandeauHorsLigne extends StatelessWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    if (!suivi.reseauIndisponible) return const SizedBox.shrink();
    final s = context.statut;
    final maj = suivi.majCache;
    final texte = maj == null
        ? 'Vous êtes hors ligne. Données enregistrées affichées.'
        : 'Vous êtes hors ligne. Données enregistrées ${ilYa(maj)}.';
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: s.avertFond,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: s.avertTexte),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texte,
                style: context.textes.bodySmall?.copyWith(
                  color: s.avertTexte,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
