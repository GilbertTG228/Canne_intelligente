import '../utils/json.dart';

/// Lien de suivi temporaire envoyé à un autre proche (sans compte).
class LienPartage {
  const LienPartage({
    required this.id,
    required this.lien,
    this.canneId,
    this.expireLe,
  });

  final String id;
  final String lien;
  final String? canneId;
  final DateTime? expireLe;

  bool get expire => expireLe != null && expireLe!.isBefore(DateTime.now());

  factory LienPartage.fromJson(Map<String, dynamic> json) => LienPartage(
        id: (json['id'] ?? '').toString(),
        lien: (json['lien'] ?? json['url'] ?? '').toString(),
        canneId: (json['cannesId'] ?? json['canneId'])?.toString(),
        expireLe: versDate(json['expireLe'] ?? json['expiration'] ?? json['expire_le']),
      );
}
