import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

/// Stockage sécurisé du jeton JWT (Keystore Android / Keychain iOS).
class AuthService {
  AuthService(this._api);

  static const _cleJeton = 'jeton_jwt';
  final ApiClient _api;
  final FlutterSecureStorage _stockage = const FlutterSecureStorage();

  Future<String?> lireJeton() async {
    try {
      return await _stockage.read(key: _cleJeton);
    } catch (_) {
      return null; // stockage corrompu : on repart sur une connexion propre
    }
  }

  /// POST /api/auth/connexion {telephone, motDePasse} -> {jeton}
  Future<void> connexion(String telephone, String motDePasse) async {
    final reponse = await _api.post(
      '/api/auth/connexion',
      corps: {'telephone': telephone, 'motDePasse': motDePasse},
      authentifie: false,
    );
    final jeton = reponse is Map ? reponse['jeton'] : null;
    if (jeton is! String || jeton.isEmpty) {
      throw ApiException('Réponse de connexion invalide.');
    }
    await _stockage.write(key: _cleJeton, value: jeton);
  }

  /// POST /api/auth/mot-de-passe-oublie {telephone}
  Future<void> motDePasseOublie(String telephone) async {
    await _api.post('/api/auth/mot-de-passe-oublie',
        corps: {'telephone': telephone}, authentifie: false);
  }

  Future<void> supprimerJeton() async {
    try {
      await _stockage.delete(key: _cleJeton);
    } catch (_) {}
  }
}
