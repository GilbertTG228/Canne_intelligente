import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/suivi_controller.dart';
import '../services/api_client.dart';
import '../services/repository.dart';
import 'protection_donnees_screen.dart';
import 'selection_point_screen.dart';

/// Paramètres : profil, canne inactive, notifications, apparence, domicile,
/// données personnelles, déconnexion.
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  /// Envoie délai et notifications au serveur (PUT /api/utilisateur/parametres).
  /// Les réglages restent enregistrés sur le téléphone même si l'envoi échoue.
  Future<void> _synchroniser(BuildContext context) async {
    final reglages = context.read<SettingsController>();
    final repo = context.read<Repository>();
    final messager = ScaffoldMessenger.of(context);
    try {
      await repo.enregistrerParametres(
        delaiInactiviteMinutes: reglages.delaiInactiviteMin,
        notificationsActives: reglages.notificationsActives,
      );
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(
        content: Text('Réglage enregistré sur ce téléphone, mais pas sur le serveur : ${e.message}'),
      ));
    }
  }

  Future<void> _modifierNom(BuildContext context, SettingsController r) async {
    final controleur = TextEditingController(text: r.nomAffiche);
    final nom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Votre nom'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nom affiché'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controleur.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    controleur.dispose();
    if (nom != null) await r.definirNomAffiche(nom);
  }

  Future<void> _choisirDomicile(BuildContext context, SettingsController r) async {
    final point = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (_) => SelectionPointScreen(titre: 'Domicile', initial: r.domicile),
      ),
    );
    if (point != null) await r.definirDomicile(point);
  }

  Future<void> _testerSos(BuildContext context) async {
    final suivi = context.read<SuiviController>();
    final repo = context.read<Repository>();
    final messager = ScaffoldMessenger.of(context);
    final canne = suivi.canne;
    if (canne == null) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déclencher un SOS de test ?'),
        content: Text('Une alerte SOS sera simulée pour ${canne.nom}. Les autres proches la recevront aussi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déclencher')),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await repo.declencherSos(canne.id);
      messager.showSnackBar(const SnackBar(content: Text('SOS de test envoyé.')));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deconnecter(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous ne recevrez plus les alertes sur ce téléphone et les données enregistrées seront effacées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.statut.critique),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirme == true) await auth.deconnexion();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<SettingsController>();
    final c = context.couleurs;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Titre('Profil'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    minTileHeight: 64,
                    leading: Icon(Icons.person_outline_rounded, color: c.primary),
                    title: Text(r.nomAffiche.isEmpty ? 'Nom non renseigné' : r.nomAffiche),
                    subtitle: const Text('Nom affiché'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _modifierNom(context, r),
                  ),
                  const Divider(),
                  ListTile(
                    minTileHeight: 64,
                    leading: Icon(Icons.phone_outlined, color: c.primary),
                    title: Text(r.telephone ?? '—'),
                    subtitle: const Text('Numéro de connexion'),
                  ),
                ],
              ),
            ),
            const _Titre('Canne inactive'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alerter si la canne n\'envoie plus de position depuis :',
                        style: context.textes.bodyLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in AppConfig.delaisInactiviteMin)
                          ChoiceChip(
                            label: Text(m < 60 ? '$m min' : '${m ~/ 60} h'),
                            selected: r.delaiInactiviteMin == m,
                            onSelected: (_) async {
                              await r.definirDelaiInactivite(m);
                              if (context.mounted) await _synchroniser(context);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const _Titre('Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Recevoir les alertes'),
                    subtitle: const Text('SOS, chute, entrée en zone, batterie, inactivité'),
                    secondary: Icon(Icons.notifications_active_outlined, color: c.primary),
                    value: r.notificationsActives,
                    onChanged: (v) async {
                      await r.definirNotifications(v);
                      if (context.mounted) await _synchroniser(context);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Sons'),
                    secondary: Icon(Icons.volume_up_outlined, color: c.primary),
                    value: r.sons,
                    onChanged: r.definirSons,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Vibrations'),
                    secondary: Icon(Icons.vibration_rounded, color: c.primary),
                    value: r.vibrations,
                    onChanged: r.definirVibrations,
                  ),
                ],
              ),
            ),
            const _Titre('Apparence'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(minimumSize: const Size(0, 52)),
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Auto'),
                        icon: Icon(Icons.brightness_auto_rounded)),
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Clair'),
                        icon: Icon(Icons.light_mode_outlined)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Sombre'),
                        icon: Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {r.themeMode},
                  onSelectionChanged: (v) => r.definirTheme(v.first),
                ),
              ),
            ),
            const _Titre('Domicile'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    minTileHeight: 64,
                    leading: Icon(Icons.home_outlined, color: c.primary),
                    title: Text(r.domicile == null ? 'Non défini' : 'Domicile enregistré'),
                    subtitle: const Text('Destination possible de l\'itinéraire de retour'),
                    trailing: const Icon(Icons.edit_location_alt_outlined),
                    onTap: () => _choisirDomicile(context, r),
                  ),
                  if (r.domicile != null) ...[
                    const Divider(),
                    ListTile(
                      minTileHeight: 56,
                      leading: Icon(Icons.delete_outline_rounded, color: context.statut.critique),
                      title: const Text('Supprimer le domicile'),
                      onTap: () => r.definirDomicile(null),
                    ),
                  ],
                ],
              ),
            ),
            const _Titre('Données personnelles'),
            Card(
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(Icons.verified_user_outlined, color: c.primary),
                title: const Text('Consentement et protection des données'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ProtectionDonneesScreen()),
                ),
              ),
            ),
            const _Titre('Outils'),
            Card(
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(Icons.sos_rounded, color: context.statut.critique),
                title: const Text('Tester une alerte SOS'),
                subtitle: const Text('Vérifie que les notifications arrivent bien'),
                onTap: () => _testerSos(context),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.statut.critique,
                side: BorderSide(color: context.statut.critique, width: 1.5),
              ),
              onPressed: () => _deconnecter(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Semantics(
        header: true,
        child: Text(texte, style: context.textes.titleMedium),
      ),
    );
  }
}
