import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Loads the app's own font (Geist) into the test engine; call it in
/// `setUpAll` before measuring text.
///
/// Without it every test glyph is the 1 em wide square of the default test
/// font, about twice as wide as real text: a layout that fits on a real
/// 360 px phone would overflow in the test. Geist has no Hebrew or Cyrillic;
/// those glyphs fall back to its missing-glyph box, which is about as wide as
/// the real letters, so the widths stay realistic.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Geist');
  for (final file in const [
    'Geist-400.ttf',
    'Geist-500.ttf',
    'Geist-600.ttf',
    'Geist-700.ttf',
  ]) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
      ),
    );
  }
  await loader.load();
}
