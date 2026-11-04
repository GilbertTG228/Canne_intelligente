import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs sémantiques de statut (nominal / avertissement / critique),
/// issues du système de design « Vigilance & Care ».
@immutable
class CouleursStatut extends ThemeExtension<CouleursStatut> {
  const CouleursStatut({
    required this.nominal,
    required this.nominalFond,
    required this.nominalTexte,
    required this.avert,
    required this.avertFond,
    required this.avertTexte,
    required this.critique,
    required this.critiqueFond,
    required this.critiqueTexte,
    required this.bordure,
    required this.surfaceDouce,
  });

  final Color nominal, nominalFond, nominalTexte;
  final Color avert, avertFond, avertTexte;
  final Color critique, critiqueFond, critiqueTexte;
  final Color bordure, surfaceDouce;

  static const claires = CouleursStatut(
    nominal: Color(0xFF16A34A),
    nominalFond: Color(0xFFDCFCE7),
    nominalTexte: Color(0xFF166534),
    avert: Color(0xFFEA580C),
    avertFond: Color(0xFFFFEDD5),
    avertTexte: Color(0xFF9A3412),
    critique: Color(0xFFDC2626),
    critiqueFond: Color(0xFFFEE2E2),
    critiqueTexte: Color(0xFF991B1B),
    bordure: Color(0xFFE2E8F0),
    surfaceDouce: Color(0xFFEFF4FF),
  );

  static const sombres = CouleursStatut(
    nominal: Color(0xFF4ADE80),
    nominalFond: Color(0xFF12301F),
    nominalTexte: Color(0xFF86EFAC),
    avert: Color(0xFFFB923C),
    avertFond: Color(0xFF3A2314),
    avertTexte: Color(0xFFFDBA74),
    critique: Color(0xFFF87171),
    critiqueFond: Color(0xFF3F1A1A),
    critiqueTexte: Color(0xFFFCA5A5),
    bordure: Color(0xFF25324A),
    surfaceDouce: Color(0xFF16213A),
  );

  @override
  CouleursStatut copyWith({
    Color? nominal,
    Color? nominalFond,
    Color? nominalTexte,
    Color? avert,
    Color? avertFond,
    Color? avertTexte,
    Color? critique,
    Color? critiqueFond,
    Color? critiqueTexte,
    Color? bordure,
    Color? surfaceDouce,
  }) {
    return CouleursStatut(
      nominal: nominal ?? this.nominal,
      nominalFond: nominalFond ?? this.nominalFond,
      nominalTexte: nominalTexte ?? this.nominalTexte,
      avert: avert ?? this.avert,
      avertFond: avertFond ?? this.avertFond,
      avertTexte: avertTexte ?? this.avertTexte,
      critique: critique ?? this.critique,
      critiqueFond: critiqueFond ?? this.critiqueFond,
      critiqueTexte: critiqueTexte ?? this.critiqueTexte,
      bordure: bordure ?? this.bordure,
      surfaceDouce: surfaceDouce ?? this.surfaceDouce,
    );
  }

  @override
  CouleursStatut lerp(ThemeExtension<CouleursStatut>? other, double t) {
    if (other is! CouleursStatut) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CouleursStatut(
      nominal: l(nominal, other.nominal),
      nominalFond: l(nominalFond, other.nominalFond),
      nominalTexte: l(nominalTexte, other.nominalTexte),
      avert: l(avert, other.avert),
      avertFond: l(avertFond, other.avertFond),
      avertTexte: l(avertTexte, other.avertTexte),
      critique: l(critique, other.critique),
      critiqueFond: l(critiqueFond, other.critiqueFond),
      critiqueTexte: l(critiqueTexte, other.critiqueTexte),
      bordure: l(bordure, other.bordure),
      surfaceDouce: l(surfaceDouce, other.surfaceDouce),
    );
  }
}

/// Raccourcis pour accéder au thème depuis n'importe quel widget.
extension ThemeContexte on BuildContext {
  ColorScheme get couleurs => Theme.of(this).colorScheme;
  TextTheme get textes => Theme.of(this).textTheme;
  CouleursStatut get statut => Theme.of(this).extension<CouleursStatut>()!;
}

class AppTheme {
  AppTheme._();

