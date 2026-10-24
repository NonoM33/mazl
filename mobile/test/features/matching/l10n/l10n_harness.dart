import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/l10n_helpers.dart';

/// One language in one theme: the grid every translated screen is rendered in.
class L10nCase {
  const L10nCase(this.locale, this.brightness);

  final Locale locale;
  final Brightness brightness;

  bool get isRtl => locale.languageCode == 'he';

  String get name => '${locale.languageCode} ${brightness.name}';
}

/// English, Hebrew (right to left), Spanish and Russian, light and dark.
const l10nCases = [
  L10nCase(Locale('en'), Brightness.light),
  L10nCase(Locale('he'), Brightness.dark),
  L10nCase(Locale('es'), Brightness.light),
  L10nCase(Locale('ru'), Brightness.dark),
  L10nCase(Locale('he'), Brightness.light),
  L10nCase(Locale('ru'), Brightness.light),
];

/// Fails when one of the French [texts] is still on screen: in another
/// language, nothing of the reference language may leak.
void expectNoFrench(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsNothing, reason: '« $text » is French');
  }
}

/// The reading direction at [finder], for the Hebrew cases.
void expectDirection(WidgetTester tester, Finder finder, L10nCase c) {
  expect(
    textDirectionAt(tester, finder),
    c.isRtl ? TextDirection.rtl : TextDirection.ltr,
    reason: c.name,
  );
}
