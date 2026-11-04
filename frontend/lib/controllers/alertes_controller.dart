import 'package:flutter/foundation.dart';

import '../models/alerte.dart';
import '../services/api_client.dart';
import '../services/repository.dart';

/// Journal d'alertes de la canne sélectionnée.
class AlertesController extends ChangeNotifier {
  AlertesController(this._repo);

  final Repository _repo;

  List<Alerte> _alertes = [];
  String? _canneId;
  bool _chargement = false;
  String? _erreur;
  bool _depuisCache = false;
  int _generation = 0;

  List<Alerte> get alertes => _alertes;
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  bool get depuisCache => _depuisCache;
  int get nonTraitees => _alertes.where((a) => !a.traitee).length;

  /// Appelé par les écrans quand la canne sélectionnée change (sans effet si
  /// c'est déjà la bonne).
  void synchroniser(String? canneId) {
    if (canneId == _canneId) return;
    _canneId = canneId;
    _alertes = [];
    _erreur = null;
    _depuisCache = false;
    _generation++;
    notifyListeners();
    if (canneId != null) recharger();
  }

  Future<void> recharger() async {
    final id = _canneId;
    if (id == null) return;
    final generation = _generation;
    _chargement = _alertes.isEmpty;
    notifyListeners();
    try {
      final r = await _repo.alertes(id);
      if (generation != _generation) return;
      _alertes = r.donnees;
      _depuisCache = r.depuisCache;
      _erreur = null;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _erreur = e.message;
    } finally {
      if (generation == _generation) {
        _chargement = false;
        notifyListeners();
      }
    }
  }

  /// PUT /api/alertes/:id/traitee. Lève ApiException en cas d'échec.
  Future<void> marquerTraitee(String alerteId) async {
    await _repo.marquerTraitee(alerteId);
    _alertes = [
      for (final a in _alertes) a.id == alerteId ? a.copyWith(traitee: true) : a,
    ];
    notifyListeners();
  }

  void reinitialiser() {
    _alertes = [];
    _canneId = null;
    _erreur = null;
    _generation++;
    notifyListeners();
  }
}
