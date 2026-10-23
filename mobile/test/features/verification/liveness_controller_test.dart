import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/core/vision/face_pose_detector.dart';
import 'package:mazl/presentation/features/verification/capture/liveness_controller.dart';

// Spec (brief): front |yaw| < 10, left/right |yaw| > 18, exactly one face,
// large enough, pose held ~400 ms. Server: left and right need OPPOSITE signs.

const _frame = Size(720, 1280);
final _t0 = DateTime.utc(2026, 10, 23, 10);

FacePose _face({double yaw = 0, double width = 400, Offset centre = const Offset(360, 640)}) => FacePose(
      yawDegrees: yaw,
      box: Rect.fromCenter(center: centre, width: width, height: width * 1.3),
      frameSize: _frame,
    );

DateTime _at(int ms) => _t0.add(Duration(milliseconds: ms));

LivenessController _controller(List<FaceChallenge> challenges, {int? leftYawSign}) => LivenessController(
      challenges: challenges,
      deadline: _t0.add(const Duration(seconds: 120)),
      leftYawSign: leftYawSign,
    );

/// Holds [yaw] from [startMs] for 500 ms and returns whether a capture fired.
bool _hold(LivenessController c, double yaw, int startMs) {
  var fired = false;
  for (var ms = 0; ms <= 500; ms += 100) {
    fired = c.observe([_face(yaw: yaw)], _at(startMs + ms)) || fired;
  }
  return fired;
}

