import 'package:intl/intl.dart';

/// Formats français : durées relatives, dates, distances.

String ilYa(DateTime t, {DateTime? maintenant}) {
  final d = (maintenant ?? DateTime.now()).difference(t);
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  if (s < 60) return 'il y a $s sec';
  if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
  if (d.inHours < 24) {
    final reste = d.inMinutes % 60;
    return reste == 0 ? 'il y a ${d.inHours} h' : 'il y a ${d.inHours} h $reste';
  }
  final j = d.inDays;
  return 'il y a $j ${j > 1 ? 'jours' : 'jour'}';
}

String distanceLisible(double metres) {
  if (metres < 1000) return '${metres.round()} m';
  return '${(metres / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

String dureeLisible(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds} s';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final m = d.inMinutes % 60;
  return '${d.inHours}h${m.toString().padLeft(2, '0')}';
}

String heure(DateTime t) => DateFormat('HH:mm').format(t);
String heureSecondes(DateTime t) => DateFormat('HH:mm:ss').format(t);

String capitaliser(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String dateLongue(DateTime t) => capitaliser(DateFormat('EEEE d MMMM y', 'fr_FR').format(t));
String moisAnnee(DateTime t) => capitaliser(DateFormat('MMMM y', 'fr_FR').format(t));
String dateCourte(DateTime t) => DateFormat('dd/MM/y', 'fr_FR').format(t);
String dateHeure(DateTime t) => DateFormat("d MMM y 'à' HH:mm", 'fr_FR').format(t);

String coordonnees(double lat, double lon) =>
    '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

String libellePrecision(double? metres) {
  if (metres == null) return 'Inconnue';
  if (metres <= 10) return 'Excellente';
  if (metres <= 30) return 'Bonne';
  return 'Moyenne';
}

bool memeJour(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
