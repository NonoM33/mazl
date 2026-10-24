import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/identity_providers.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';
import 'package:mazl/core/vision/text_line_recognizer.dart';

import '../../../helpers/l10n_helpers.dart';

/// The five languages of the app.
const kAllLocales = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

/// ICAO specimen: born 1974-08-12, expires 2045-04-15.
const icaoSpecimen = MrzData(
  documentNumber: 'L898902C3',
  birthYymmdd: '740812',
  expiryYymmdd: '450415',
);

class NoopRecognizer implements TextLineRecognizer {
  @override
  Future<List<String>> recognizeLines(
    CameraImage image,
    CameraDescription camera,
  ) async => const [];

  @override
  Future<void> close() async {}
}

/// Renders an identity screen in [locale], at 360 px, with the camera recognizer stubbed.
Future<void> pumpIdentityView(
  WidgetTester tester,
  Widget view, {
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
}) async {
  await pumpLocalized(
    tester,
    view,
    locale: locale,
    brightness: brightness,
    overrides: [
      textLineRecognizerProvider.overrideWithValue(NoopRecognizer()),
      ...overrides,
    ],
  );
  // Not pumpAndSettle: progress indicators never settle.
  await tester.pump(const Duration(milliseconds: 100));
}

/// Every language, light and dark, at 360 px: a RenderFlex overflow fails the test.
Future<void> expectFitsEverywhere(
  WidgetTester tester,
  Widget Function() view,
) async {
  for (final locale in kAllLocales) {
    for (final brightness in Brightness.values) {
      await pumpIdentityView(
        tester,
        view(),
        locale: locale,
        brightness: brightness,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${locale.languageCode} ${brightness.name}',
      );
    }
  }
}

double centerX(WidgetTester tester, Finder finder) =>
    tester.getCenter(finder).dx;
