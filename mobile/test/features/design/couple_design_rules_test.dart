import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Paid on 2026-10-23: the couple screens arrived with their own palette (pink
// #FF6B9D, navy gradients, multicolour confetti, emoji in titles and chips)
// while the rest of the app speaks « Encre & Tekhelet ». These rules read the
// SOURCES of every couple screen so the old look cannot come back.

const _roots = ['lib/presentation/features/couple'];
const _extraFiles = ['lib/presentation/features/navigation/screens/couple_navigation_screen.dart'];

final _rules = <String, RegExp>{
  'dégradé': RegExp(r'\b(Linear|Radial|Sweep)Gradient\('),
  'ombre portée': RegExp(r'\bBoxShadow\('),
  'couleur écrite à la main (Color(0x…))': RegExp(r'\bColor\(0x'),
  'couleur Material hors palette': RegExp(r'\bColors\.(?!white\b|black\b|transparent\b)\w+'),
  'accent rose du couple': RegExp(r'coupleAccent'),
};

/// Pictographs and symbols drawn as colour emoji (not Hebrew, not punctuation).
final _emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}]', unicode: true);
final _stringLiteral = RegExp(r"""('(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")""");

List<File> _files() => [
  for (final root in _roots)
    ...Directory(root).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
  for (final path in _extraFiles) File(path),
]..sort((a, b) => a.path.compareTo(b.path));

List<String> _violations(File file) {
  final found = <String>[];
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    _rules.forEach((name, pattern) {
      if (pattern.hasMatch(line)) found.add('${i + 1}: $name — ${line.trim()}');
    });
    for (final literal in _stringLiteral.allMatches(line)) {
      if (_emoji.hasMatch(literal.group(0)!)) found.add('${i + 1}: émoji dans un texte — ${line.trim()}');
    }
  }
  return found;
}

void main() {
  test('les écrans couple sont bien scannés', () {
    expect(_files().length, greaterThan(10));
  });

  for (final file in _files()) {
    test('DA couple : ${file.path}', () {
      final found = _violations(file);
      expect(found, isEmpty, reason: 'Hors palette Encre & Tekhelet :\n${found.join('\n')}');
    });
  }
}
