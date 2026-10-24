import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';
import '../../helpers/l10n_helpers.dart';

// Luminance relative et contraste d'après WCAG 2.1 (§1.4.3), pas d'après le code.
double _channel(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('palette Encre & Tekhelet', () {
    final pairs = <String, (Color, Color)>{
      'encre sur blanc': (AppColors.ink, AppColors.paper),
      'texte secondaire sur blanc': (AppColors.muted, AppColors.paper),
      'texte secondaire sur brume': (AppColors.muted, AppColors.mist),
      'blanc sur tekhelet': (Colors.white, AppColors.tekhelet),
      'encre sur tekhelet clair (thème sombre)': (AppColors.ink, AppColors.tekheletLight),
      'erreur sur blanc': (AppColors.error, AppColors.paper),
      'tekhelet sur blanc': (AppColors.tekhelet, AppColors.paper),
      'icône inactive sur encre': (AppColors.iconOnInk, AppColors.ink),
      'texte sombre sur fond sombre': (AppColors.textPrimaryDark, AppColors.backgroundDark),
      'secondaire sombre sur fond sombre': (AppColors.textSecondaryDark, AppColors.backgroundDark),
      'texte Shabbat atténué': (AppColors.shabbatMuted, AppColors.shabbatBackground),
    };
    for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
      test('$name atteint 4,5:1', () {
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
      });
    }

    test('un seul accent : les anciens rôles colorés pointent vers le tekhelet', () {
      expect(AppColors.secondary, AppColors.tekhelet);
      expect(AppColors.accentGold, AppColors.tekhelet);
      expect(AppColors.gradientStart, AppColors.gradientEnd);
    });

    test('le texte sur l\'accent reste lisible dans les deux thèmes', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final scheme = theme.colorScheme;
        expect(_contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
      }
    });

    test('le thème utilise Geist', () {
      expect(AppTheme.lightTheme.textTheme.bodyLarge?.fontFamily, 'Geist');
      expect(AppTheme.darkTheme.textTheme.bodyLarge?.fontFamily, 'Geist');
    });
  });

  group('barre de navigation flottante', () {
    Future<void> pump(WidgetTester tester, {double safeBottom = 34}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              padding: EdgeInsets.only(bottom: safeBottom),
            ),
            child: Scaffold(
              extendBody: true,
              body: const SizedBox.expand(),
              bottomNavigationBar: MazlNavBar(
                items: const [
                  MazlNavItem(icon: LucideIcons.layers, label: 'Découvrir'),
                  MazlNavItem(icon: LucideIcons.user, label: 'Profil'),
                ],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('flotte au moins 12 pt au-dessus de la zone système', (tester) async {
      await pump(tester);
      final bar = tester.getRect(find.byKey(const Key('mazl-nav-bar')));
      expect(844 - 34 - bar.bottom, greaterThanOrEqualTo(12));
      expect(bar.left, greaterThanOrEqualTo(16));
    });

    testWidgets('garde son écart même sans zone système', (tester) async {
      await pump(tester, safeBottom: 0);
      final bar = tester.getRect(find.byKey(const Key('mazl-nav-bar')));
      expect(844 - bar.bottom, greaterThanOrEqualTo(12));
    });

    testWidgets('chaque onglet est un bouton nommé', (tester) async {
      await pump(tester);
      expect(find.bySemanticsLabel('Découvrir'), findsOneWidget);
      expect(find.bySemanticsLabel('Profil'), findsOneWidget);
    });
  });
}
