import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_review_format.dart';

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

  test('dates are shown day/month/year', () {
    expect(formatReviewDate(DateTime(1974, 8, 12)), '12/08/1974');
    expect(formatReviewDate(DateTime(2045, 4, 15)), '15/04/2045');
  });
}
