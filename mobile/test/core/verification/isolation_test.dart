import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The OCR engine and the NFC library are swappable only if they stay behind
/// their adapter: one file each may import them.
void main() {
  List<String> importers(String package) => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => f.readAsStringSync().contains('package:$package'))
      .map((f) => f.path)
      .toList();

  test('only the ML Kit adapter imports google_mlkit_text_recognition', () {
    expect(importers('google_mlkit_text_recognition'), ['lib/core/vision/mlkit_text_line_recognizer.dart']);
  });

  test('only the dmrtd adapter imports dmrtd', () {
    expect(importers('dmrtd'), ['lib/core/verification/chip/dmrtd_chip_reader.dart']);
  });
}
