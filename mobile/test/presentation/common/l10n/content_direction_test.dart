import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_view/profile_sections.dart';

import '../../../helpers/l10n_helpers.dart';

/// A bio written in French, read in the Hebrew interface: its punctuation
/// stays in place (left-to-right) and it lines up on the right like the rest.
void main() {
  testWidgets('une bio en français dans l\'interface en hébreu', (
    tester,
  ) async {
    const bio = 'Passionnée de randonnée, je cherche quelqu\'un de sérieux.';
    await pumpLocalized(
      tester,
      const Scaffold(
        body: ProfileTextSection(label: 'אודות', text: bio),
      ),
      locale: const Locale('he'),
    );

    final text = tester.widget<Text>(find.text(bio));
    expect(text.textDirection, TextDirection.ltr);
    expect(text.textAlign, TextAlign.right);
  });

  testWidgets('une bio en hébreu dans l\'interface en français', (
    tester,
  ) async {
    const bio = 'אוהבת טיולים ומחפשת קשר רציני.';
    await pumpLocalized(
      tester,
      const Scaffold(
        body: ProfileTextSection(label: 'À propos', text: bio),
      ),
    );

    final text = tester.widget<Text>(find.text(bio));
    expect(text.textDirection, TextDirection.rtl);
    expect(text.textAlign, TextAlign.left);
  });
}
