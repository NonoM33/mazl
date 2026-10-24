import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/services/verification_api.dart';
import '../../../../core/vision/face_pose_detector.dart';
import 'liveness_capture_screen.dart';

/// [LivenessCapture] backed by the front camera and a [FacePoseDetector].
class CameraLivenessCapture implements LivenessCapture {
  CameraLivenessCapture({
    required this.detector,
    this.timeout = const Duration(seconds: 110),
    this.leftYawSign,
  });

  final FacePoseDetector detector;

  /// Counted from the start of the capture. Slightly under the server's 120 s
  /// session so the user is told before the upload would be refused.
  final Duration timeout;

  /// +1 / -1 once the detector's sign for "user turns left" is confirmed on a
  /// device; null lets the first lateral pose pick it (see LivenessController).
  final int? leftYawSign;

  @override
  Future<List<Uint8List>?> capture(BuildContext context, List<FaceChallenge> challenges) {
    return Navigator.of(context, rootNavigator: true).push<List<Uint8List>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LivenessCaptureScreen(
          challenges: challenges,
          detector: detector,
          timeout: timeout,
          leftYawSign: leftYawSign,
        ),
      ),
    );
  }
}
