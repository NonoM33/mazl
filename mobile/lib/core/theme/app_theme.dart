import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Thème « Encre & Tekhelet » : un seul constructeur pour le clair et le
/// sombre, pour que les deux ne divergent jamais.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final p = _Palette(brightness);
    final text = AppTypography.textTheme(p.text, p.muted);
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    final buttonText = AppTypography.button;

    return ThemeData(
      // Every back button shows the app's arrow, not the platform chevron,
      // pointing the way the language reads.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => Icon(
          Directionality.of(context) == TextDirection.rtl
              ? LucideIcons.arrowRight
              : LucideIcons.arrowLeft,
        ),
      ),
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.family,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.onAccent,
        primaryContainer: p.fill,
        onPrimaryContainer: p.onFill,
        secondary: p.accent,
        onSecondary: p.onAccent,
        tertiary: p.accent,
        onTertiary: p.onAccent,
        surface: p.background,
        onSurface: p.text,
        onSurfaceVariant: p.muted,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.background,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surface,
        surfaceContainerHighest: p.surface,
        outline: p.hairline,
        outlineVariant: p.divider,
        error: p.error,
        onError: p.isDark ? AppColors.ink : Colors.white,
        inverseSurface: p.text,
        onInverseSurface: p.background,
        shadow: Colors.black,
      ),
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.divider,
      splashFactory: NoSplash.splashFactory,
      highlightColor: p.text.withValues(alpha: 0.04),
      textTheme: text,
      iconTheme: IconThemeData(color: p.text, size: 22),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        centerTitle: false,
        titleSpacing: 24,
        systemOverlayStyle: p.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.text,
          foregroundColor: p.background,
          disabledBackgroundColor: p.surface,
          disabledForegroundColor: p.muted,
          minimumSize: const Size(64, 56),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.fill,
          foregroundColor: p.onFill,
          minimumSize: const Size(64, 56),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(64, 56),
          side: BorderSide(color: p.hairline),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(44, 44),
          textStyle: buttonText.copyWith(fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.text,
        foregroundColor: p.background,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(p.text),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error),
        hintStyle: text.bodyLarge?.copyWith(color: p.muted),
        labelStyle: text.bodyMedium?.copyWith(color: p.muted),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.text,
        secondarySelectedColor: p.text,
        disabledColor: p.surface,
        side: BorderSide.none,
        showCheckmark: false,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: p.background),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        // The only drag handle of the app (design system: 36x5, hairline).
        // Sheets never draw their own: see showMazlSheet.
        showDragHandle: true,
        dragHandleColor: p.hairline,
        dragHandleSize: const Size(36, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        iconColor: p.text,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.hairline,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.text : Colors.transparent,
        ),
        side: BorderSide(color: p.hairline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.text,
        inactiveTrackColor: p.hairline,
        thumbColor: p.text,
        overlayColor: p.text.withValues(alpha: 0.06),
        trackHeight: 2,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surface,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.text,
        unselectedLabelColor: p.muted,
        indicatorColor: p.text,
        dividerColor: p.divider,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.background,
        selectedItemColor: p.text,
        unselectedItemColor: p.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: color == Colors.transparent
        ? BorderSide.none
        : BorderSide(color: color, width: 1.5),
  );
}

class _Palette {
  _Palette(Brightness brightness) : isDark = brightness == Brightness.dark;

  final bool isDark;

  Color get background => isDark ? AppColors.backgroundDark : AppColors.paper;
  Color get surface => isDark ? AppColors.cardDark : AppColors.mist;
  Color get text => isDark ? AppColors.textPrimaryDark : AppColors.ink;
  Color get muted => isDark ? AppColors.textSecondaryDark : AppColors.muted;
  Color get hairline => isDark ? AppColors.dividerDark : AppColors.hairline;
  Color get divider => isDark ? AppColors.dividerDark : AppColors.dividerLight;
  Color get accent => isDark ? AppColors.tekheletLight : AppColors.tekhelet;

  /// Texte sur l'accent : le blanc sur le tekhelet clair du thème sombre
  /// n'atteint que 3,8:1, l'encre y passe à 5,2:1.
  /// Aplat portant du texte ou une icône (bouton plein, bulle envoyée) :
  /// le tekhelet de marque dans les deux thèmes, blanc dessus (6,35:1). La
  /// variante claire de l'accent n'y donne que 3,77:1 avec du blanc et
  /// l'encre dessus était peu lisible.
  Color get fill => AppColors.tekhelet;
  Color get onFill => Colors.white;

  /// Le rouge d'erreur de la marque n'atteint que 3,53:1 sur l'encre ; sa
  /// variante claire passe 4,5:1 sur le fond et sur les cartes sombres.
  Color get error => isDark ? AppColors.errorOnDark : AppColors.error;

  Color get onAccent => isDark ? AppColors.ink : Colors.white;
}
