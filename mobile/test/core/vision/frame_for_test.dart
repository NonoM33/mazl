import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/vision/mlkit_face_pose_detector.dart';

// Seen on 2026-10-26: a face in the middle of the selfie read « Centrez votre
// visage dans le cercle ». A box given in the landscape frame was divided by
// the portrait frame.
void main() {
  const portrait = Size(1080, 1920);

  test('a box that only fits the landscape frame belongs to it', () {
    // Centred in 1920 x 1080: leaves the portrait frame on the right.
    final box = Rect.fromCenter(
      center: const Offset(960, 540),
      width: 420,
      height: 420,
    );
    expect(
      MlKitFacePoseDetector.frameFor(box, portrait),
      const Size(1920, 1080),
    );
    final frame = MlKitFacePoseDetector.frameFor(box, portrait);
    expect(box.center.dx / frame.width, closeTo(0.5, 0.01));
    expect(box.center.dy / frame.height, closeTo(0.5, 0.01));
  });

  test('a box that fits the upright frame stays in it', () {
    final box = Rect.fromCenter(
      center: const Offset(540, 960),
      width: 420,
      height: 420,
    );
    expect(MlKitFacePoseDetector.frameFor(box, portrait), portrait);
  });
}
