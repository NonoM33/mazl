import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_pose_detector.dart';

/// The only file allowed to import `google_mlkit_face_detection`.
///
/// Assumes the capture is locked to portrait, so the rotation to apply is the
/// sensor orientation itself (no device orientation compensation).
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

  @override
  Future<List<FacePose>> detect(CameraImage image, CameraDescription camera) async {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null || image.planes.length != 1) return const [];
    final expected = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    if (format != expected) return const [];

    final plane = image.planes.first;
    final input = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );

    final turned = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
    final frameSize = turned
        ? Size(image.height.toDouble(), image.width.toDouble())
        : Size(image.width.toDouble(), image.height.toDouble());

    final faces = await _detector.processImage(input);
    return [
      for (final face in faces)
        if (face.headEulerAngleY != null)
          FacePose(yawDegrees: face.headEulerAngleY!, box: face.boundingBox, frameSize: frameSize),
    ];
  }

  @override
  Future<void> close() => _detector.close();
}
