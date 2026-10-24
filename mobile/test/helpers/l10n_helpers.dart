import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/l10n.dart';

export 'package:mazl/core/l10n/app_language.dart';
export 'package:mazl/l10n/l10n.dart';

/// Les tests rendent l'app dans sa langue de référence, le français, sauf
/// ceux qui vérifient une autre langue.
const kTestLocale = Locale('fr');

/// Le plus petit téléphone visé : les textes longs (anglais, russe) doivent
/// y tenir sans déborder.
const kSmallPhone = Size(360, 780);

/// Rend [home] dans [locale], avec le vrai thème clair ou sombre, sur un
/// écran de [size]. Un débordement (RenderFlex overflow) fait échouer le test.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget home, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
  Size size = kSmallPhone,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: brightness == Brightness.light
            ? ThemeMode.light
            : ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: home,
      ),
    ),
  );
}

/// Le sens de lecture au point où [finder] est rendu.
TextDirection textDirectionAt(WidgetTester tester, Finder finder) =>
    Directionality.of(tester.element(finder));
