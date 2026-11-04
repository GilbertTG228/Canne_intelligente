import '../utils/json.dart';
import 'position_canne.dart';

/// Une canne suivie par le proche.
class Canne {
  const Canne({
    required this.id,
    required this.identifiant,
    required this.nom,
    required this.enLigne,
    this.batterie,
    this.dernierePosition,
    this.telephonePersonne,
    this.consentement = false,
  });

  final String id;
  final String identifiant;
  final String nom;
  final bool enLigne;
  final int? batterie;
  final PositionCanne? dernierePosition;

  /// Numéro de la personne qui utilise la canne (pour le bouton « Appeler »).
  /// Hypothèse : fourni par l'API sous `telephonePersonne`.
  final String? telephonePersonne;

  /// Hypothèse : l'API peut indiquer si le consentement a déjà été enregistré.
  final bool consentement;

  /// Prénom ou nom court pour les phrases (« La canne de Michel… »).
  String get nomCourt => nom.split(RegExp(r'[\s\-–]+')).firstWhere(
        (m) => m.isNotEmpty,
        orElse: () => nom,
      );

  factory Canne.fromJson(Map<String, dynamic> json) {
    final position = PositionCanne.essayer(json['dernierePosition']);
    final id = json['id'].toString();
    return Canne(
      id: id,
      identifiant: (json['identifiant'] ?? id).toString(),
      nom: (json['nom'] ?? json['identifiant'] ?? 'Canne $id').toString(),
      enLigne: versBool(json['enLigne']),
      batterie: versInt(json['batterie']) ?? position?.batterie,
      dernierePosition: position,
      telephonePersonne: json['telephonePersonne']?.toString(),
      consentement: versBool(json['consentement']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifiant': identifiant,
        'nom': nom,
        'enLigne': enLigne,
        'batterie': batterie,
        'dernierePosition': dernierePosition?.toJson(),
        'telephonePersonne': telephonePersonne,
        'consentement': consentement,
      };
}
