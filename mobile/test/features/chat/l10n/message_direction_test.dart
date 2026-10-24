import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/l10n_helpers.dart';
import '../chat_test_support.dart';

/// A message is written by a member, in the member's own language: it reads
/// in the direction of its own text, whatever the language of the interface.
/// Seen on the simulator: in Hebrew, « …ta semaine ? » showed as « ? semaine ».
void main() {
  setUpAll(() async {
    await loadChatFonts();
    await initializeDateFormatting();
  });

  TextDirection? directionOf(WidgetTester tester, String content) =>
      tester.widget<Text>(find.text(content)).textDirection;

  testWidgets('un message en français reste de gauche à droite en hébreu', (
    tester,
  ) async {
    const content = "Salut ! Comment s'est passée ta semaine ?";
    await ChatHarness(
      initial: chatState([msg(1, other, content, at: today(9, 0))]),
    ).pump(tester, locale: const Locale('he'));

    expect(directionOf(tester, content), TextDirection.ltr);
  });

  testWidgets('un message en hébreu est de droite à gauche en français', (
    tester,
  ) async {
    const content = 'שבת שלום! מה שלומך?';
    await ChatHarness(
      initial: chatState([msg(1, other, content, at: today(9, 0))]),
    ).pump(tester, locale: kTestLocale);

    expect(directionOf(tester, content), TextDirection.rtl);
  });
}
