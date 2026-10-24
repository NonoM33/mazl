import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_format.dart';

import 'verification_l10n.dart';

void main() {
  group('maskDocumentNumber', () {
    test('passport number: only the last three characters are visible', () {
      expect(maskDocumentNumber('L898902C3'), '••••••2C3');
    });

    test('12-character French ID card number', () {
      expect(maskDocumentNumber('X4RTBPFW46C1'), '•••••••••6C1');
    });

    test('short numbers keep at most one character', () {
      expect(maskDocumentNumber('AB12'), '•••2');
      expect(maskDocumentNumber('A'), '•');
    });

    test('the full number never appears', () {
      for (final n in ['L898902C3', 'X4RTBPFW46C1', 'D23145890']) {
        expect(maskDocumentNumber(n), isNot(contains(n)));
        expect(maskDocumentNumber(n).length, n.length);
      }
    });
  });

  setUpAll(loadDatePatterns);

  test('dates are shown day/month/year in French', () {
    expect(formatReviewDate(DateTime(1974, 8, 12), 'fr'), '12/08/1974');
    expect(formatReviewDate(DateTime(2045, 4, 15), 'fr'), '15/04/2045');
  });

  test('dates follow the language, not the French pattern', () {
    expect(formatReviewDate(DateTime(1974, 8, 12), 'en'), '8/12/1974');
    expect(formatReviewDate(DateTime(1974, 8, 12), 'es'), '12/8/1974');
    expect(formatReviewDate(DateTime(1974, 8, 12), 'ru'), '12.08.1974');
    expect(formatReviewDate(DateTime(1974, 8, 12), 'he'), '12.8.1974');
  });

  test('the displayed number is isolated left to right, the mask unchanged inside', () {
    final shown = reviewDocumentNumber('L898902C3');
    expect(shown, contains(maskDocumentNumber('L898902C3')));
    expect(shown.codeUnits.first, 0x2066);
    expect(shown.codeUnits.last, 0x2069);
  });
}
