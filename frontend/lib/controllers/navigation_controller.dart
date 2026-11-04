import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Onglet actif de la barre du bas, et demande de centrage de la carte
/// (par ex. « Voir sur la carte » depuis une alerte).
class NavigationController extends ChangeNotifier {
  int _onglet = 0;
  LatLng? _focus;

  int get onglet => _onglet;
  LatLng? get focus => _focus;

  void aller(int onglet, {LatLng? focus}) {
    _onglet = onglet;
    _focus = focus;
    notifyListeners();
  }

  /// L'écran d'accueil appelle ceci après avoir centré la carte.
  void focusTraite() {
    _focus = null;
  }

  void reinitialiser() {
    _onglet = 0;
    _focus = null;
    notifyListeners();
  }
}
