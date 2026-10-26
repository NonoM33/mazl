import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_pose_detector.dart';
import 'rotation_search.dart';

/// The only file allowed to import `google_mlkit_face_detection`.
///
/// The quarter turn that makes a frame upright is searched ([RotationSearch]):
/// the sensor orientation is right on a phone held upright, not on the
/// foldable iPhone opened sideways, where faces lay on their side.
class MlKitFacePoseDetector implements FacePoseDetector {
  MlKitFacePoseDetector()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

  final FaceDetector _detector;
  RotationSearch? _rotations;

  @override
  Future<List<FacePose>> detect(
    CameraImage image,
    CameraDescription camera,
  ) async {
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null || image.planes.length != 1) return const [];
    final expected = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;
    if (format != expected) return const [];
    final search = _rotations ??= RotationSearch(
      firstRotation(image.width, image.height, camera.sensorOrientation),
    );

    final plane = image.planes.first;
    for (final degrees in search.candidates()) {
      final rotation = InputImageRotationValue.fromRawValue(degrees);
      if (rotation == null) continue;
      final input = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      final faces = await _detector.processImage(input);
      final poses = [
        for (final face in faces)
          if (face.headEulerAngleY != null)
            FacePose(
              yawDegrees: face.headEulerAngleY!,
              box: face.boundingBox,
              frameSize: frameFor(
                face.boundingBox,
                _uprightSize(image, rotation),
              ),
            ),
      ];
      if (poses.isNotEmpty) {
        search.record(degrees);
        return poses;
      }
    }
    search.record(null);
    return const [];
  }

  /// The frame [box] is expressed in. ML Kit may give the box in the frame
  /// before the quarter turn: a box that leaves [upright] on one side while it
  /// fits the frame turned the other way belongs to that one. Without this, a
  /// face in the middle reads as off-centre (seen on iPhone on 2026-10-26).
  static Size frameFor(Rect box, Size upright) {
    bool fits(Size frame) =>
        box.right <= frame.width + 1 && box.bottom <= frame.height + 1;
    final turned = Size(upright.height, upright.width);
    return !fits(upright) && fits(turned) ? turned : upright;
  }

  static Size _uprightSize(CameraImage image, InputImageRotation rotation) {
    final turned =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    return turned
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());
  }

  @override
  Future<void> close() => _detector.close();
}
