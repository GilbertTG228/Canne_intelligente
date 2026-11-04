import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Erreur renvoyée par le serveur ou par le réseau, avec un message
/// directement affichable à l'utilisateur.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.reseau = false});

  final String message;
  final int? statusCode;

  /// true si le serveur n'a pas pu être joint (pas de réseau, délai dépassé).
  final bool reseau;

  /// Le serveur est inaccessible ou en panne : on peut se rabattre sur le cache.
  bool get indisponible => reseau || (statusCode != null && statusCode! >= 500);

  @override
  String toString() => message;
}

/// Client HTTP JSON : ajoute le jeton, gère les délais et les erreurs.
/// Une réponse 401 sur une requête authentifiée appelle [surNonAutorise]
/// (retour à l'écran de connexion).
class ApiClient {
  ApiClient({required this.lireJeton, http.Client? client})
      : _client = client ?? http.Client();

  final Future<String?> Function() lireJeton;
  final http.Client _client;
  void Function()? surNonAutorise;

  Future<dynamic> get(String chemin, {Map<String, String>? query}) =>
      _envoyer('GET', chemin, query: query);

  Future<dynamic> post(String chemin, {Object? corps, bool authentifie = true}) =>
      _envoyer('POST', chemin, corps: corps, authentifie: authentifie);

  Future<dynamic> put(String chemin, {Object? corps}) =>
      _envoyer('PUT', chemin, corps: corps);

  Future<dynamic> delete(String chemin) => _envoyer('DELETE', chemin);

  Future<dynamic> _envoyer(
    String methode,
    String chemin, {
    Map<String, String>? query,
    Object? corps,
    bool authentifie = true,
  }) async {
    var uri = Uri.parse('${AppConfig.apiBaseUrl}$chemin');
    if (query != null && query.isNotEmpty) uri = uri.replace(queryParameters: query);

    final requete = http.Request(methode, uri)
      ..headers['Accept'] = 'application/json';
    if (corps != null) {
      requete.headers['Content-Type'] = 'application/json; charset=utf-8';
      requete.body = jsonEncode(corps);
    }
    if (authentifie) {
      final jeton = await lireJeton();
      if (jeton != null) requete.headers['Authorization'] = 'Bearer $jeton';
    }

    late http.Response reponse;
    try {
      final flux = await _client.send(requete).timeout(AppConfig.delaiRequete);
      reponse = await http.Response.fromStream(flux).timeout(AppConfig.delaiRequete);
    } on TimeoutException {
      throw ApiException('Le serveur met trop de temps à répondre.', reseau: true);
    } on SocketException {
      throw ApiException('Serveur injoignable. Vérifiez votre connexion.', reseau: true);
    } on HandshakeException {
      throw ApiException('Connexion sécurisée impossible avec le serveur.', reseau: true);
    } on http.ClientException {
      throw ApiException('Serveur injoignable. Vérifiez votre connexion.', reseau: true);
    }
    return _traiter(reponse, authentifie);
  }

  dynamic _traiter(http.Response reponse, bool authentifie) {
    final code = reponse.statusCode;
    dynamic donnees;
    if (reponse.bodyBytes.isNotEmpty) {
      try {
        donnees = jsonDecode(utf8.decode(reponse.bodyBytes));
      } on FormatException {
        if (code >= 200 && code < 300) {
          throw ApiException('Réponse du serveur illisible.', statusCode: code);
        }
      }
    }
    if (code >= 200 && code < 300) return donnees;

    if (code == 401 && authentifie) {
      surNonAutorise?.call();
      throw ApiException('Session expirée. Reconnectez-vous.', statusCode: 401);
    }
    throw ApiException(_messageErreur(donnees, code), statusCode: code);
  }

  String _messageErreur(dynamic donnees, int code) {
    if (donnees is Map) {
      final m = donnees['message'] ?? donnees['erreur'] ?? donnees['error'];
      if (m is String && m.isNotEmpty) return m;
    }
    switch (code) {
      case 400:
        return 'Requête invalide.';
      case 401:
        return 'Numéro ou mot de passe incorrect.';
      case 403:
        return 'Accès refusé.';
      case 404:
        return 'Élément introuvable.';
      default:
        return code >= 500
            ? 'Le serveur rencontre un problème (code $code).'
            : 'Erreur inattendue (code $code).';
    }
  }
}
