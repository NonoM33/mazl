import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // French elides « de » before avril, août and octobre: « le bilan de
  // octobre » was shown on the couple screens (2026-10-27). A month inserted
  // after « de » or « du » can never be right for every month.
  test('no French string puts a month placeholder after de or du', () {
    final strings = (jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync())
            as Map<String, dynamic>)
        .entries
        .where((e) => !e.key.startsWith('@') && e.value is String);
    final wrong = [
      for (final entry in strings)
        if (RegExp(r"\b(de|du) \{month\}", caseSensitive: false)
            .hasMatch(entry.value as String))
          entry.key,
    ];
    expect(wrong, isEmpty);
  });
}
