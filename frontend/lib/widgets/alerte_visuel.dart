import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/alerte.dart';

/// Icône, couleurs et libellés associés à chaque type d'alerte.
IconData iconeAlerte(TypeAlerte t) {
  switch (t) {
    case TypeAlerte.sos:
      return Icons.sos_rounded;
    case TypeAlerte.entreeZone:
      return Icons.wrong_location_outlined;
    case TypeAlerte.chute:
      return Icons.personal_injury_outlined;
    case TypeAlerte.batterieFaible:
      return Icons.battery_alert_outlined;
    case TypeAlerte.canneInactive:
      return Icons.signal_wifi_off_outlined;
    case TypeAlerte.inconnu:
      return Icons.notifications_active_outlined;
  }
}

String titreAlerte(Alerte a) {
  switch (a.type) {
    case TypeAlerte.sos:
      return 'Alerte SOS';
    case TypeAlerte.entreeZone:
      return 'Entrée dans une zone à éviter';
    case TypeAlerte.chute:
      return 'Chute détectée';
    case TypeAlerte.batterieFaible:
      return 'Batterie faible';
    case TypeAlerte.canneInactive:
      return 'Canne inactive';
    case TypeAlerte.inconnu:
      return a.message ?? 'Alerte';
  }
}

/// Rouge pour les urgences vitales (SOS, chute), orange pour le reste.
Color couleurAlerte(BuildContext context, Alerte a) =>
    a.critique ? context.statut.critique : context.statut.avert;

Color fondAlerte(BuildContext context, Alerte a) =>
    a.critique ? context.statut.critiqueFond : context.statut.avertFond;

Color texteAlerte(BuildContext context, Alerte a) =>
    a.critique ? context.statut.critiqueTexte : context.statut.avertTexte;