void main() {
  group('feedback', () {
    test('no face', () {
      final c = _controller([FaceChallenge.front]);
      expect(c.observe([], _at(0)), isFalse);
      expect(c.feedback, PoseFeedback.noFace);
    });

    test('two faces are refused', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face(), _face()], _at(0));
      expect(c.feedback, PoseFeedback.multipleFaces);
      expect(c.observe([_face(), _face()], _at(1000)), isFalse);
    });

    test('a small face is refused', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face(width: 150)], _at(0));
      expect(c.feedback, PoseFeedback.tooSmall);
    });

    test('a face far from the centre is refused', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face(centre: const Offset(100, 640))], _at(0));
      expect(c.feedback, PoseFeedback.offCenter);
      c.observe([_face(centre: const Offset(360, 1200))], _at(10));
      expect(c.feedback, PoseFeedback.offCenter);
    });

    test('front: 10 degrees is not straight enough, 9.9 is', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face(yaw: 10)], _at(0));
      expect(c.feedback, PoseFeedback.lookStraight);
      c.observe([_face(yaw: -10)], _at(10));
      expect(c.feedback, PoseFeedback.lookStraight);
      c.observe([_face(yaw: 9.9)], _at(20));
      expect(c.feedback, PoseFeedback.holding);
    });
  });

  group('hold timer', () {
    test('fires only once the pose was held for 400 ms', () {
      final c = _controller([FaceChallenge.front]);
      expect(c.observe([_face()], _at(0)), isFalse);
      expect(c.observe([_face()], _at(399)), isFalse);
      expect(c.observe([_face()], _at(400)), isTrue);
      expect(c.phase, LivenessPhase.capturing);
    });

    test('progress grows during the hold and resets when the pose breaks', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face()], _at(0));
      expect(c.holdProgress(_at(200)), closeTo(0.5, 0.001));
      c.observe([_face(yaw: 25)], _at(250));
      expect(c.holdProgress(_at(260)), 0);
      c.observe([_face()], _at(300));
      expect(c.observe([_face()], _at(600)), isFalse, reason: 'timer restarted at 300');
      expect(c.observe([_face()], _at(700)), isTrue);
    });

    test('losing the face resets the timer', () {
      final c = _controller([FaceChallenge.front]);
      c.observe([_face()], _at(0));
      c.observe([], _at(300));
      expect(c.observe([_face()], _at(450)), isFalse);
    });

    test('observations are ignored while a still is being taken', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left]);
      expect(_hold(c, 0, 0), isTrue);
      expect(c.observe([_face()], _at(2000)), isFalse);
      expect(c.index, 0);
    });
  });

  group('transitions', () {
    test('success advances to the next challenge', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left]);
      _hold(c, 0, 0);
      c.captureSucceeded();
      expect(c.index, 1);
      expect(c.current, FaceChallenge.left);
      expect(c.phase, LivenessPhase.guiding);
      expect(c.captured, 1);
    });

    test('the last success completes the session', () {
      final c = _controller([FaceChallenge.front]);
      _hold(c, 0, 0);
      c.captureSucceeded();
      expect(c.phase, LivenessPhase.completed);
      expect(c.isFinished, isTrue);
      expect(c.observe([_face()], _at(5000)), isFalse);
    });

    test('a failed still asks the same pose again', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left]);
      _hold(c, 0, 0);
      c.captureFailed();
      expect(c.index, 0);
      expect(c.phase, LivenessPhase.guiding);
      expect(c.observe([_face()], _at(3000)), isFalse, reason: 'hold restarts');
      expect(c.observe([_face()], _at(3400)), isTrue);
    });

    test('captureSucceeded / captureFailed outside capturing do nothing', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left]);
      c.captureSucceeded();
      c.captureFailed();
      expect(c.index, 0);
    });

    test('cancel ends the session, and does not undo a completed one', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left]);
      c.cancel();
      expect(c.phase, LivenessPhase.cancelled);
      expect(c.observe([_face()], _at(0)), isFalse);

      final done = _controller([FaceChallenge.front]);
      _hold(done, 0, 0);
      done.captureSucceeded();
      done.cancel();
      expect(done.phase, LivenessPhase.completed);
    });

    test('expires at the deadline, even in the middle of a hold', () {
      final c = LivenessController(
        challenges: [FaceChallenge.front],
        deadline: _at(1000),
      );
      c.observe([_face()], _at(0));
      expect(c.observe([_face()], _at(1000)), isFalse);
      expect(c.phase, LivenessPhase.expired);
    });

    test('checkExpiry alone expires a session with no frames', () {
      final c = LivenessController(challenges: [FaceChallenge.front], deadline: _at(1000));
      expect(c.checkExpiry(_at(999)), isFalse);
      expect(c.checkExpiry(_at(1000)), isTrue);
      expect(c.phase, LivenessPhase.expired);
    });

    test('a finished session cannot be expired afterwards', () {
      final c = _controller([FaceChallenge.front]);
      _hold(c, 0, 0);
      c.captureSucceeded();
      expect(c.checkExpiry(_t0.add(const Duration(hours: 1))), isFalse);
      expect(c.phase, LivenessPhase.completed);
    });
  });

  group('lateral poses', () {
    test('18 degrees exactly is not enough, 18.1 is', () {
      final c = _controller([FaceChallenge.left], leftYawSign: 1);
      c.observe([_face(yaw: 18)], _at(0));
      expect(c.feedback, PoseFeedback.turnMore);
      c.observe([_face(yaw: 18.1)], _at(10));
      expect(c.feedback, PoseFeedback.holding);
    });

    test('a head turned too far is refused', () {
      final c = _controller([FaceChallenge.left], leftYawSign: 1);
      c.observe([_face(yaw: 70)], _at(0));
      expect(c.feedback, PoseFeedback.turnLess);
    });

    test('configured convention: left needs the configured sign, right the opposite', () {
      final c = _controller([FaceChallenge.left, FaceChallenge.right], leftYawSign: -1);
      c.observe([_face(yaw: 30)], _at(0));
      expect(c.feedback, PoseFeedback.turnOtherWay);
      expect(_hold(c, -30, 100), isTrue);
      c.captureSucceeded();
      c.observe([_face(yaw: -30)], _at(2000));
      expect(c.feedback, PoseFeedback.turnOtherWay);
      expect(_hold(c, 30, 3000), isTrue);
    });

    test('learned convention: first lateral pose accepts either sign, second must be opposite', () {
      for (final firstYaw in [-28.0, 28.0]) {
        final c = _controller([FaceChallenge.front, FaceChallenge.right, FaceChallenge.left]);
        _hold(c, 0, 0);
        c.captureSucceeded();
        expect(_hold(c, firstYaw, 1000), isTrue, reason: 'first lateral, yaw $firstYaw');
        c.captureSucceeded();
        c.observe([_face(yaw: firstYaw)], _at(3000));
        expect(c.feedback, PoseFeedback.turnOtherWay, reason: 'same side again');
        expect(_hold(c, -firstYaw, 4000), isTrue);
        c.captureSucceeded();
        expect(c.phase, LivenessPhase.completed);
      }
    });

    test('a straight face while a lateral pose is asked says turn more, not other way', () {
      final c = _controller([FaceChallenge.left, FaceChallenge.right]);
      _hold(c, 30, 0);
      c.captureSucceeded();
      c.observe([_face(yaw: 2)], _at(2000));
      expect(c.feedback, PoseFeedback.turnMore);
    });

    test('4 step session (front, left, right, front) completes with the opposite signs', () {
      final c = _controller([FaceChallenge.front, FaceChallenge.left, FaceChallenge.right, FaceChallenge.front]);
      final yaws = [0.0, 25.0, -25.0, 3.0];
      for (var i = 0; i < yaws.length; i++) {
        expect(_hold(c, yaws[i], i * 2000), isTrue, reason: 'step $i');
        c.captureSucceeded();
      }
      expect(c.phase, LivenessPhase.completed);
    });
  });
}
