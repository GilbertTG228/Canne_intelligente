import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Écran simple : le serveur se charge d'envoyer la réinitialisation.
class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  bool _envoi = false;
  bool _envoye = false;
  String? _erreur;

  @override
  void dispose() {
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formulaire.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final auth = context.read<AuthService>();
    try {
      await auth.motDePasseOublie(_telephone.text.trim());
      if (mounted) setState(() => _envoye = true);
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
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _envoye
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 64, color: context.statut.nominal),
                    const SizedBox(height: 16),
                    Text('Demande envoyée', style: context.textes.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Si ce numéro correspond à un compte, vous recevrez les instructions pour choisir un nouveau mot de passe.',
                      style: context.textes.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                )
              : Form(
                  key: _formulaire,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Saisissez le numéro de téléphone de votre compte. Nous vous enverrons de quoi choisir un nouveau mot de passe.',
                        style: context.textes.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _telephone,
                        keyboardType: TextInputType.phone,
                        style: context.textes.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().length < 6)
                            ? 'Saisissez votre numéro de téléphone.'
                            : null,
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(_erreur!,
                              style: context.textes.bodyMedium?.copyWith(color: c.error)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _envoi ? null : _envoyer,
                        child: _envoi
                            ? const SizedBox(
                                width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                            : const Text('Envoyer la demande'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
