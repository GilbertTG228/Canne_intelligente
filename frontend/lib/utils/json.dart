/// Conversions tolérantes : PostgreSQL/Node renvoient parfois les nombres
/// décimaux sous forme de chaînes ("6.1319") et les dates en ISO 8601.

double? versDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}

int? versInt(dynamic v) {
  final d = versDouble(v);
  return d?.round();
}

bool versBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  return s == 'true' || s == 't' || s == '1' || s == 'oui';
}

/// Accepte une chaîne ISO 8601 ou un horodatage Unix (secondes ou millisecondes).
/// Le résultat est toujours en heure locale.
DateTime? versDate(dynamic v) {
  if (v == null) return null;
  if (v is num) {
    final ms = v > 100000000000 ? v.toInt() : (v * 1000).toInt();
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  final texte = v.toString();
  final asNum = num.tryParse(texte);
  if (asNum != null) return versDate(asNum);
  return DateTime.tryParse(texte)?.toLocal();
}

Map<String, dynamic> versMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

/// Extrait une liste d'une réponse qui peut être soit une liste directe,
/// soit un objet contenant la liste sous l'une des clés données.
List<dynamic> versListe(dynamic json, [List<String> cles = const []]) {
  if (json is List) return json;
  if (json is Map) {
    for (final cle in cles) {
      final valeur = json[cle];
      if (valeur is List) return valeur;
    }
  }
  return const [];
}
