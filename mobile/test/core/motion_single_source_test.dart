import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every gesture reads its motion values from `core/motion/mazl_motion.dart`.
/// One file per line, so that each gesture adds its own lines when it lands.

/// Files that animate: they import MazlMotion themselves.
const _animatingFiles = <String>[
  'lib/presentation/common/widgets/swipe_deck/swipe_deck.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_deck_pose.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_deck_physics.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_intent_discs.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_progress_scale.dart',
];

/// Screens that only wire a gesture widget: they reach MazlMotion through it.
const _wiringFiles = <String>[
  'lib/presentation/features/matching/screens/discover_screen.dart',
  'lib/presentation/features/couple/screens/couple_activities_feed_screen.dart',
];

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('the files that animate import MazlMotion', () {
    for (final path in _animatingFiles) {
      expect(
        _read(path),
        contains('core/motion/mazl_motion.dart'),
        reason: '$path must read its values from MazlMotion',
      );
    }
  });

  test('the screens that wire a gesture use the shared widget', () {
    for (final path in _wiringFiles) {
      expect(
        _read(path),
        contains('swipe_deck/swipe_deck.dart'),
        reason: '$path must use the shared deck, not its own animation',
      );
    }
  });

  test('no gesture file writes a duration or a spring of its own', () {
    for (final path in [..._animatingFiles, ..._wiringFiles]) {
      final source = _read(path);
      expect(
        source,
        isNot(contains('Duration(milliseconds:')),
        reason: '$path has a Duration literal: add it to MazlMotion',
      );
      expect(
        source,
        isNot(contains('SpringDescription(')),
        reason: '$path builds its own spring: use MazlMotion.spring',
      );
    }
  });

  test('flutter_card_swiper is gone', () {
    for (final path in [..._animatingFiles, ..._wiringFiles]) {
      expect(_read(path), isNot(contains('flutter_card_swiper')), reason: path);
    }
    expect(_read('pubspec.yaml'), isNot(contains('flutter_card_swiper')));
  });
}
