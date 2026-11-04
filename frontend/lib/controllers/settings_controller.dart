import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Préférences locales du proche (thème, délais, sons, domicile, profil,
/// consentements déjà donnés).
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsController> charger() async =>
      SettingsController(await SharedPreferences.getInstance());

  // Thème : 0 = automatique, 1 = clair, 2 = sombre (ordre de ThemeMode).
  ThemeMode get themeMode {
    final i = _prefs.getInt('theme') ?? 0;
    return ThemeMode.values[i.clamp(0, 2)];
  }

  int get delaiInactiviteMin =>
      _prefs.getInt('delai_inactivite') ?? AppConfig.delaiInactiviteParDefautMin;
  bool get sons => _prefs.getBool('sons') ?? true;
  bool get vibrations => _prefs.getBool('vibrations') ?? true;
  bool get notificationsActives => _prefs.getBool('notifications') ?? true;

  String? get telephone => _prefs.getString('telephone');
  String get nomAffiche => _prefs.getString('nom_affiche') ?? '';
  String? get canneSelectionnee => _prefs.getString('canne_selectionnee');

  LatLng? get domicile {
    final lat = _prefs.getDouble('domicile_lat');
    final lon = _prefs.getDouble('domicile_lon');
    return (lat != null && lon != null) ? LatLng(lat, lon) : null;
  }

  bool aConsenti(String canneId) =>
      (_prefs.getStringList('consentements') ?? const <String>[]).contains(canneId);

  Future<void> definirTheme(ThemeMode mode) async {
    await _prefs.setInt('theme', mode.index);
    notifyListeners();
  }

  Future<void> definirDelaiInactivite(int minutes) async {
    await _prefs.setInt('delai_inactivite', minutes);
    notifyListeners();
  }

  Future<void> definirSons(bool v) async {
    await _prefs.setBool('sons', v);
    notifyListeners();
  }

  Future<void> definirVibrations(bool v) async {
    await _prefs.setBool('vibrations', v);
    notifyListeners();
  }

  Future<void> definirNotifications(bool v) async {
    await _prefs.setBool('notifications', v);
    notifyListeners();
  }

  Future<void> definirTelephone(String? v) async {
    if (v == null) {
      await _prefs.remove('telephone');
    } else {
      await _prefs.setString('telephone', v);
    }
    notifyListeners();
  }

  Future<void> definirNomAffiche(String v) async {
    await _prefs.setString('nom_affiche', v.trim());
    notifyListeners();
  }

  Future<void> definirCanneSelectionnee(String? id) async {
    if (id == null) {
      await _prefs.remove('canne_selectionnee');
    } else {
      await _prefs.setString('canne_selectionnee', id);
    }
  }

  Future<void> definirDomicile(LatLng? p) async {
    if (p == null) {
      await _prefs.remove('domicile_lat');
      await _prefs.remove('domicile_lon');
    } else {
      await _prefs.setDouble('domicile_lat', p.latitude);
      await _prefs.setDouble('domicile_lon', p.longitude);
    }
    notifyListeners();
  }

  Future<void> marquerConsenti(String canneId) async {
    final liste = {...(_prefs.getStringList('consentements') ?? const <String>[]), canneId};
    await _prefs.setStringList('consentements', liste.toList());
    notifyListeners();
  }

  /// À la déconnexion : on garde le thème et les sons, on efface le reste
  /// qui est lié au compte.
  Future<void> reinitialiserCompte() async {
    for (final cle in [
      'telephone',
      'nom_affiche',
      'canne_selectionnee',
      'domicile_lat',
      'domicile_lon',
      'consentements',
    ]) {
      await _prefs.remove(cle);
    }
    notifyListeners();
  }
}
