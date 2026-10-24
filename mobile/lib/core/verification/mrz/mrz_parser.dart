import 'mrz_check_digit.dart';
import 'mrz_data.dart';

/// Parses the machine readable zone of a passport (TD3) or ID card (TD1, TD2)
/// following ICAO 9303 parts 4 to 6.
///
/// A result is only returned when every check digit passes (document number,
/// birth date, expiry date, optional data of TD3 and the composite digit).
/// OCR confusions are repaired where the alphabet makes it safe:
///  - numeric fields (dates, check digits): O/Q/D->0, I/L->1, Z->2, S->5, G->6, B->8;
///  - document number (alphanumeric): one O/0, I/1, B/8, S/5 or Z/2
///    substitution, accepted only if the check digit and the composite digit
///    then match.
abstract final class MrzParser {
  /// Finds an MRZ in multi-line OCR text.
  static MrzData? parseText(String text) => parseLines(text.split(RegExp(r'[\r\n]+')));

  /// Finds an MRZ among OCR lines (extra lines before, between or after are ignored).
  static MrzData? parseLines(Iterable<String> rawLines) {
    final lines = rawLines.map(cleanLine).where((l) => _widths.contains(l.length)).toList();
    for (final format in MrzFormat.values) {
      for (var i = 0; i + format.lines <= lines.length; i++) {
        final window = lines.sublist(i, i + format.lines);
        if (window.any((l) => l.length != format.width)) continue;
        final parsed = parse(format, window);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Parses exactly [format.lines] cleaned lines of [format.width] characters.
  static MrzData? parse(MrzFormat format, List<String> lines) {
    if (lines.length != format.lines || lines.any((l) => l.length != format.width)) return null;
    final grid = [for (final l in lines) l.split('')];
    return switch (format) {
      MrzFormat.td1 => _parseTd1(grid),
      MrzFormat.td2 => _parseTd2(grid),
      MrzFormat.td3 => _parseTd3(grid),
    };
  }

  /// Uppercases, drops spaces and maps look-alike chevrons to `<`; any other
  /// character outside `A-Z 0-9 <` becomes `<` so line lengths are preserved.
  static String cleanLine(String raw) {
    final out = StringBuffer();
    for (final rune in raw.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch.trim().isEmpty) continue;
      out.write(_isMrzChar(rune) ? ch : '<');
    }
    return out.toString();
  }

  static const _widths = {30, 36, 44};

  static bool _isMrzChar(int c) => (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5A) || c == 0x3C;

  // ---- formats -----------------------------------------------------------

  static MrzData? _parseTd3(List<List<String>> g) {
    final doc = _DocField(line: 1, start: 0, checkLine: 1, checkAt: 9);
    final personalOk = _personalNumberOk(g[1], 28, 42);
    if (!personalOk) return null;
    return _finish(MrzFormat.td3, g, doc,
        birth: const _Date(1, 13), expiry: const _Date(1, 21), sexAt: const _At(1, 20),
        composite: const [_Seg(1, 0, 10), _Seg(1, 13, 20), _Seg(1, 21, 43)], compositeAt: const _At(1, 43));
  }

  static MrzData? _parseTd2(List<List<String>> g) {
    final doc = _DocField(line: 1, start: 0, checkLine: 1, checkAt: 9);
    return _finish(MrzFormat.td2, g, doc,
        birth: const _Date(1, 13), expiry: const _Date(1, 21), sexAt: const _At(1, 20),
        composite: const [_Seg(1, 0, 10), _Seg(1, 13, 20), _Seg(1, 21, 35)], compositeAt: const _At(1, 35));
  }

  static MrzData? _parseTd1(List<List<String>> g) {
    var doc = _DocField(line: 0, start: 5, checkLine: 0, checkAt: 14);
    if (g[0][14] == '<') {
      // Document number longer than 9: the excess and the check digit sit at
      // the start of the optional data, followed by a filler (ICAO 9303-5, 4.2.4).
      final rest = g[0].sublist(15).join();
      final end = rest.indexOf('<');
      if (end < 2) return null;
      doc = _DocField(line: 0, start: 5, checkLine: 0, checkAt: 15 + end - 1, overflowFrom: 15);
    }
    return _finish(MrzFormat.td1, g, doc,
        birth: const _Date(1, 0), expiry: const _Date(1, 8), sexAt: const _At(1, 7),
        composite: const [_Seg(0, 5, 30), _Seg(1, 0, 7), _Seg(1, 8, 15), _Seg(1, 18, 29)], compositeAt: const _At(1, 29));
  }

  // ---- shared checks -----------------------------------------------------

  static MrzData? _finish(
    MrzFormat format,
    List<List<String>> g,
    _DocField doc, {
    required _Date birth,
    required _Date expiry,
    required _At sexAt,
    required List<_Seg> composite,
    required _At compositeAt,
  }) {
    final birthDigits = _numericRun(g, birth.line, birth.start, 7);
    final expiryDigits = _numericRun(g, expiry.line, expiry.start, 7);
    final compositeDigit = _numericRun(g, compositeAt.line, compositeAt.index, 1);
    final docCheck = _numericRun(g, doc.checkLine, doc.checkAt, 1);
    if (birthDigits == null || expiryDigits == null || compositeDigit == null || docCheck == null) return null;

    final birthDate = birthDigits.substring(0, 6);
    final expiryDate = expiryDigits.substring(0, 6);
    if (!_validDate(birthDate) || !_validDate(expiryDate)) return null;
    if (mrzCheckDigit(birthDate) != int.parse(birthDigits[6])) return null;
    if (mrzCheckDigit(expiryDate) != int.parse(expiryDigits[6])) return null;
    if (!'MFX<'.contains(g[sexAt.line][sexAt.index])) return null;

    _write(g, birth.line, birth.start, birthDigits);
    _write(g, expiry.line, expiry.start, expiryDigits);
    _write(g, compositeAt.line, compositeAt.index, compositeDigit);
    _write(g, doc.checkLine, doc.checkAt, docCheck);

    final original = g[doc.line].sublist(doc.start, doc.start + 9).join() +
        (doc.overflowFrom == null ? '' : g[doc.line].sublist(doc.overflowFrom!, doc.checkAt).join());
    for (final candidate in _docNumberCandidates(original)) {
      if (mrzCheckDigit(candidate) != int.parse(docCheck)) continue;
      _writeDoc(g, doc, candidate);
      final expected = mrzCheckDigit([for (final s in composite) g[s.line].sublist(s.start, s.end).join()].join());
      if (expected == int.parse(compositeDigit)) {
        final number = candidate.replaceFirst(RegExp(r'<+$'), '');
        if (number.isEmpty || number.contains('<')) return null;
        return MrzData(format: format, documentNumber: number, birthYymmdd: birthDate, expiryYymmdd: expiryDate);
      }
    }
    return null;
  }

  static bool _personalNumberOk(List<String> line, int start, int checkAt) {
    final field = line.sublist(start, checkAt).join();
    final check = line[checkAt];
    if (field.replaceAll('<', '').isEmpty) return check == '<' || _numeric(check) == '0';
    final digit = _numeric(check);
    return digit != null && mrzCheckDigit(field) == int.parse(digit);
  }

  /// Document number as printed, then every variant with ONE look-alike
  /// substitution. Never two: swapping 8/B at two positions of weights 3 and 7
  /// leaves both the document and the composite check digits unchanged, so a
  /// double repair would accept wrong numbers. One substitution always changes
  /// the digit (checked for every pair below), so a single repair is sound.
  static Iterable<String> _docNumberCandidates(String field) sync* {
    yield field;
    final positions = [
      for (var i = 0; i < field.length; i++)
        if (_lookAlike.containsKey(field[i])) i,
    ];
    for (final i in positions) {
      yield field.replaceRange(i, i + 1, _lookAlike[field[i]]!);
    }
  }

  static const _lookAlike = {
    'O': '0', '0': 'O', 'I': '1', '1': 'I', 'B': '8', '8': 'B', 'S': '5', '5': 'S', 'Z': '2', '2': 'Z',
  };

  static const _toDigit = {
    'O': '0', 'Q': '0', 'D': '0', 'I': '1', 'L': '1', 'Z': '2', 'S': '5', 'G': '6', 'B': '8',
  };

  static String? _numeric(String s) {
    final out = StringBuffer();
    for (final ch in s.split('')) {
      final mapped = _toDigit[ch] ?? ch;
      if (mapped.length != 1 || mapped.codeUnitAt(0) < 0x30 || mapped.codeUnitAt(0) > 0x39) return null;
      out.write(mapped);
    }
    return out.toString();
  }

  static String? _numericRun(List<List<String>> g, int line, int start, int length) =>
      _numeric(g[line].sublist(start, start + length).join());

  static void _write(List<List<String>> g, int line, int start, String value) {
    for (var i = 0; i < value.length; i++) {
      g[line][start + i] = value[i];
    }
  }

  static void _writeDoc(List<List<String>> g, _DocField doc, String candidate) {
    _write(g, doc.line, doc.start, candidate.substring(0, 9));
    if (doc.overflowFrom != null) _write(g, doc.line, doc.overflowFrom!, candidate.substring(9));
  }

  static bool _validDate(String yymmdd) {
    final month = int.parse(yymmdd.substring(2, 4));
    final day = int.parse(yymmdd.substring(4, 6));
    if (month < 1 || month > 12 || day < 1) return false;
    const days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return day <= days[month - 1];
  }
}

class _DocField {
  const _DocField({
    required this.line,
    required this.start,
    required this.checkLine,
    required this.checkAt,
    this.overflowFrom,
  });

  final int line;
  final int start;
  final int checkLine;
  final int checkAt;
  final int? overflowFrom;
}

class _Date {
  const _Date(this.line, this.start);
  final int line;
  final int start;
}

class _At {
  const _At(this.line, this.index);
  final int line;
  final int index;
}

class _Seg {
  const _Seg(this.line, this.start, this.end);
  final int line;
  final int start;
  final int end;
}
