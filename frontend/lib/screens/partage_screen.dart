import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../controllers/suivi_controller.dart';
import '../models/lien_partage.dart';
import '../services/api_client.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import '../widgets/etat_vide.dart';

/// Partage temporaire du suivi : génère un lien (1 h, 4 h ou 24 h) pour un
/// autre proche sans compte, et permet de révoquer les liens actifs.
class PartageScreen extends StatefulWidget {
  const PartageScreen({super.key});

  @override
  State<PartageScreen> createState() => _PartageScreenState();
}

class _PartageScreenState extends State<PartageScreen> {
  static const _durees = [1, 4, 24];

  int _duree = 1;
  bool _creation = false;
  bool _chargement = true;
  String? _erreur;
  String? _nouveauLien;
  List<LienPartage> _liens = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final repo = context.read<Repository>();
    final canneId = context.read<SuiviController>().canneId;
    try {
      final tous = await repo.liensPartage();
      if (!mounted) return;
      setState(() {
        _liens = tous
            .where((l) => !l.expire && (l.canneId == null || l.canneId == canneId))
            .toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _generer() async {
    final repo = context.read<Repository>();
    final canne = context.read<SuiviController>().canne;
    final messager = ScaffoldMessenger.of(context);
    if (canne == null) return;
    setState(() => _creation = true);
    try {
      final lien = await repo.creerLienPartage(canne.id, _duree);
      if (!mounted) return;
      setState(() => _nouveauLien = lien);
      await _charger();
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _creation = false);
    }
  }

  Future<void> _copier(String lien) async {
    final messager = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: lien));
    messager.showSnackBar(const SnackBar(content: Text('Lien copié dans le presse-papiers.')));
  }

  Future<void> _envoyer(String lien) async {
    final canne = context.read<SuiviController>().canne;
    await Share.share(
      'Suivez la position de ${canne?.nom ?? 'la canne'} en direct (lien temporaire) : $lien',
      subject: 'Lien de suivi',
    );
  }

  Future<void> _revoquer(LienPartage lien) async {
    final repo = context.read<Repository>();
    final messager = ScaffoldMessenger.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer ce lien ?'),
        content: const Text('La personne qui l\'a reçu ne pourra plus voir la position.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.statut.critique),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await repo.revoquerLien(lien.id);
      if (!mounted) return;
      setState(() {
        _liens = _liens.where((l) => l.id != lien.id).toList();
        if (_nouveauLien == lien.lien) _nouveauLien = null;
      });
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canne = context.watch<SuiviController>().canne;
    final c = context.couleurs;

    return Scaffold(
      appBar: AppBar(title: const Text('Partager le suivi')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                'Envoyez un lien temporaire à un autre proche : il verra la position de ${canne?.nom ?? 'la canne'} sans avoir besoin de compte.',
                style: context.textes.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text('Durée de validité', style: context.textes.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(minimumSize: const Size(0, 52)),
                segments: [
                  for (final d in _durees) ButtonSegment(value: d, label: Text('$d h')),
                ],
                selected: {_duree},
                onSelectionChanged: (v) => setState(() => _duree = v.first),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: (_creation || canne == null) ? null : _generer,
                icon: _creation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.link_rounded),
                label: const Text('Générer le lien'),
              ),
              if (_nouveauLien != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lien créé (valable $_duree h)', style: context.textes.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(_nouveauLien!,
                            style: context.textes.bodyMedium?.copyWith(color: c.primary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copier(_nouveauLien!),
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copier'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _envoyer(_nouveauLien!),
                                icon: const Icon(Icons.send_rounded),
                                label: const Text('Envoyer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Semantics(
                header: true,
                child: Text('Liens actifs', style: context.textes.headlineMedium),
              ),
              const SizedBox(height: 12),
              if (_chargement)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_erreur != null)
                SizedBox(
                  height: 200,
                  child: EtatVide(
                    icone: Icons.error_outline_rounded,
                    titre: 'Liste indisponible',
                    message: _erreur,
                    libelleBouton: 'Réessayer',
                    surBouton: _charger,
                  ),
                )
              else if (_liens.isEmpty)
                const SizedBox(
                  height: 160,
                  child: EtatVide(
                    icone: Icons.link_off_rounded,
                    titre: 'Aucun lien actif',
                  ),
                )
              else
                for (final lien in _liens) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: c.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.link_rounded, color: c.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lien.lien,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textes.bodyMedium,
                                ),
                                Text(
                                  lien.expireLe == null
                                      ? 'Durée inconnue'
                                      : 'Expire à ${heure(lien.expireLe!)} (${_dans(lien.expireLe!)})',
                                  style: context.textes.bodySmall
                                      ?.copyWith(color: c.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copier le lien',
                            onPressed: () => _copier(lien.lien),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                          IconButton(
                            tooltip: 'Révoquer le lien',
                            onPressed: () => _revoquer(lien),
                            icon: Icon(Icons.link_off_rounded, color: context.statut.critique),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  String _dans(DateTime fin) {
    final reste = fin.difference(DateTime.now());
    if (reste.isNegative) return 'expiré';
    return 'dans ${dureeLisible(reste)}';
  }
}
