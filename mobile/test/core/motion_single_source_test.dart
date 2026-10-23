import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every gesture reads its motion values from MazlMotion: no duration literal,
// no spring of its own. One file per line; add the new gestures here.
const _gestureFiles = <String>[
  'lib/presentation/features/chat/widgets/swipe_to_reply.dart',
  'lib/presentation/features/chat/widgets/photo_viewer.dart',
];

String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  for (final path in _gestureFiles) {
    group(path, () {
      test('imports core/motion/mazl_motion.dart', () {
        expect(_code(path), contains('core/motion/mazl_motion.dart'));
      });

      test('has no Duration(milliseconds: …) literal', () {
        expect(_code(path), isNot(contains('Duration(milliseconds:')));
      });

      test('has no SpringDescription of its own', () {
        expect(_code(path), isNot(contains('SpringDescription(')));
        expect(_code(path), isNot(contains('SpringDescription.')));
      });
    });
  }
}
