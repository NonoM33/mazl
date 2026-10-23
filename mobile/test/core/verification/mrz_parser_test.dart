import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/mrz/mrz_check_digit.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';
import 'package:mazl/core/verification/mrz/mrz_parser.dart';

// Specimen MRZs of ICAO Doc 9303 parts 4 and 5 (fictional state "UTO").
const _td3Line1 = 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
const _td3Line2 = 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';
const _td1Line1 = 'I<UTOD231458907<<<<<<<<<<<<<<<';
const _td1Line2 = '7408122F1204159UTO<<<<<<<<<<<6';
const _td1Line3 = 'ERIKSSON<<ANNA<MARIA<<<<<<<<<<';
const _td2Line1 = 'I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<';
const _td2Line2 = 'D231458907UTO7408122F1204159<<<<<<<6';
// Part 5 example of a document number longer than nine characters.
const _overflowLine1 = 'I<UTOD23145890<7349<<<<<<<<<<<';

/// Independent check-digit implementation, written from ICAO 9303-3 §4.9
/// with a lookup alphabet instead of the code's character arithmetic.
int _spec(String s) {
  const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const weights = [7, 3, 1];
  var sum = 0;
  for (var i = 0; i < s.length; i++) {
    final value = s[i] == '<' ? 0 : alphabet.indexOf(s[i]);
    sum += value * weights[i % 3];
  }
  return sum % 10;
}

String _pad(String s, int n) => s.padRight(n, '<');

/// Builds a TD3 passport MRZ from raw fields.
List<String> _buildTd3(String doc, String dob, String exp, {String personal = ''}) {
  final docField = _pad(doc, 9);
  final personalField = _pad(personal, 14);
  final personalCd = personal.isEmpty ? '<' : '${_spec(personalField)}';
  final body = '$docField${_spec(docField)}UTO$dob${_spec(dob)}M$exp${_spec(exp)}$personalField$personalCd';
  final composite = _spec(body.substring(0, 10) + body.substring(13, 20) + body.substring(21, 43));
  return [_td3Line1, '$body$composite'];
}

