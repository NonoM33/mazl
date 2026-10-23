import 'package:flutter/material.dart';

/// Palette « Encre & Tekhelet » : un fond blanc, une encre presque noire et
/// un seul accent, le bleu tekhelet. Les anciens noms (secondary, accentGold,
/// gradients...) restent pour les écrans existants mais pointent tous vers
/// cette palette : il n'y a plus qu'un accent dans l'application.
abstract class AppColors {
  // Fondamentaux
  static const ink = Color(0xFF0B0B0F);
  static const paper = Color(0xFFFFFFFF);
  static const tekhelet = Color(0xFF2747F5);
  static const tekheletLight = Color(0xFF5B78FF);
  static const tekheletDark = Color(0xFF1A35C9);

  /// Fond des puces, champs et cartes en mode clair.
  static const mist = Color(0xFFF3F3F5);

  /// Contour des boutons secondaires et des champs.
  static const hairline = Color(0xFFE2E2E6);

  /// Texte secondaire : 5,3:1 sur blanc.
  static const muted = Color(0xFF6B6B76);

  /// Icônes inactives sur l'encre (barre de navigation) : 6:1 sur [ink].
  static const iconOnInk = Color(0xFF9A9AA5);

  /// Teintes neutres des emplacements photo, sans dégradé.
  static const photoTints = [
    Color(0xFFE7E4DF),
    Color(0xFFE1E5EA),
    Color(0xFFE8E2E5),
    Color(0xFFE1E8E4),
    Color(0xFFE3E1EA),
  ];

  // Noms historiques, remappés sur la palette
  static const primary = tekhelet;
  static const primaryLight = tekheletLight;
  static const primaryDark = tekheletDark;

  static const secondary = tekhelet;
  static const secondaryLight = tekheletLight;
  static const secondaryDark = tekheletDark;

  static const accent = tekhelet;
  static const accentGold = tekhelet;

  // Sémantique
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFD92D20);
  static const info = tekhelet;

  // Neutres — clair
  static const backgroundLight = paper;
  static const surfaceLight = paper;
  static const cardLight = mist;
  static const textPrimaryLight = ink;
  static const textSecondaryLight = muted;
  static const textTertiaryLight = Color(0xFF8A8A94);
  static const dividerLight = Color(0xFFEDEDF0);

  // Neutres — sombre
  static const backgroundDark = ink;
  static const surfaceDark = Color(0xFF141418);
  static const cardDark = Color(0xFF1C1C22);
  static const textPrimaryDark = Color(0xFFF4F4F5);
  static const textSecondaryDark = Color(0xFFA1A1AA);
  static const textTertiaryDark = Color(0xFF71717A);
  static const dividerDark = Color(0xFF26262C);

  // Verre : neutres, sans teinte
  static const glassLight = Color(0xCCFFFFFF);
  static const glassDark = Color(0x660B0B0F);
  static const glassBorderLight = Color(0x14000000);
  static const glassBorderDark = Color(0x1FFFFFFF);

  // Les « dégradés » sont désormais pleins
  static const gradientStart = tekhelet;
  static const gradientEnd = tekhelet;

  // Cartes de découverte
  static const likeGreen = tekhelet;
  static const passRed = muted;
  static const superLikeBlue = tekhelet;

  // Mode Shabbat
  static const shabbatGold = Color(0xFFF2B544);
  static const shabbatBackground = ink;
  static const candleFlame = Color(0xFFF2B544);
  static const shabbatText = Color(0xFFF4F1EA);
  static const shabbatMuted = Color(0xFFB9B6AE);

  static const premiumGradient = [tekhelet, tekhelet, tekhelet];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [mist, Color(0xFFFAFAFB), mist],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const LinearGradient shimmerGradientDark = LinearGradient(
    colors: [cardDark, Color(0xFF26262C), cardDark],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
