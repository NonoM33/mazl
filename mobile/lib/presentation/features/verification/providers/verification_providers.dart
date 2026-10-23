import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/vision_providers.dart';
import '../../../../core/services/verification_api.dart';
import '../capture/camera_liveness_capture.dart';

/// Guided live capture. Overridden by a fake in widget tests.
final livenessCaptureProvider = Provider<LivenessCapture>((ref) {
  return CameraLivenessCapture(detector: ref.watch(facePoseDetectorProvider));
});
