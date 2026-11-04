import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Message centré (liste vide, erreur) avec bouton facultatif.
class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.libelleBouton,
    this.surBouton,
  });

  final IconData icone;
  final String titre;
  final String? message;
  final String? libelleBouton;
  final VoidCallback? surBouton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: context.couleurs.outline),
            const SizedBox(height: 16),
            Text(titre, style: context.textes.titleMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: context.textes.bodyMedium?.copyWith(color: context.couleurs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (libelleBouton != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: surBouton, child: Text(libelleBouton!)),
            ],
          ],
        ),
      ),
    );
  }
}
