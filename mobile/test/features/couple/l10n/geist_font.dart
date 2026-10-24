import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's own font (Geist) into the test engine.
///
/// Without it every test glyph is the 1 em wide square of the default test
/// font, about twice as wide as real text: a layout that fits on a real
/// 360 px phone would overflow in the test. Geist has no Hebrew or Cyrillic;
/// those glyphs fall back to its missing-glyph box, which is about as wide as
/// the real letters, so the widths stay realistic.
Future<void> loadGeist() async {
  final loader = FontLoader('Geist');
  for (final file in const [
    'Geist-400.ttf',
    'Geist-500.ttf',
    'Geist-600.ttf',
    'Geist-700.ttf',
  ]) {
    loader.addFont(
      Future.value(
        ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
      ),
    );
  }
  await loader.load();
}
