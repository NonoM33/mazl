import 'dart:io';

import 'package:camera/camera.dart';
import 'dart:ui' show Size;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'text_line_recognizer.dart';

/// ML Kit implementation of [TextLineRecognizer]. The only file of the app
/// allowed to import `google_mlkit_text_recognition`.
class MlKitTextLineRecognizer implements TextLineRecognizer {
  MlKitTextLineRecognizer() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<List<String>> recognizeLines(CameraImage image, CameraDescription camera) async {
    final input = _toInputImage(image, camera);
    if (input == null) return const [];
    final result = await _recognizer.processImage(input);
    return [
      for (final block in result.blocks)
        for (final line in block.lines) line.text,
    ];
  }

  @override
  Future<void> close() => _recognizer.close();

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null) return null;
    // ML Kit wants NV21 on Android and BGRA8888 on iOS, in a single plane.
    final expected = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    if (format != expected || image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
