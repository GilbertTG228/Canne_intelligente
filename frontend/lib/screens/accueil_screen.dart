import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/suivi_controller.dart';
import '../models/itineraire.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/routing_service.dart';
import '../utils/format.dart';
import '../widgets/carte_base.dart';
import '../widgets/pastille.dart';
import 'partage_screen.dart';
import 'parametres_screen.dart';

/// Onglet « Accueil » : carte en direct, état de la canne, itinéraire de retour.
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final _carte = MapController();
  Itineraire? _itineraire;
  String? _itineraireCanneId;
  bool _calcul = false;

  /// La carte suit la canne tant que le proche ne la déplace pas à la main.
  bool _suivre = true;
  String? _centreePour; // canne pour laquelle la carte a déjà été centrée
  DateTime? _dernierHorodatageSuivi;

  @override
  void dispose() {
    _carte.dispose();
    super.dispose();
  }

  void _planifierCentrage(SuiviController suivi, NavigationController nav) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Demande explicite (« Voir sur la carte » depuis une alerte).
      final focus = nav.focus;
      if (focus != null) {
        nav.focusTraite();
        _suivre = false;
        _carte.deplacerSur(focus, zoom: 17);
        return;
      }
      final p = suivi.position;
      if (p == null) return;
      final canneChangee = _centreePour != suivi.canneId;
      final nouvellePosition = _dernierHorodatageSuivi != p.horodatage;
      if (canneChangee) {
        _centreePour = suivi.canneId;
        _suivre = true;
        _itineraire = null;
        _carte.deplacerSur(p.latLng, zoom: 17);
      } else if (_suivre && nouvellePosition) {
        _carte.deplacerSur(p.latLng);
      }
      _dernierHorodatageSuivi = p.horodatage;
    });
  }

  void _recentrer(SuiviController suivi) {
    final p = suivi.position;
    if (p == null) return;
    setState(() => _suivre = true);
    _carte.deplacerSur(p.latLng, zoom: 17);
  }

  // --- Itinéraire ---------------------------------------------------------------

  Future<void> _choisirDestination() async {
    final reglages = context.read<SettingsController>();
    final choix = await showModalBottomSheet<_Destination>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Itinéraire de retour', style: ctx.textes.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Tracer le chemin à pied depuis la canne jusqu\'à :',
                style: ctx.textes.bodyMedium?.copyWith(color: ctx.couleurs.onSurfaceVariant),
              ),
            ),
            ListTile(
              minTileHeight: 64,
              leading: Icon(Icons.person_pin_circle_outlined, color: ctx.couleurs.primary, size: 32),
              title: Text('Ma position', style: ctx.textes.titleSmall),
              subtitle: const Text('Là où se trouve mon téléphone'),
              onTap: () => Navigator.pop(ctx, _Destination.maPosition),
            ),
            ListTile(
              minTileHeight: 64,
              enabled: reglages.domicile != null,
              leading: Icon(Icons.home_outlined, color: ctx.couleurs.primary, size: 32),
              title: Text('Domicile', style: ctx.textes.titleSmall),
              subtitle: Text(reglages.domicile != null
                  ? 'Adresse enregistrée dans les paramètres'
                  : 'Non défini : à renseigner dans les paramètres'),
              onTap: reglages.domicile != null
                  ? () => Navigator.pop(ctx, _Destination.domicile)
                  : null,
            ),
            if (reglages.domicile == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(ctx, _Destination.definirDomicile),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Définir le domicile'),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choix == null || !mounted) return;
    if (choix == _Destination.definirDomicile) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ParametresScreen()),
      );
      return;
    }
    await _calculer(choix);
  }

  Future<void> _calculer(_Destination destination) async {
    final suivi = context.read<SuiviController>();
    final reglages = context.read<SettingsController>();
    final routage = context.read<RoutingService>();
    final localisation = context.read<LocationService>();
    final messager = ScaffoldMessenger.of(context);
    final depart = suivi.position?.latLng;
    if (depart == null) {
      messager.showSnackBar(const SnackBar(content: Text('Position de la canne inconnue.')));
      return;
    }
    setState(() => _calcul = true);
    try {
      late final LatLng arrivee;
      late final String libelle;
      if (destination == _Destination.domicile) {
        arrivee = reglages.domicile!;
        libelle = 'le domicile';
      } else {
        arrivee = await localisation.positionActuelle();
        libelle = 'votre position';
      }
      final resultat = await routage.calculer(
        depart: depart,
        arrivee: arrivee,
        libelleDestination: libelle,
      );
      if (!mounted) return;
      setState(() {
        _itineraire = resultat;
        _itineraireCanneId = suivi.canneId;
        _suivre = false;
      });
      _carte.ajusterSur([...resultat.points, depart, arrivee]);
    } on LocalisationException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      messager.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _calcul = false);
    }
  }

  Future<void> _appeler(String numero) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: numero));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le composeur.')));
    }
  }

  // --- Affichage ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final suivi = context.watch<SuiviController>();
    final reglages = context.watch<SettingsController>();
    final nav = context.read<NavigationController>();
    final canne = suivi.canne;
    if (canne == null) return const SizedBox.shrink();
    _planifierCentrage(suivi, nav);

    final position = suivi.position;
    final horsLigne = suivi.canneHorsLigne;
    final c = context.couleurs;
    final s = context.statut;
    final itineraire = _itineraireCanneId == suivi.canneId ? _itineraire : null;
    final centreInitial = position?.latLng ?? reglages.domicile ?? AppConfig.centreParDefaut;

    final couches = <Widget>[
      if (position?.precision != null && position!.precision! > 0)
        CircleLayer(circles: [
          CircleMarker(
            point: position.latLng,
            radius: position.precision!,
            useRadiusInMeter: true,
            color: (horsLigne ? c.outline : c.primary).withValues(alpha: 0.18),
            borderColor: horsLigne ? c.outline : c.primary,
            borderStrokeWidth: 1.5,
          ),
        ]),
      if (itineraire != null)
        PolylineLayer(polylines: [
          Polyline(points: itineraire.points, strokeWidth: 6, color: c.primary),
        ]),
      MarkerLayer(markers: [
        if (reglages.domicile != null)
          Marker(
            point: reglages.domicile!,
            width: 40,
            height: 40,
            child: MarqueurRond(
                icone: Icons.home_rounded, couleur: s.nominal, taille: 40, libelle: 'Domicile'),
          ),
        if (itineraire != null)
          Marker(
            point: itineraire.destination,
            width: 40,
            height: 40,
            child: MarqueurRond(
                icone: Icons.flag_rounded,
                couleur: s.avert,
                taille: 40,
                libelle: 'Arrivée : ${itineraire.libelleDestination}'),
          ),
        if (position != null)
          Marker(
            point: position.latLng,
            width: 56,
            height: 56,
            child: MarqueurRond(
              icone: Icons.directions_walk_rounded,
              couleur: horsLigne ? c.outline : c.primary,
              taille: 56,
              libelle: 'Position de ${canne.nom}',
            ),
          ),
      ]),
    ];

    return Column(
      children: [
        if (horsLigne) _BandeauCanneHorsLigne(suivi: suivi),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: CarteBase(
                  controleur: _carte,
                  centre: centreInitial,
                  zoom: position == null ? 12 : 17,
                  couches: couches,
                  libelle: position == null
                      ? 'Carte. Aucune position reçue pour ${canne.nom}.'
                      : 'Carte. Position de ${canne.nom}, reçue ${ilYa(position.horodatage)}.',
                  surDeplacement: (geste) {
                    if (geste && _suivre) setState(() => _suivre = false);
                  },
                ),
              ),
              if (position != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      color: c.surfaceContainerLowest,
                      elevation: 3,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded,
                                size: 18, color: horsLigne ? c.outline : s.nominal),
                            const SizedBox(width: 8),
                            Text('Synchro : ${ilYa(position.horodatage)}',
                                style: context.textes.labelMedium),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                right: 12,
                child: Semantics(
                  button: true,
                  label: 'Recentrer la carte sur la canne',
                  child: Material(
                    color: c.surfaceContainerLowest,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: position == null ? null : () => _recentrer(suivi),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          _suivre ? Icons.my_location_rounded : Icons.location_searching_rounded,
                          color: c.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: c.surfaceContainerLowest,
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.52),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: horsLigne
                  ? _CarteInactive(
                      suivi: suivi,
                      surAppeler: _appeler,
                    )
                  : _CarteSuivi(
                      suivi: suivi,
                      itineraire: itineraire,
                      calculEnCours: _calcul,
                      surItineraire: _choisirDestination,
                      surEffacerItineraire: () => setState(() => _itineraire = null),
                      surAppeler: _appeler,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _Destination { maPosition, domicile, definirDomicile }

// --- Bandeau canne hors ligne -----------------------------------------------------

class _BandeauCanneHorsLigne extends StatelessWidget {
  const _BandeauCanneHorsLigne({required this.suivi});
  final SuiviController suivi;

  @override
  Widget build(BuildContext context) {
    final s = context.statut;
    final p = suivi.position;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: s.avertFond,
        child: Row(
          children: [
            Icon(Icons.signal_wifi_off_rounded, color: s.avertTexte, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canne hors ligne',
                      style: context.textes.titleSmall?.copyWith(color: s.avertTexte)),
                  Text(
                    p == null
                        ? 'Aucune position reçue pour le moment'
                        : 'Dernière position il y a ${_duree(DateTime.now().difference(p.horodatage))}',
                    style: context.textes.bodySmall?.copyWith(color: s.avertTexte),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// « 12 min », « 2 h 10 », « 3 jours » (sans le « il y a »).
  static String _duree(Duration d) =>
      ilYa(DateTime.now().subtract(d)).replaceFirst('il y a ', '');
}

// --- Carte « suivi » (canne en ligne) ---------------------------------------------

class _CarteSuivi extends StatelessWidget {
  const _CarteSuivi({
    required this.suivi,
    required this.itineraire,
    required this.calculEnCours,
    required this.surItineraire,
    required this.surEffacerItineraire,
    required this.surAppeler,
  });

  final SuiviController suivi;
  final Itineraire? itineraire;
  final bool calculEnCours;
  final VoidCallback surItineraire;
  final VoidCallback surEffacerItineraire;
  final Future<void> Function(String numero) surAppeler;

  @override
  Widget build(BuildContext context) {
    final canne = suivi.canne!;
    final p = suivi.position;
    final c = context.couleurs;
    final s = context.statut;
    final batterie = suivi.batterie;
    final faible = batterie != null && batterie < 20;
    final telephone = canne.telephonePersonne;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(canne.nom, style: context.textes.headlineLarge),
                  const SizedBox(height: 6),
                  const Pastille('Actif', type: TypePastille.nominal, point: true),
                ],
              ),
            ),
            if (p != null)
              Semantics(
                label: 'Dernier repère à ${heureSecondes(p.horodatage)}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dernier repère',
                        style: context.textes.labelMedium?.copyWith(color: c.onSurfaceVariant)),
                    Text(
                      heureSecondes(p.horodatage),
                      style: context.textes.titleMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (p != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.navigation_outlined, color: c.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(coordonnees(p.latitude, p.longitude),
                    style: context.textes.bodyMedium),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Indicateur(
                icone: faible ? Icons.battery_alert_rounded : Icons.battery_full_rounded,
                couleurIcone: faible ? s.critique : s.nominal,
                titre: 'Batterie',
                valeur: batterie == null ? '—' : '$batterie %',
                couleurValeur: faible ? s.critiqueTexte : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Indicateur(
                icone: Icons.gps_fixed_rounded,
                couleurIcone: s.nominal,
                titre: 'Précision GPS',
                valeur: libellePrecision(p?.precision),
                detail: p?.precision == null ? null : '(±${p!.precision!.round()} m)',
                couleurValeur: s.nominalTexte,
              ),
            ),
          ],
        ),
        if (itineraire != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_walk_rounded, color: c.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vers ${itineraire!.libelleDestination} : ${distanceLisible(itineraire!.distanceM)}, '
                    '${dureeLisible(itineraire!.duree)} à pied',
                    style: context.textes.bodyMedium?.copyWith(
                        color: c.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Effacer l\'itinéraire',
                  onPressed: surEffacerItineraire,
                  icon: Icon(Icons.close_rounded, color: c.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: (p == null || calculEnCours) ? null : surItineraire,
          icon: calculEnCours
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Icon(Icons.explore_outlined),
          label: const Text('Itinéraire de retour'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PartageScreen()),
                ),
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Partager'),
              ),
            ),
            if (telephone != null && telephone.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => surAppeler(telephone),
                  icon: const Icon(Icons.call_rounded),
                  label: Text('Appeler ${canne.nomCourt}', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Indicateur extends StatelessWidget {
  const _Indicateur({
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.valeur,
    this.detail,
    this.couleurValeur,
  });

  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String valeur;
  final String? detail;
  final Color? couleurValeur;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Semantics(
      label: '$titre : $valeur${detail != null ? ' $detail' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.statut.surfaceDouce,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: couleurIcone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: context.textes.labelMedium?.copyWith(color: c.onSurfaceVariant)),
                  Text(valeur,
                      style: context.textes.titleSmall?.copyWith(
                          color: couleurValeur, fontWeight: FontWeight.w800)),
                  if (detail != null)
                    Text(detail!,
                        style: context.textes.labelMedium?.copyWith(color: c.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Carte « canne inactive » -----------------------------------------------------

class _CarteInactive extends StatelessWidget {
  const _CarteInactive({required this.suivi, required this.surAppeler});

  final SuiviController suivi;
  final Future<void> Function(String numero) surAppeler;

  @override
  Widget build(BuildContext context) {
    final canne = suivi.canne!;
    final p = suivi.position;
    final c = context.couleurs;
    final s = context.statut;
    final batterie = suivi.batterie;
    final faible = batterie != null && batterie < 20;
    final age = suivi.ageDernierePosition;
    final telephone = canne.telephonePersonne;
    final nav = context.read<NavigationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: s.avertFond,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.wifi_off_rounded, color: s.avertTexte, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Signal interrompu', style: context.textes.headlineMedium),
                  ),
                  Text('Absence de position récente',
                      style: context.textes.bodySmall?.copyWith(color: c.onSurfaceVariant)),
                ],
              ),
            ),
            const Pastille('Canne inactive', type: TypePastille.avertissement),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          p == null
              ? 'La canne de ${canne.nomCourt} n\'a encore transmis aucune position.'
              : 'La canne de ${canne.nomCourt} n\'émet plus de signal GPS depuis ${heure(p.horodatage)}.',
          style: context.textes.bodyLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: s.surfaceDouce,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: c.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Que vérifier ?', style: context.textes.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: context.textes.bodyMedium,
                  children: [
                    const TextSpan(
                        text:
                            'Causes probables : passage en zone sans réseau (sous-sol, tunnel) ou batterie déchargée'),
                    if (batterie != null) ...[
                      const TextSpan(text: ' (dernier niveau connu : '),
                      TextSpan(
                        text: '$batterie %',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: faible ? s.critiqueTexte : null,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Indicateur(
                icone: faible ? Icons.battery_alert_rounded : Icons.battery_std_rounded,
                couleurIcone: faible ? s.critique : c.onSurfaceVariant,
                titre: 'Batterie',
                valeur: batterie == null ? '—' : '$batterie %',
                couleurValeur: faible ? s.critiqueTexte : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Indicateur(
                icone: Icons.timer_outlined,
                couleurIcone: c.onSurfaceVariant,
                titre: 'Sans signal',
                valeur: age == null ? '—' : dureeLisible(age),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (telephone != null && telephone.isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: () => surAppeler(telephone),
            icon: const Icon(Icons.call_rounded),
            label: Text('Appeler ${canne.nomCourt} ($telephone)', overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => nav.aller(2),
          icon: const Icon(Icons.route_rounded),
          label: const Text('Voir l\'historique récent'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: suivi.rafraichir,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Actualiser la connexion'),
        ),
      ],
    );
  }
}
