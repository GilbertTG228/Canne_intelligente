import 'package:intl/intl.dart';

import '../models/alerte.dart';
import '../models/canne.dart';
import '../models/lien_partage.dart';
import '../models/position_canne.dart';
import '../models/zone.dart';
import '../utils/json.dart';
import 'api_client.dart';
import 'cache_service.dart';

/// Données lues + indication qu'elles viennent du cache (hors ligne).
class Resultat<T> {
  const Resultat(this.donnees, {this.depuisCache = false, this.majCache});
  final T donnees;
  final bool depuisCache;
  final DateTime? majCache;
}

/// Toutes les routes de l'API du serveur, avec repli sur le cache local pour
/// les lectures quand le serveur est injoignable.
class Repository {
  Repository(this._api, this._cache);

  final ApiClient _api;
  final CacheService _cache;

  Future<Resultat<T>> _lire<T>(
    String cle,
    String chemin,
    T Function(dynamic json) analyser, {
    Map<String, String>? query,
  }) async {
    try {
      final json = await _api.get(chemin, query: query);
      final valeur = analyser(json);
      await _cache.ecrire(cle, json);
      return Resultat(valeur);
    } on ApiException catch (e) {
      if (!e.indisponible) rethrow;
      final entree = await _cache.lire(cle);
      if (entree == null) rethrow;
      return Resultat(analyser(entree.json), depuisCache: true, majCache: entree.maj);
    }
  }

  // --- Cannes -------------------------------------------------------------

  /// GET /api/cannes
  Future<Resultat<List<Canne>>> cannes() => _lire('cannes', '/api/cannes', (json) {
        return versListe(json, ['cannes', 'donnees', 'data'])
            .whereType<Map>()
            .map((m) => Canne.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      });

  /// GET /api/cannes/:id/position
  Future<Resultat<PositionCanne?>> position(String canneId) => _lire(
        'position_$canneId',
        '/api/cannes/$canneId/position',
        (json) => PositionCanne.essayer(json is Map && json['position'] is Map ? json['position'] : json),
      );

  /// GET /api/cannes/:id/historique?du=AAAA-MM-JJ&au=AAAA-MM-JJ
  Future<Resultat<List<PositionCanne>>> historique(
      String canneId, DateTime du, DateTime au) {
    final f = DateFormat('yyyy-MM-dd');
    final duTexte = f.format(du);
    final auTexte = f.format(au);
    return _lire(
      'historique_${canneId}_${duTexte}_$auTexte',
      '/api/cannes/$canneId/historique',
      (json) {
        final liste = versListe(json, ['positions', 'historique', 'donnees', 'data'])
            .map(PositionCanne.essayer)
            .whereType<PositionCanne>()
            .toList()
          ..sort((a, b) => a.horodatage.compareTo(b.horodatage));
        return liste;
      },
      query: {'du': duTexte, 'au': auTexte},
    );
  }

  /// POST /api/cannes/:id/sos (test)
  Future<void> declencherSos(String canneId) async {
    await _api.post('/api/cannes/$canneId/sos');
  }

  // --- Consentement ---------------------------------------------------------

  /// POST /api/consentements {cannesId}
  Future<void> enregistrerConsentement(String canneId) async {
    await _api.post('/api/consentements', corps: {'cannesId': canneId});
  }

  // --- Zones ------------------------------------------------------------------

  /// GET /api/cannes/:id/zones
  Future<Resultat<List<Zone>>> zones(String canneId) =>
      _lire('zones_$canneId', '/api/cannes/$canneId/zones', (json) {
        return versListe(json, ['zones', 'donnees', 'data'])
            .map(Zone.essayer)
            .whereType<Zone>()
            .toList();
      });

  /// POST /api/cannes/:id/zones
  Future<void> creerZone(String canneId, Zone zone) async {
    await _api.post('/api/cannes/$canneId/zones', corps: zone.toApi());
  }

  /// PUT /api/cannes/:id/zones/:zoneId
  Future<void> modifierZone(String canneId, Zone zone) async {
    await _api.put('/api/cannes/$canneId/zones/${zone.id}', corps: zone.toApi());
  }

  /// DELETE /api/cannes/:id/zones/:zoneId
  Future<void> supprimerZone(String canneId, String zoneId) async {
    await _api.delete('/api/cannes/$canneId/zones/$zoneId');
  }

  // --- Alertes ------------------------------------------------------------------

  /// GET /api/cannes/:id/alertes
  Future<Resultat<List<Alerte>>> alertes(String canneId) =>
      _lire('alertes_$canneId', '/api/cannes/$canneId/alertes', (json) {
        return versListe(json, ['alertes', 'donnees', 'data'])
            .whereType<Map>()
            .map((m) {
              final map = Map<String, dynamic>.from(m);
              map.putIfAbsent('cannesId', () => canneId);
              return Alerte.fromJson(map);
            })
            .toList()
          ..sort((a, b) => b.horodatage.compareTo(a.horodatage));
      });

  /// PUT /api/alertes/:id/traitee
  Future<void> marquerTraitee(String alerteId) async {
    await _api.put('/api/alertes/$alerteId/traitee');
  }

  // --- Partage ------------------------------------------------------------------

  /// POST /api/liens-partage {cannesId, dureeHeures} -> {lien}
  Future<String> creerLienPartage(String canneId, int dureeHeures) async {
    final reponse = await _api.post('/api/liens-partage',
        corps: {'cannesId': canneId, 'dureeHeures': dureeHeures});
    final lien = reponse is Map ? (reponse['lien'] ?? reponse['url']) : null;
    if (lien is! String || lien.isEmpty) {
      throw ApiException('Le serveur n\'a pas renvoyé de lien.');
    }
    return lien;
  }

  /// GET /api/liens-partage
  Future<List<LienPartage>> liensPartage() async {
    final json = await _api.get('/api/liens-partage');
    return versListe(json, ['liens', 'liensPartage', 'donnees', 'data'])
        .whereType<Map>()
        .map((m) => LienPartage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// DELETE /api/liens-partage/:id
  Future<void> revoquerLien(String id) async {
    await _api.delete('/api/liens-partage/$id');
  }

  // --- Utilisateur ----------------------------------------------------------------

  /// PUT /api/utilisateur/parametres
  /// Hypothèse sur le corps : {delaiInactiviteMinutes, notificationsActives,
  /// fcmToken?}. Le jeton FCM est envoyé par ce même appel.
  Future<void> enregistrerParametres({
    required int delaiInactiviteMinutes,
    required bool notificationsActives,
    String? jetonPush,
  }) async {
    await _api.put('/api/utilisateur/parametres', corps: {
      'delaiInactiviteMinutes': delaiInactiviteMinutes,
      'notificationsActives': notificationsActives,
      if (jetonPush != null) 'fcmToken': jetonPush,
    });
  }
}
