import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/verification/capture/liveness_capture_screen.dart';

// The server (src/features/verification/presentation/capture-diagnostics.ts)
// accepts exactly these keys, counts only: nothing else may leave the device.
void main() {
  test('the selfie diagnostics carry counts and sizes, nothing else', () {
    final json = CaptureDiagnostics().toJson();
    expect(json.keys.toSet(), {
      'platform',
      'frames',
      'framesWithFace',
      'feedback',
      'imageWidth',
      'imageHeight',
      'sensorOrientation',
      'rotation',
      'lastFace',
    });
    expect(json['lastFace'], isNull);
  });
}
