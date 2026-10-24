import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/presentation/common/widgets/swipe_deck/swipe_deck_physics.dart';
import 'package:mazl/presentation/common/widgets/swipe_deck/swipe_deck_types.dart';

const _size = Size(400, 600);
const _all = {SwipeDirection.left, SwipeDirection.right, SwipeDirection.up};
const _horizontal = {SwipeDirection.left, SwipeDirection.right};

SwipeDirection? _decide(
  Offset finger, {
  Offset velocity = Offset.zero,
  Set<SwipeDirection> allowed = _all,
}) {
  final card = SwipeDeckPhysics.follow(finger, allowed);
  return SwipeDeckPhysics.commitDirection(
    finger: finger,
    card: card,
    velocity: Velocity(pixelsPerSecond: velocity),
    size: _size,
    allowed: allowed,
  );
}

void main() {
  group('follow', () {
    test('allowed directions follow the finger 1:1', () {
      expect(
        SwipeDeckPhysics.follow(const Offset(120, -80), _all),
        const Offset(120, -80),
      );
      expect(
        SwipeDeckPhysics.follow(const Offset(-120, 0), _all),
        const Offset(-120, 0),
      );
    });

    test('down is always blocked: it gives way at the resistance rate', () {
      final card = SwipeDeckPhysics.follow(const Offset(0, 100), _all);
      expect(card.dy, closeTo(100 * MazlMotion.deckBlockedResistance, 1e-9));
    });

    test('a direction the deck does not allow is blocked too', () {
      final card = SwipeDeckPhysics.follow(
        const Offset(100, -100),
        _horizontal,
      );
      expect(card.dx, 100);
      expect(card.dy, closeTo(-100 * MazlMotion.deckBlockedResistance, 1e-9));
      final onlyLeft = SwipeDeckPhysics.follow(const Offset(100, 0), const {
        SwipeDirection.left,
        SwipeDirection.up,
      });
      expect(
        onlyLeft.dx,
        closeTo(100 * MazlMotion.deckBlockedResistance, 1e-9),
      );
    });

    test('unfollow is the inverse', () {
      const raw = Offset(100, 200);
      final card = SwipeDeckPhysics.follow(raw, _all);
      expect(SwipeDeckPhysics.fingerFor(card, _all), raw);
    });
  });

  group('rotation', () {
    double degrees(double r) => r * 180 / math.pi;

    test('is dx / width of the max rotation, clamped', () {
      expect(
        degrees(
          SwipeDeckPhysics.rotation(dx: 200, width: 400, grabbedLower: false),
        ),
        closeTo(MazlMotion.deckMaxRotationDegrees / 2, 1e-9),
      );
      expect(
        degrees(
          SwipeDeckPhysics.rotation(dx: 4000, width: 400, grabbedLower: false),
        ),
        closeTo(MazlMotion.deckMaxRotationDegrees, 1e-9),
      );
    });

    test('the sign flips when the card is grabbed by its lower half', () {
      final upper = SwipeDeckPhysics.rotation(
        dx: 100,
        width: 400,
        grabbedLower: false,
      );
      final lower = SwipeDeckPhysics.rotation(
        dx: 100,
        width: 400,
        grabbedLower: true,
      );
      expect(upper, greaterThan(0));
      expect(lower, -upper);
    });
  });

  group('progress', () {
    test('reaches 1 exactly at the threshold, per direction', () {
      final threshold = MazlMotion.deckThreshold * _size.width;
      expect(
        SwipeDeckPhysics.progress(Offset(threshold / 2, 0), _size, _all).value,
        closeTo(0.5, 1e-9),
      );
      expect(
        SwipeDeckPhysics.progress(Offset(threshold, 0), _size, _all).value,
        1,
      );
      expect(
        SwipeDeckPhysics.progress(Offset(threshold * 3, 0), _size, _all).value,
        1,
      );
      final left = SwipeDeckPhysics.progress(
        Offset(-threshold, 0),
        _size,
        _all,
      );
      expect((left.direction, left.value), (SwipeDirection.left, 1));
      final up = SwipeDeckPhysics.progress(
        Offset(0, -MazlMotion.deckUpThreshold * _size.height),
        _size,
        _all,
      );
      expect((up.direction, up.value), (SwipeDirection.up, 1));
    });

    test('a blocked direction never shows an intent', () {
      final p = SwipeDeckPhysics.progress(const Offset(300, 0), _size, const {
        SwipeDirection.left,
      });
      expect(p.value, 0);
      expect(p.direction, isNull);
    });
  });

  group('commit', () {
    test(
      'past 30 % of the width commits left or right, short of it does not',
      () {
        expect(_decide(const Offset(121, 0)), SwipeDirection.right);
        expect(_decide(const Offset(-121, 0)), SwipeDirection.left);
        expect(_decide(const Offset(119, 0)), isNull);
      },
    );

    test('past 25 % of the height upward commits up, only when allowed', () {
      expect(_decide(const Offset(0, -151)), SwipeDirection.up);
      expect(_decide(const Offset(0, -149)), isNull);
      expect(_decide(const Offset(0, -300), allowed: _horizontal), isNull);
      expect(
        _decide(const Offset(300, 0), allowed: const {SwipeDirection.left}),
        isNull,
      );
    });

    test(
      'a fast, long enough, horizontal fling commits below the threshold',
      () {
        expect(
          _decide(const Offset(60, 0), velocity: const Offset(1500, 0)),
          SwipeDirection.right,
        );
        expect(
          _decide(const Offset(-60, 5), velocity: const Offset(-1500, 0)),
          SwipeDirection.left,
        );
      },
    );

    test(
      'a fling that is too slow, too short, or against the drag does not',
      () {
        expect(
          _decide(const Offset(60, 0), velocity: const Offset(700, 0)),
          isNull,
        );
        expect(
          _decide(const Offset(40, 0), velocity: const Offset(1500, 0)),
          isNull,
        );
        expect(
          _decide(const Offset(60, 0), velocity: const Offset(-1500, 0)),
          isNull,
        );
      },
    );

    test('a fast, mostly vertical flick never becomes a like', () {
      expect(
        _decide(const Offset(60, 200), velocity: const Offset(1500, 4000)),
        isNull,
      );
      expect(
        _decide(const Offset(60, 100), velocity: const Offset(1500, 2000)),
        isNull,
      );
      expect(
        _decide(
          const Offset(60, -100),
          velocity: const Offset(1500, -2000),
          allowed: _horizontal,
        ),
        isNull,
      );
    });

    test(
      'a fast mostly vertical upward flick is a super like when up is allowed',
      () {
        expect(
          _decide(const Offset(10, -80), velocity: const Offset(0, -2000)),
          SwipeDirection.up,
        );
      },
    );
  });

  group('exit', () {
    test('goes fully off screen along the committed direction', () {
      final right = SwipeDeckPhysics.exitTarget(
        direction: SwipeDirection.right,
        card: const Offset(150, 20),
        velocity: Offset.zero,
        size: _size,
      );
      expect(right.dx, MazlMotion.deckExitDistance * _size.width);
      expect(right.dy, 20);
      final up = SwipeDeckPhysics.exitTarget(
        direction: SwipeDirection.up,
        card: const Offset(10, -200),
        velocity: const Offset(500, -2000),
        size: _size,
      );
      expect(up.dy, -MazlMotion.deckExitDistance * _size.height);
      expect(up.dx, closeTo(10 + 500 * MazlMotion.deckExitVelocityCarry, 1e-9));
    });
  });

  test('the back card follows the travel of the top card', () {
    expect(SwipeDeckPhysics.backProgress(Offset.zero, _size), 0);
    expect(SwipeDeckPhysics.backProgress(const Offset(200, 0), _size), 0.5);
    expect(SwipeDeckPhysics.backProgress(const Offset(0, -300), _size), 0.5);
    expect(SwipeDeckPhysics.backProgress(const Offset(0, 300), _size), 0);
    expect(SwipeDeckPhysics.backProgress(const Offset(4000, 0), _size), 1);
  });
}
