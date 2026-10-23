import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vision/face_pose_detector.dart';
import '../../vision/mlkit_face_pose_detector.dart';

/// Face pose detection for the live selfie. Swap the implementation here
/// (e.g. Apple Vision on iOS); nothing else knows the vendor SDK.
final facePoseDetectorProvider = Provider<FacePoseDetector>((ref) {
  final detector = MlKitFacePoseDetector();
  ref.onDispose(detector.close);
  return detector;
});
