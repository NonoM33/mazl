import 'package:camera/camera.dart';

/// Reads the lines of text visible in a camera frame.
///
/// The MRZ scanner depends on this interface only, so the OCR engine can be
/// swapped per platform (ML Kit today, Apple Vision on iOS later).
abstract class TextLineRecognizer {
  /// Returns the recognized text lines of [image], top to bottom.
  /// [camera] gives the sensor orientation needed to upright the frame.
  Future<List<String>> recognizeLines(CameraImage image, CameraDescription camera);

  Future<void> close();
}
