import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/canne.dart';
import '../models/position_canne.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/repository.dart';
import '../utils/format.dart';
import 'settings_controller.dart';

/// Cannes suivies, canne sélectionnée, dernière position et états
/// (hors ligne réseau, canne inactive).
class SuiviController extends ChangeNotifier {
  SuiviController(this._repo, this._reglages, this._notifications);

  final Repository _repo;
  final SettingsController _reglages;
  final NotificationService _notifications;

  List<Canne> _cannes = [];
  String? _canneId;
  PositionCanne? _positionDetaillee;
  bool _premierChargementTermine = false;
  bool _enCours = false;
  String? _erreur;
  bool _reseauIndisponible = false;
  DateTime? _majCache;
  String? _cleInactiviteNotifiee;

  // --- Lecture ------------------------------------------------------------------

  List<Canne> get cannes => _cannes;
  String? get canneId => _canneId;
  bool get chargementInitial => !_premierChargementTermine;
  String? get erreur => _erreur;

  /// Le serveur est injoignable : les données affichées viennent du cache.
  bool get reseauIndisponible => _reseauIndisponible;
  DateTime? get majCache => _majCache;

  Canne? get canne {
    for (final c in _cannes) {
      if (c.id == _canneId) return c;
    }
    return null;
  }

  /// La plus récente entre la position détaillée et celle de la liste des cannes.
  PositionCanne? get position {
    final a = _positionDetaillee;
    final b = canne?.dernierePosition;
    if (a == null) return b;
    if (b == null) return a;
    return a.horodatage.isAfter(b.horodatage) ? a : b;
  }

  int? get batterie => position?.batterie ?? canne?.batterie;

  Duration? get ageDernierePosition {
    final p = position;
    return p == null ? null : DateTime.now().difference(p.horodatage);
  }

  /// Aucune position depuis plus que le délai réglé dans les paramètres.
  bool get inactive {
    final age = ageDernierePosition;
    if (age == null) return canne != null; // jamais de position reçue
    return age > Duration(minutes: _reglages.delaiInactiviteMin);
  }

  /// La canne ne transmet pas : le serveur la dit hors ligne ou elle est inactive.
  bool get canneHorsLigne {
    final c = canne;
    if (c == null) return false;
    final serveurDitHorsLigne = !_reseauIndisponible && !c.enLigne;
    return serveurDitHorsLigne || inactive;
  }

  // --- Actions --------------------------------------------------------------------

  Future<void> selectionner(String id) async {
    if (id == _canneId) return;
    _canneId = id;
    _positionDetaillee = null;
    _cleInactiviteNotifiee = null;
    await _reglages.definirCanneSelectionnee(id);
    notifyListeners();
    await rafraichir();
  }

  /// Recharge la liste des cannes et la position de la canne sélectionnée.
  /// Appelé régulièrement ; en cas d'échec réseau, les données en cache restent
  /// affichées.
  Future<void> rafraichir() async {
    if (_enCours) return;
    _enCours = true;
    try {
      final resultat = await _repo.cannes();
      _cannes = resultat.donnees;
      _reseauIndisponible = resultat.depuisCache;
      _majCache = resultat.majCache;
      _erreur = null;
      _choisirCanneParDefaut();

      final id = _canneId;
      if (id != null) {
        try {
          final p = await _repo.position(id);
          if (id == _canneId) {
            _positionDetaillee = p.donnees;
            if (p.depuisCache) {
              _reseauIndisponible = true;
              _majCache = p.majCache ?? _majCache;
            }
          }
        } on ApiException {
          // La position de la liste des cannes sert de repli.
        }
      }
      _verifierInactivite();
    } on ApiException catch (e) {
      _erreur = e.message;
    } catch (_) {
      _erreur = 'Une erreur inattendue est survenue.';
    } finally {
      _enCours = false;
      _premierChargementTermine = true;
      notifyListeners(); // notifie aussi à vide : fait avancer « il y a X min »
    }
  }

  void _choisirCanneParDefaut() {
    if (_cannes.isEmpty) {
      _canneId = null;
      return;
    }
    final existe = _cannes.any((c) => c.id == _canneId);
    if (existe) return;
    final memorisee = _reglages.canneSelectionnee;
    _canneId = _cannes.any((c) => c.id == memorisee) ? memorisee : _cannes.first.id;
    _positionDetaillee = null;
  }

  /// Une seule notification locale par période d'inactivité.
  void _verifierInactivite() {
    final c = canne;
    final p = position;
    if (c == null || p == null || _reseauIndisponible || !inactive) {
      if (!inactive) _cleInactiviteNotifiee = null;
      return;
    }
    if (!AppConfig.notificationLocaleInactivite || !_reglages.notificationsActives) return;
    final cle = '${c.id}|${p.horodatage.millisecondsSinceEpoch}';
    if (cle == _cleInactiviteNotifiee) return;
    _cleInactiviteNotifiee = cle;
    _notifications.afficher(
      'Canne inactive : ${c.nom}',
      'Aucune position reçue ${ilYa(p.horodatage)}. Vérifiez la batterie ou la couverture réseau.',
      {'type': 'canne_inactive', 'canneId': c.id},
    );
  }

  void reinitialiser() {
    _cannes = [];
    _canneId = null;
    _positionDetaillee = null;
    _premierChargementTermine = false;
    _erreur = null;
    _reseauIndisponible = false;
    _majCache = null;
    _cleInactiviteNotifiee = null;
    notifyListeners();
  }
}
