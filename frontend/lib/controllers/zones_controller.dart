import 'package:flutter/foundation.dart';

import '../models/zone.dart';
import '../services/api_client.dart';
import '../services/repository.dart';

/// Zones à éviter de la canne sélectionnée.
class ZonesController extends ChangeNotifier {
  ZonesController(this._repo);

  final Repository _repo;

  List<Zone> _zones = [];
  String? _canneId;
  bool _chargement = false;
  String? _erreur;
  bool _depuisCache = false;
  int _generation = 0;

  List<Zone> get zones => _zones;
  bool get chargement => _chargement;
  String? get erreur => _erreur;
  bool get depuisCache => _depuisCache;
  int get nombreActives => _zones.where((z) => z.actif).length;

  void synchroniser(String? canneId) {
    if (canneId == _canneId) return;
    _canneId = canneId;
    _zones = [];
    _erreur = null;
    _depuisCache = false;
    _generation++;
    notifyListeners();
    if (canneId != null) charger();
  }

  Future<void> charger() async {
    final id = _canneId;
    if (id == null) return;
    final generation = _generation;
    _chargement = _zones.isEmpty;
    notifyListeners();
    try {
      final r = await _repo.zones(id);
      if (generation != _generation) return;
      _zones = r.donnees;
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

  // Les écritures exigent le réseau : en cas d'échec, ApiException est relancée
  // et l'écran affiche le message.

  Future<void> creer(Zone zone) async {
    final id = _exigerCanne();
    await _repo.creerZone(id, zone);
    await charger();
  }

  Future<void> modifier(Zone zone) async {
    final id = _exigerCanne();
    await _repo.modifierZone(id, zone);
    await charger();
  }

  Future<void> supprimer(Zone zone) async {
    final id = _exigerCanne();
    await _repo.supprimerZone(id, zone.id);
    _zones = _zones.where((z) => z.id != zone.id).toList();
    notifyListeners();
  }

  /// Active ou désactive une zone (mise à jour immédiate, annulée si le
  /// serveur refuse).
  Future<void> basculer(Zone zone, bool actif) async {
    final id = _exigerCanne();
    final avant = _zones;
    _zones = [for (final z in _zones) z.id == zone.id ? z.copyWith(actif: actif) : z];
    notifyListeners();
    try {
      await _repo.modifierZone(id, zone.copyWith(actif: actif));
    } catch (_) {
      _zones = avant;
      notifyListeners();
      rethrow;
    }
  }

  String _exigerCanne() {
    final id = _canneId;
    if (id == null) throw ApiException('Aucune canne sélectionnée.');
    return id;
  }

  void reinitialiser() {
    _zones = [];
    _canneId = null;
    _erreur = null;
    _generation++;
    notifyListeners();
  }
}