  static const _clair = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1D4ED8),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCE4FF),
    onPrimaryContainer: Color(0xFF0B2A8F),
    secondary: Color(0xFF0F172A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE5EEFF),
    onSecondaryContainer: Color(0xFF0F172A),
    tertiary: Color(0xFF16A34A),
    onTertiary: Colors.white,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFFE2E8F0),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFEAF0FB),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFDCE4F2),
  );

  static const _sombre = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9DB4FF),
    onPrimary: Color(0xFF0A1F6B),
    primaryContainer: Color(0xFF1D4ED8),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFCBD5E1),
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF1E2A44),
    onSecondaryContainer: Color(0xFFE2E8F0),
    tertiary: Color(0xFF4ADE80),
    onTertiary: Color(0xFF053D1B),
    error: Color(0xFFF87171),
    onError: Color(0xFF3F0A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: Color(0xFF0B1220),
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFFA8B4C8),
    outline: Color(0xFF7B88A0),
    outlineVariant: Color(0xFF25324A),
    surfaceContainerLowest: Color(0xFF111A2E),
    surfaceContainerLow: Color(0xFF0F1727),
    surfaceContainer: Color(0xFF16213A),
    surfaceContainerHigh: Color(0xFF1C2944),
    surfaceContainerHighest: Color(0xFF243352),
  );

  static ThemeData claire() => _construire(_clair, CouleursStatut.claires);
  static ThemeData sombre() => _construire(_sombre, CouleursStatut.sombres);

  static TextTheme _textes(ColorScheme c) {
    final base = GoogleFonts.interTextTheme(
      ThemeData(brightness: c.brightness).textTheme,
    ).apply(bodyColor: c.onSurface, displayColor: c.onSurface);
    TextStyle? s(TextStyle? t, double taille, FontWeight poids, double hauteur,
            [double espacement = 0]) =>
        t?.copyWith(
            fontSize: taille,
            fontWeight: poids,
            height: hauteur / taille,
            letterSpacing: espacement);
    return base.copyWith(
      displayLarge: s(base.displayLarge, 36, FontWeight.w800, 44, -0.7),
      displayMedium: s(base.displayMedium, 30, FontWeight.w800, 38, -0.6),
      headlineLarge: s(base.headlineLarge, 26, FontWeight.w700, 34, -0.4),
      headlineMedium: s(base.headlineMedium, 22, FontWeight.w700, 30, -0.2),
      headlineSmall: s(base.headlineSmall, 19, FontWeight.w600, 26),
      titleLarge: s(base.titleLarge, 22, FontWeight.w700, 30, -0.2),
      titleMedium: s(base.titleMedium, 19, FontWeight.w600, 26),
      titleSmall: s(base.titleSmall, 16, FontWeight.w600, 24, 0.1),
      bodyLarge: s(base.bodyLarge, 18, FontWeight.w400, 28),
      bodyMedium: s(base.bodyMedium, 16, FontWeight.w400, 24),
      bodySmall: s(base.bodySmall, 14, FontWeight.w500, 20),
      labelLarge: s(base.labelLarge, 16, FontWeight.w600, 24, 0.2),
      labelMedium: s(base.labelMedium, 14, FontWeight.w600, 20, 0.3),
      labelSmall: s(base.labelSmall, 12, FontWeight.w700, 16, 0.5),
    );
  }

  static ThemeData _construire(ColorScheme c, CouleursStatut statut) {
    final textes = _textes(c);
    final arrondi12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      scaffoldBackgroundColor: c.surface,
      textTheme: textes,
      extensions: [statut],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surfaceContainerLowest,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textes.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statut.bordure),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: arrondi12,
          textStyle: textes.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: arrondi12,
          side: BorderSide(color: statut.bordure, width: 1.5),
          foregroundColor: c.onSurface,
          textStyle: textes.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: arrondi12,
          textStyle: textes.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: statut.bordure, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: statut.bordure, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.error, width: 2),
        ),
        labelStyle: textes.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceContainerLowest,
        height: 76,
        indicatorColor: c.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((etats) {
          final actif = etats.contains(WidgetState.selected);
          return textes.labelMedium?.copyWith(
            fontWeight: actif ? FontWeight.w800 : FontWeight.w600,
            color: actif ? c.primary : c.onSurfaceVariant,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: textes.labelMedium,
        side: BorderSide(color: statut.bordure),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: arrondi12,
        contentTextStyle: textes.bodyMedium?.copyWith(color: c.onInverseSurfaceSafe),
      ),
      dividerTheme: DividerThemeData(color: statut.bordure, space: 1),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}

extension on ColorScheme {
  /// Couleur de texte lisible sur le fond des SnackBar (inverse de la surface).
  Color get onInverseSurfaceSafe => onInverseSurface;
}
