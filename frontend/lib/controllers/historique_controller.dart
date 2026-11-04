import 'package:flutter/foundation.dart';

import '../models/position_canne.dart';
import '../models/trajet.dart';
import '../services/api_client.dart';
import '../services/repository.dart';
import '../utils/geo.dart';

enum Periode { jour, mois, annee }

/// Historique des déplacements : filtre par jour, mois ou année.
class HistoriqueController extends ChangeNotifier {
  HistoriqueController(this._repo) : _date = _aujourdhui();

  final Repository _repo;

  static DateTime _aujourdhui() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Periode _periode = Periode.jour;
  DateTime _date;
  String? _canneId;
  List<PositionCanne> _positions = [];
  List<Trajet> _trajets = [];
  int? _trajetSelectionne;
  bool _chargement = false;
  String? _erreur;
  bool _depuisCache = false;
  int _generation = 0;

  /// Augmente à chaque changement qui exige de recadrer la carte.
  int version = 0;

  Periode get periode => _periode;
  DateTime get date => _date;
  List<PositionCanne> get positions => _positions;
  List<Trajet> get trajets => _trajets;
  int? get trajetSelectionne => _trajetSelectionne;
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  bool get depuisCache => _depuisCache;

  double get distanceTotaleM => _trajets.fold(0.0, (s, t) => s + t.distanceM);
  Duration get dureeTotale => _trajets.fold(Duration.zero, (s, t) => s + t.duree);

  /// Premier et dernier jour (inclus) de la période affichée.
  (DateTime, DateTime) get intervalle {
    switch (_periode) {
      case Periode.jour:
        return (_date, _date);
      case Periode.mois:
        return (DateTime(_date.year, _date.month, 1), DateTime(_date.year, _date.month + 1, 0));
      case Periode.annee:
        return (DateTime(_date.year, 1, 1), DateTime(_date.year, 12, 31));
    }
  }

  bool get peutAvancer {
    final (_, fin) = intervalle;
    return fin.isBefore(_aujourdhui());
  }

  void synchroniser(String? canneId) {
    if (canneId == _canneId) return;
    _canneId = canneId;
    _positions = [];
    _trajets = [];
    _trajetSelectionne = null;
    _erreur = null;
    _generation++;
    notifyListeners();
    if (canneId != null) charger();
  }

  void changerPeriode(Periode p) {
    if (p == _periode) return;
    _periode = p;
    charger();
  }

  void definirDate(DateTime d) {
    _date = DateTime(d.year, d.month, d.day);
    charger();
  }

  void precedent() => _deplacer(-1);
  void suivant() {
    if (peutAvancer) _deplacer(1);
  }

  void _deplacer(int pas) {
    switch (_periode) {
      case Periode.jour:
        _date = DateTime(_date.year, _date.month, _date.day + pas);
      case Periode.mois:
        _date = DateTime(_date.year, _date.month + pas, 1);
      case Periode.annee:
        _date = DateTime(_date.year + pas, 1, 1);
    }
    charger();
  }

  void selectionnerTrajet(int? index) {
    _trajetSelectionne = (index == _trajetSelectionne) ? null : index;
    version++;
    notifyListeners();
  }

  Future<void> charger() async {
    final id = _canneId;
    if (id == null) return;
    final generation = ++_generation;
    final (du, au) = intervalle;
    _chargement = true;
    _erreur = null;
    _trajetSelectionne = null;
    notifyListeners();
    try {
      final r = await _repo.historique(id, du, au);
      if (generation != _generation) return;
      _positions = r.donnees;
      _trajets = decouperEnTrajets(_positions);
      _depuisCache = r.depuisCache;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _positions = [];
      _trajets = [];
      _erreur = e.message;
    } finally {
      if (generation == _generation) {
        _chargement = false;
        version++;
        notifyListeners();
      }
    }
  }

  void reinitialiser() {
    _positions = [];
    _trajets = [];
    _canneId = null;
    _erreur = null;
    _periode = Periode.jour;
    _date = _aujourdhui();
    _generation++;
    notifyListeners();
  }
}
