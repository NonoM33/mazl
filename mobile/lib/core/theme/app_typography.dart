import 'package:flutter/material.dart';

/// Échelle typographique : Geist pour tout, Geist Mono pour les petites
/// étiquettes en capitales. Les titres sont grands et serrés.
abstract class AppTypography {
  static const family = 'Geist';
  static const monoFamily = 'GeistMono';

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  /// Étiquette de section : « À PROPOS », « NOUVEAUX · 3 ».
  static TextStyle eyebrow(Color color) => TextStyle(
        fontFamily: monoFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.3,
        height: 1.3,
        color: color,
      );

  /// Le mot-symbole « mazl. » à la taille voulue.
  static TextStyle wordmark(double size, Color color) => TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -size * 0.055,
        height: 0.95,
        color: color,
      );

  static TextTheme textTheme(Color text, Color muted) => TextTheme(
        displayLarge: _s(64, FontWeight.w700, -3.5, text, 0.95),
        displayMedium: _s(48, FontWeight.w700, -2.4, text, 1),
        displaySmall: _s(40, FontWeight.w700, -2, text, 1.05),
        headlineLarge: _s(34, FontWeight.w600, -1.3, text, 1.1),
        headlineMedium: _s(28, FontWeight.w600, -1, text, 1.15),
        headlineSmall: _s(22, FontWeight.w600, -0.6, text, 1.25),
        titleLarge: _s(19, FontWeight.w600, -0.4, text, 1.3),
        titleMedium: _s(16, FontWeight.w600, -0.2, text, 1.35),
        titleSmall: _s(14, FontWeight.w600, -0.1, text, 1.35),
        bodyLarge: _s(16, FontWeight.w400, -0.1, text, 1.5),
        bodyMedium: _s(15, FontWeight.w400, -0.1, text, 1.45),
        bodySmall: _s(13, FontWeight.w400, 0, muted, 1.4),
        labelLarge: _s(14, FontWeight.w500, -0.1, text, 1.3),
        labelMedium: _s(12, FontWeight.w500, 0, muted, 1.3),
        labelSmall: _s(11, FontWeight.w500, 0.2, muted, 1.3),
      );

  static TextStyle _s(
    double size,
    FontWeight weight,
    double spacing,
    Color color,
    double height,
  ) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color,
      );
}
