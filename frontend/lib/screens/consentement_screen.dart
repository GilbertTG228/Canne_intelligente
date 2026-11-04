import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/canne.dart';
import '../services/api_client.dart';
import '../services/repository.dart';

/// Affiché à la première ouverture pour chaque canne suivie.
class ConsentementScreen extends StatefulWidget {
  const ConsentementScreen({super.key, required this.canne});

  final Canne canne;

  @override
  State<ConsentementScreen> createState() => _ConsentementScreenState();
}

class _ConsentementScreenState extends State<ConsentementScreen> {
  bool _envoi = false;
  String? _erreur;

  Future<void> _accepter() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final repo = context.read<Repository>();
    final reglages = context.read<SettingsController>();
    try {
      await repo.enregistrerConsentement(widget.canne.id);
      await reglages.marquerConsenti(widget.canne.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.verified_user_outlined, size: 72, color: c.primary),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Suivi de ${widget.canne.nom}',
                      style: context.textes.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Point(
                    icone: Icons.location_on_outlined,
                    texte:
                        'La localisation de la personne est partagée avec vous avec son accord.',
                  ),
                  const _Point(
                    icone: Icons.undo_rounded,
                    texte:
                        'Elle peut retirer cet accord à tout moment. Le suivi s\'arrêtera alors.',
                  ),
                  const _Point(
                    icone: Icons.lock_outline_rounded,
                    texte:
                        'Ces informations sont personnelles : ne les partagez qu\'avec des proches de confiance.',
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(_erreur!,
                          style: context.textes.bodyMedium?.copyWith(color: c.error),
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _envoi ? null : _accepter,
                    child: _envoi
                        ? const SizedBox(
                            width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                        : const Text('J\'ai compris'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _envoi ? null : () => context.read<AuthController>().deconnexion(),
                    child: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.couleurs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: context.couleurs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(texte, style: context.textes.bodyLarge)),
        ],
      ),
    );
  }
}
