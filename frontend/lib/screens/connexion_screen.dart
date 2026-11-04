import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../services/api_client.dart';
import 'mot_de_passe_oublie_screen.dart';

/// Connexion par numéro de téléphone et mot de passe.
class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _formulaire = GlobalKey<FormState>();
  final _telephone = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _masque = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _telephone.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formulaire.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    final auth = context.read<AuthController>();
    try {
      await auth.connexion(_telephone.text.trim(), _motDePasse.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final messageSession = context.watch<AuthController>().messageSession;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formulaire,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(Icons.assistant_navigation, size: 48, color: c.onPrimary),
                          ),
                          const SizedBox(height: 20),
                          Text('Canne Proche',
                              style: context.textes.displayMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(
                            'Suivez en toute sérénité la canne de votre proche.',
                            style: context.textes.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (messageSession != null) ...[
                      _Bandeau(message: messageSession, avertissement: true),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      style: context.textes.bodyLarge,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 6) ? 'Saisissez votre numéro de téléphone.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _motDePasse,
                      obscureText: _masque,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _valider(),
                      autofillHints: const [AutofillHints.password],
                      style: context.textes.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _masque ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                          onPressed: () => setState(() => _masque = !_masque),
                          icon: Icon(_masque ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Saisissez votre mot de passe.' : null,
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      _Bandeau(message: _erreur!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _envoi ? null : _valider,
                      child: _envoi
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const MotDePasseOublieScreen()),
                      ),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.message, this.avertissement = false});
  final String message;
  final bool avertissement;

  @override
  Widget build(BuildContext context) {
    final s = context.statut;
    final fond = avertissement ? s.avertFond : s.critiqueFond;
    final texte = avertissement ? s.avertTexte : s.critiqueTexte;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: texte),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: context.textes.bodyMedium?.copyWith(color: texte, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
