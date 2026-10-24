import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';

import '../../../helpers/l10n_helpers.dart';

/// « mazl. » is a logo: its tekhelet dot stays after the word, even in a
/// right-to-left language.
void main() {
  testWidgets('en hébreu, le point du logo reste à droite du mot', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      const Scaffold(body: Center(child: MazlWordmark())),
      locale: const Locale('he'),
    );

    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byType(MazlWordmark),
        matching: find.byType(RichText),
      ),
    );
    expect(text.textDirection, TextDirection.ltr);
  });
}
