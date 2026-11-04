import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/alertes_controller.dart';
import '../controllers/suivi_controller.dart';
import '../models/alerte.dart';
import '../services/api_client.dart';
import '../utils/format.dart';
import '../widgets/alerte_visuel.dart';
import '../widgets/etat_vide.dart';
import 'alerte_en_cours_screen.dart';

/// Onglet « Alertes » : journal chronologique.
class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  bool _masquerTraitees = false;

  Future<void> _traiter(Alerte a) async {
    final controleur = context.read<AlertesController>();
    final messager = ScaffoldMessenger.of(context);
    try {
      await controleur.marquerTraitee(a.id);
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final alertes = context.watch<AlertesController>();
    final canneId = suivi.canneId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AlertesController>().synchroniser(canneId);
    });

    final liste = _masquerTraitees
        ? alertes.alertes.where((a) => !a.traitee).toList()
        : alertes.alertes;

    Widget corps;
    if (alertes.chargement && alertes.alertes.isEmpty) {
      corps = const Center(child: CircularProgressIndicator());
    } else if (alertes.erreur != null && alertes.alertes.isEmpty) {
      corps = EtatVide(
        icone: Icons.error_outline_rounded,
        titre: 'Alertes indisponibles',
        message: alertes.erreur,
        libelleBouton: 'Réessayer',
        surBouton: alertes.recharger,
      );
    } else if (liste.isEmpty) {
      corps = EtatVide(
        icone: Icons.notifications_none_rounded,
        titre: _masquerTraitees ? 'Aucune alerte à traiter' : 'Aucune alerte',
        message: 'Tout est calme. Les nouvelles alertes apparaîtront ici.',
      );
    } else {
      corps = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: liste.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _TuileAlerte(
          alerte: liste[i],
          surTraiter: () => _traiter(liste[i]),
          surOuvrir: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AlerteEnCoursScreen(alerte: liste[i]),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Alertes', style: context.textes.headlineLarge),
                ),
              ),
              FilterChip(
                label: const Text('À traiter'),
                selected: _masquerTraitees,
                onSelected: (v) => setState(() => _masquerTraitees = v),
              ),
            ],
          ),
        ),
        if (alertes.depuisCache)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Journal enregistré sur ce téléphone (hors ligne).',
                  style: context.textes.bodySmall?.copyWith(color: context.statut.avertTexte)),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<AlertesController>().recharger(),
            child: corps is ListView
                ? corps
                : LayoutBuilder(
                    // Permet le « tirer pour actualiser » même sur un état vide.
                    builder: (context, contraintes) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: contraintes.maxHeight, child: corps),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TuileAlerte extends StatelessWidget {
  const _TuileAlerte({
    required this.alerte,
    required this.surTraiter,
    required this.surOuvrir,
  });

  final Alerte alerte;
  final VoidCallback surTraiter;
  final VoidCallback surOuvrir;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final couleur = couleurAlerte(context, alerte);
    final fond = fondAlerte(context, alerte);
    final titre = titreAlerte(alerte);
    final date = dateHeure(alerte.horodatage);
    final zone = alerte.zoneNom;

    return Opacity(
      opacity: alerte.traitee ? 0.7 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: surOuvrir,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
                        child: Icon(iconeAlerte(alerte.type), color: couleur, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titre, style: context.textes.titleSmall),
                            const SizedBox(height: 2),
                            Text(date,
                                style: context.textes.bodyMedium
                                    ?.copyWith(color: c.onSurfaceVariant)),
                            if (zone != null && zone.isNotEmpty)
                              Text('Zone : $zone', style: context.textes.bodyMedium),
                            Text(alerte.traitee ? 'Traitée' : 'À traiter',
                                style: context.textes.labelMedium?.copyWith(
                                  color: alerte.traitee
                                      ? context.statut.nominalTexte
                                      : texteAlerte(context, alerte),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (alerte.traitee)
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: context.statut.nominal),
                      const SizedBox(width: 8),
                      Text('Marquée comme traitée', style: context.textes.bodyMedium),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: surTraiter,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Marquer comme traitée'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
