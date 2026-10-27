import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Every gesture reads its motion values from MazlMotion: no duration literal,
// no spring of its own. One file per line; add the new gestures here.
const _gestureFiles = <String>[
  'lib/presentation/features/chat/widgets/swipe_to_reply.dart',
  'lib/presentation/features/chat/widgets/photo_viewer.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_deck.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_deck_pose.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_deck_physics.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_intent_discs.dart',
  'lib/presentation/common/widgets/swipe_deck/swipe_progress_scale.dart',
  'lib/presentation/common/widgets/star_refresh/star_refresh.dart',
  'lib/presentation/common/widgets/star_refresh/star_frame.dart',
];

// Screens that only wire a gesture widget: they reach MazlMotion through the
// shared deck, and must not animate on their own.
const _wiringFiles = <String>[
  'lib/presentation/features/matching/screens/discover_screen.dart',
  'lib/presentation/features/couple/screens/couple_activities_feed_screen.dart',
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

  for (final path in _wiringFiles) {
    group(path, () {
      test('uses the shared deck, with no animation of its own', () {
        final code = _code(path);
        expect(code, contains('swipe_deck/swipe_deck.dart'));
        expect(code, isNot(contains('Duration(milliseconds:')));
        expect(code, isNot(contains('SpringDescription')));
        expect(code, isNot(contains('flutter_card_swiper')));
      });
    });
  }

  // docs/design/MOUVEMENT.md §7bis: every pull to refresh is the star.
  test('no screen uses the stock RefreshIndicator', () {
    final stock = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            _code(entity.path).contains('RefreshIndicator('))
          entity.path,
    ];
    expect(stock, isEmpty, reason: 'Use StarRefresh instead.');
  });

  test('flutter_card_swiper is gone from the project', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('flutter_card_swiper')),
    );
  });
}
