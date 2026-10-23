import 'dart:ui';

import 'package:camera/camera.dart';

/// One face found in a camera frame, in the coordinates of the UPRIGHT frame
/// (rotation compensation already applied by the detector).
class FacePose {
  const FacePose({required this.yawDegrees, required this.box, required this.frameSize});

  /// Head rotation around the vertical axis. Positive when the face turns
  /// toward the RIGHT side of the upright, unmirrored image. Detectors must
  /// return this convention; the liveness logic additionally learns which
  /// sign the user's left produces, so a flipped platform does not matter.
  final double yawDegrees;

  /// Face bounding box in upright-frame pixels.
  final Rect box;

  /// Size of the upright frame the [box] refers to.
  final Size frameSize;
}

/// Face pose detection on camera frames. Implementations hide the vision
/// framework (ML Kit today, Apple Vision on iOS later): nothing outside
/// `lib/core/vision` may import a vendor SDK.
abstract class FacePoseDetector {
  Future<List<FacePose>> detect(CameraImage image, CameraDescription camera);

  Future<void> close();
}
