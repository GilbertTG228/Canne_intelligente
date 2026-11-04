import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Consentement et protection des données : texte d'information.
class ProtectionDonneesScreen extends StatelessWidget {
  const ProtectionDonneesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = <(String, String)>[
      (
        'Consentement',
        'La localisation de la personne suivie n\'est partagée qu\'avec son accord. Elle peut le retirer à tout moment, simplement en le demandant à l\'administrateur du service : le suivi s\'arrête alors pour tous les proches.'
      ),
      (
        'Données collectées',
        'Position GPS de la canne, niveau de batterie, alertes (SOS, chute, entrée en zone, batterie faible, inactivité) et zones à éviter. Votre numéro de téléphone sert uniquement à vous identifier.'
      ),
      (
        'Utilisation',
        'Ces données servent exclusivement à assurer la sécurité de la personne. Elles ne sont ni vendues ni utilisées à des fins publicitaires.'
      ),
      (
        'Liens de partage',
        'Un lien de suivi donne accès à la position pendant sa durée de validité. Vous pouvez le révoquer à tout moment depuis l\'écran « Partager ».'
      ),
      (
        'Stockage sur ce téléphone',
        'Pour fonctionner sans réseau, l\'application garde les dernières données reçues sur ce téléphone. Elles sont effacées à la déconnexion. Le jeton de connexion est stocké de façon chiffrée.'
      ),
      (
        'Vos droits',
        'Vous pouvez demander l\'accès, la correction ou la suppression de vos données auprès de l\'administrateur du service.'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Protection des données')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (titre, texte) in sections) ...[
              Semantics(header: true, child: Text(titre, style: context.textes.titleMedium)),
              const SizedBox(height: 6),
              Text(texte, style: context.textes.bodyLarge),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