void main() {
  group('check digit (ICAO 9303-3)', () {
    test('specimen fields', () {
      expect(mrzCheckDigit('L898902C3'), 6);
      expect(mrzCheckDigit('740812'), 2);
      expect(mrzCheckDigit('120415'), 9);
      expect(mrzCheckDigit('ZE184226B<<<<<'), 1);
    });

    test('filler counts as zero and letters start at 10', () {
      expect(mrzCheckDigit('<<<<<<<<<'), 0);
      expect(mrzCheckDigit('A'), 70 % 10); // A = 10, weight 7
      expect(mrzCheckDigit('Z'), 35 * 7 % 10);
    });

    test('rejects characters outside the alphabet', () {
      expect(mrzCheckDigit('ab'), isNull);
      expect(mrzCheckDigit('É'), isNull);
    });

    test('agrees with the independent implementation', () {
      for (final s in ['L898902C3', '12AB34567', 'ZZZZZZZZZ', '000000001', 'D23145890734']) {
        expect(mrzCheckDigit(s), _spec(s));
      }
    });
  });

  group('specimens', () {
    test('TD3 passport', () {
      final mrz = MrzParser.parseLines([_td3Line1, _td3Line2])!;
      expect(mrz.format, MrzFormat.td3);
      expect(mrz.documentNumber, 'L898902C3');
      expect(mrz.birthYymmdd, '740812');
      expect(mrz.expiryYymmdd, '120415');
    });

    test('TD1 ID card', () {
      final mrz = MrzParser.parseLines([_td1Line1, _td1Line2, _td1Line3])!;
      expect(mrz.format, MrzFormat.td1);
      expect(mrz.documentNumber, 'D23145890');
      expect(mrz.birthYymmdd, '740812');
      expect(mrz.expiryYymmdd, '120415');
    });

    test('TD2 ID card', () {
      final mrz = MrzParser.parseLines([_td2Line1, _td2Line2])!;
      expect(mrz.format, MrzFormat.td2);
      expect(mrz.documentNumber, 'D23145890');
    });

    test('TD1 with a document number longer than nine characters', () {
      // composite digit recomputed with the independent implementation
      final l2 = _td1Line2.substring(0, 29);
      final composite = _spec(_overflowLine1.substring(5, 30) + l2.substring(0, 7) + l2.substring(8, 15) + l2.substring(18, 29));
      final mrz = MrzParser.parseLines([_overflowLine1, '$l2$composite', _td1Line3])!;
      expect(mrz.documentNumber, 'D23145890734');
    });

    test('text blob with noise lines around the MRZ', () {
      final mrz = MrzParser.parseText('RÉPUBLIQUE\nPASSEPORT\n$_td3Line1\n$_td3Line2\nSignature\n')!;
      expect(mrz.documentNumber, 'L898902C3');
    });

    test('same MRZ read twice gives equal data', () {
      expect(MrzParser.parseLines([_td3Line1, _td3Line2]), MrzParser.parseLines([_td3Line1, _td3Line2]));
    });
  });

  group('independently built vectors', () {
    test('alphanumeric document number with a personal number', () {
      final lines = _buildTd3('12AB34567', '900228', '300101', personal: 'ABC123');
      final mrz = MrzParser.parseLines(lines)!;
      expect(mrz.documentNumber, '12AB34567');
      expect(mrz.birthYymmdd, '900228');
    });

    test('short document number padded with fillers', () {
      final mrz = MrzParser.parseLines(_buildTd3('AB1234', '850630', '291231'))!;
      expect(mrz.documentNumber, 'AB1234');
    });

    test('impossible calendar dates are refused even with valid check digits', () {
      expect(MrzParser.parseLines(_buildTd3('AB1234', '851330', '291231')), isNull);
      expect(MrzParser.parseLines(_buildTd3('AB1234', '850230', '291231')), isNull); // 30 February
      expect(MrzParser.parseLines(_buildTd3('AB1234', '850630', '290431').toList()..[1] = _buildTd3('AB1234', '850630', '291231')[1]), isNotNull);
    });
  });

  group('OCR noise', () {
    test('spaces and lower case are ignored', () {
      final noisy = _td3Line2.toLowerCase().replaceAll('', ' ');
      expect(MrzParser.parseLines([_td3Line1, noisy])!.documentNumber, 'L898902C3');
    });

    test('look-alike chevrons are read as fillers', () {
      final lines = [_td3Line1.replaceAll('<', '«'), _td3Line2.replaceAll('<', '‹')];
      expect(MrzParser.parseLines(lines)!.documentNumber, 'L898902C3');
    });

    test('letters in numeric fields are repaired (O->0, I->1, S->5, B->8, Z->2)', () {
      // birth date 740812 -> 74O8I2 ; expiry 120415 -> I2O4I5 ; check digit 2 -> Z ; 9 stays
      const noisy = 'L898902C36UTO74O8I2ZF' 'I2O4I59' 'ZE184226B<<<<<10';
      expect(noisy.length, 44);
      final mrz = MrzParser.parseLines([_td3Line1, noisy])!;
      expect(mrz.birthYymmdd, '740812');
      expect(mrz.expiryYymmdd, '120415');
    });

    test('document number O/0 confusion is repaired through its check digit', () {
      final noisy = _td3Line2.replaceFirst('L898902C3', 'L8989O2C3');
      expect(MrzParser.parseLines([_td3Line1, noisy])!.documentNumber, 'L898902C3');
    });

    test('two confusions in the document number are not guessed (8/B swaps collide on weights 3 and 7)', () {
      expect(_spec('LB9B902C3'), _spec('L898902C3'));
      final noisy = _td3Line2.replaceFirst('L898902C3', 'L89B9O2C3');
      expect(MrzParser.parseLines([_td3Line1, noisy]), isNull);
    });

    test('a single look-alike substitution always changes the check digit', () {
      const pairs = {'O': '0', 'I': '1', 'B': '8', 'S': '5', 'Z': '2'};
      pairs.forEach((letter, digit) {
        for (var i = 0; i < 9; i++) {
          final a = 'A' * i + letter + 'A' * (8 - i);
          final b = 'A' * i + digit + 'A' * (8 - i);
          expect(_spec(a), isNot(_spec(b)), reason: '$letter/$digit at $i');
        }
      });
    });

    test('document number letters are not blindly rewritten', () {
      final mrz = MrzParser.parseLines(_buildTd3('OB1234', '850630', '291231'))!;
      expect(mrz.documentNumber, 'OB1234');
    });

    test('a wrong digit anywhere is refused', () {
      for (final i in [0, 3, 13, 15, 19, 21, 24, 27, 30, 42, 43]) {
        final ch = _td3Line2[i];
        final replacement = ch == '7' ? '8' : '7';
        final broken = _td3Line2.replaceRange(i, i + 1, replacement);
        expect(MrzParser.parseLines([_td3Line1, broken]), isNull, reason: 'position $i');
      }
    });

    test('a misread document number that no look-alike repair explains is refused', () {
      final noisy = _td3Line2.replaceFirst('L898902C3', 'L898942C3');
      expect(MrzParser.parseLines([_td3Line1, noisy]), isNull);
    });

    test('wrong line lengths are refused', () {
      expect(MrzParser.parseLines([_td3Line1, _td3Line2.substring(1)]), isNull);
      expect(MrzParser.parseLines([_td3Line1]), isNull);
      expect(MrzParser.parseLines(<String>[]), isNull);
    });

    test('garbage is refused', () {
      expect(MrzParser.parseText('Hello world\nnothing to see'), isNull);
    });
  });

  group('MrzData', () {
    test('birth century: 74 is 1974, a future two-digit year is the previous century', () {
      final now = DateTime(2026, 10, 23);
      expect(const MrzData(format: MrzFormat.td3, documentNumber: 'X', birthYymmdd: '740812', expiryYymmdd: '300101').birthDate(now: now), DateTime(1974, 8, 12));
      expect(const MrzData(format: MrzFormat.td3, documentNumber: 'X', birthYymmdd: '050101', expiryYymmdd: '300101').birthDate(now: now), DateTime(2005, 1, 1));
    });

    test('expiry is in the 2000s', () {
      const mrz = MrzData(format: MrzFormat.td3, documentNumber: 'X', birthYymmdd: '740812', expiryYymmdd: '120415');
      expect(mrz.expiryDate(), DateTime(2012, 4, 15));
    });

    test('fromDates formats YYMMDD', () {
      final mrz = MrzData.fromDates(format: MrzFormat.td3, documentNumber: 'X', birthDate: DateTime(1974, 8, 12), expiryDate: DateTime(2031, 4, 5));
      expect(mrz.birthYymmdd, '740812');
      expect(mrz.expiryYymmdd, '310405');
    });

    test('toString never prints personal data', () {
      const mrz = MrzData(format: MrzFormat.td3, documentNumber: 'L898902C3', birthYymmdd: '740812', expiryYymmdd: '120415');
      expect(mrz.toString(), isNot(contains('L898902C3')));
      expect(mrz.toString(), isNot(contains('740812')));
    });
  });
}
