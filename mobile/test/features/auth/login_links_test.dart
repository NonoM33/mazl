import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/di/providers/link_providers.dart';
import 'package:mazl/presentation/features/auth/screens/login_screen.dart';

import '../../helpers/l10n_helpers.dart';

/// The router builds `LoginScreen()` with no callback: the two legal links of
/// the sentence under the buttons must open the public pages by themselves
/// (docs/launch/V1-CONTRAT.md §6).
void main() {
  Future<List<Uri>> tapLink(WidgetTester tester, int index) async {
    final opened = <Uri>[];
    await pumpLocalized(
      tester,
      const LoginScreen(showApple: true),
      overrides: [
        externalLinkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    final l10n = lookupAppLocalizations(kTestLocale);
    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText() ==
                l10n.authLegal(
                  l10n.authLegalTermsLink,
                  l10n.authLegalPrivacyLink,
                ),
      ),
    );
    final links = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.recognizer != null) links.add(span);
      return true;
    });
    (links[index].recognizer! as dynamic).onTap();
    await tester.pump();
    return opened;
  }

  testWidgets('« Conditions » opens mazl.app/cgu', (tester) async {
    final opened = await tapLink(tester, 0);
    expect(opened.map((u) => u.toString()), ['https://mazl.app/cgu']);
  });

  testWidgets('« Confidentialité » opens mazl.app/confidentialite', (
    tester,
  ) async {
    final opened = await tapLink(tester, 1);
    expect(opened.map((u) => u.toString()), [
      'https://mazl.app/confidentialite',
    ]);
  });
}
