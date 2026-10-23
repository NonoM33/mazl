import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/verification/mrz/mrz_data.dart';
import 'package:mazl/presentation/features/verification/identity/manual_mrz_input.dart';
import 'package:mazl/presentation/features/verification/identity/mrz_scan_filter.dart';

const _a = MrzData(documentNumber: 'L898902C3', birthYymmdd: '740812', expiryYymmdd: '300415');
const _b = MrzData(documentNumber: 'L898902C4', birthYymmdd: '740812', expiryYymmdd: '300415');

void main() {
  group('MrzScanFilter', () {
    test('one frame is not enough', () {
      expect(MrzScanFilter().add(_a), isNull);
    });

    test('two consecutive identical frames confirm', () {
      final filter = MrzScanFilter()..add(_a);
      expect(filter.add(_a), _a);
    });

    test('two different readings do not confirm each other', () {
      final filter = MrzScanFilter()..add(_a);
      expect(filter.add(_b), isNull);
      expect(filter.add(_b), _b);
    });

    test('a frame with no valid MRZ breaks the streak', () {
      final filter = MrzScanFilter()..add(_a);
      expect(filter.add(null), isNull);
      expect(filter.add(_a), isNull);
      expect(filter.add(_a), _a);
    });

    test('reset forgets the candidate', () {
      final filter = MrzScanFilter()..add(_a);
      filter.reset();
      expect(filter.add(_a), isNull);
    });

    test('three frames can be required', () {
      final filter = MrzScanFilter(framesRequired: 3)..add(_a);
      expect(filter.add(_a), isNull);
      expect(filter.add(_a), _a);
    });
  });

  group('manual entry', () {
    final now = DateTime(2026, 10, 23);

    ({MrzData? data, ManualMrzErrors errors}) run(String number, String birth, String expiry) =>
        validateManualMrz(ManualMrzInput(documentNumber: number, birthDate: birth, expiryDate: expiry), now: now);

    test('valid input becomes access key data', () {
      final r = run(' 12ab34567 ', '12/08/1974', '15/04/2031');
      expect(r.errors.isEmpty, isTrue);
      expect(r.data!.documentNumber, '12AB34567');
      expect(r.data!.birthYymmdd, '740812');
      expect(r.data!.expiryYymmdd, '310415');
    });

    test('inner spaces in the number are dropped, lower case accepted', () {
      expect(run('12 ab 34567', '12/08/1974', '15/04/2031').data!.documentNumber, '12AB34567');
    });

    test('number too short, too long or with symbols', () {
      expect(run('AB12', '12/08/1974', '15/04/2031').errors.documentNumber, isNotNull);
      expect(run('A' * 13, '12/08/1974', '15/04/2031').errors.documentNumber, isNotNull);
      expect(run('AB-12345', '12/08/1974', '15/04/2031').errors.documentNumber, isNotNull);
    });

    test('impossible dates', () {
      expect(run('AB12345', '31/02/1974', '15/04/2031').errors.birthDate, isNotNull);
      expect(run('AB12345', '12/13/1974', '15/04/2031').errors.birthDate, isNotNull);
      expect(run('AB12345', '12/08/1974', '00/04/2031').errors.expiryDate, isNotNull);
      expect(run('AB12345', '', '').errors.birthDate, isNotNull);
    });

    test('leap day only in leap years', () {
      expect(run('AB12345', '29/02/2000', '15/04/2031').errors.birthDate, isNull);
      expect(run('AB12345', '29/02/2001', '15/04/2031').errors.birthDate, isNotNull);
    });

    test('birth date in the future is refused', () {
      expect(run('AB12345', '24/10/2026', '15/04/2031').errors.birthDate, isNotNull);
    });

    test('an expired date is accepted here: the flow reports it with a clear message', () {
      expect(run('AB12345', '12/08/1974', '15/04/2020').errors.isEmpty, isTrue);
    });

    test('all errors are reported at once', () {
      final r = run('', '', '');
      expect(r.data, isNull);
      expect(r.errors.documentNumber, isNotNull);
      expect(r.errors.birthDate, isNotNull);
      expect(r.errors.expiryDate, isNotNull);
    });
  });

  group('FrenchDateInputFormatter', () {
    String type(String raw) =>
        const FrenchDateInputFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: raw)).text;

    test('inserts slashes', () {
      expect(type('1'), '1');
      expect(type('120'), '12/0');
      expect(type('12081974'), '12/08/1974');
    });

    test('ignores letters and extra digits', () {
      expect(type('12a08b19749999'), '12/08/1974');
    });
  });
}
