import 'package:flutter/material.dart';

/// App color palette
abstract class AppColors {
  // Primary colors - Blue/Indigo (trust, connection)
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);

  // Secondary colors - Pink/Rose (love, warmth)
  static const secondary = Color(0xFFEC4899);
  static const secondaryLight = Color(0xFFF472B6);
  static const secondaryDark = Color(0xFFDB2777);

  // Accent colors
  static const accent = Color(0xFF8B5CF6);
  static const accentGold = Color(0xFFD4AF37); // Gold for premium features

  // Semantic colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Neutral colors - Light mode
  static const backgroundLight = Color(0xFFF8FAFC);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1E293B);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textTertiaryLight = Color(0xFF94A3B8);
  static const dividerLight = Color(0xFFE2E8F0);

  // Neutral colors - Dark mode
  static const backgroundDark = Color(0xFF0F172A);
  static const surfaceDark = Color(0xFF1E293B);
  static const cardDark = Color(0xFF334155);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);
  static const dividerDark = Color(0xFF334155);

  // Glassmorphism colors
  static const glassLight = Color(0x80FFFFFF);
  static const glassDark = Color(0x40000000);
  static const glassBorderLight = Color(0x40FFFFFF);
  static const glassBorderDark = Color(0x20FFFFFF);

  // Gradient colors
  static const gradientStart = Color(0xFF6366F1);
  static const gradientEnd = Color(0xFFEC4899);

  // Swipe card colors
  static const likeGreen = Color(0xFF22C55E);
  static const passRed = Color(0xFFEF4444);
  static const superLikeBlue = Color(0xFF3B82F6);

  // Special - Shabbat mode
  static const shabbatGold = Color(0xFFD4AF37);
  static const shabbatBackground = Color(0xFF1A1A2E);
  static const candleFlame = Color(0xFFFFB347);

  // Premium gradients
  static const premiumGradient = [
    Color(0xFFD4AF37),
    Color(0xFFF5E6A3),
    Color(0xFFD4AF37),
  ];

  /// Primary gradient for buttons and highlights
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Shimmer gradient for loading states
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFE2E8F0),
      Color(0xFFF8FAFC),
      Color(0xFFE2E8F0),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  /// Dark shimmer gradient
  static const LinearGradient shimmerGradientDark = LinearGradient(
    colors: [
      Color(0xFF334155),
      Color(0xFF475569),
      Color(0xFF334155),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
