import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers/identity_providers.dart';
import '../../../../core/verification/mrz/mrz_data.dart';
import '../../../../core/verification/mrz/mrz_parser.dart';
import '../../../../core/vision/text_line_recognizer.dart';
import 'identity_layout.dart';
import 'mrz_scan_filter.dart';

/// Camera preview that reads the MRZ. Accepts it only when every check digit
/// passes on two consecutive frames; frames are never stored.
class MrzScannerView extends ConsumerStatefulWidget {
  const MrzScannerView({super.key, required this.onScanned, required this.onManual, required this.onClose});

  final ValueChanged<MrzData> onScanned;
  final VoidCallback onManual;
  final VoidCallback onClose;

  @override
  ConsumerState<MrzScannerView> createState() => _MrzScannerViewState();
}

class _MrzScannerViewState extends ConsumerState<MrzScannerView> {
  static const _minFrameGap = Duration(milliseconds: 350);

  final _filter = MrzScanFilter();
  // Held open with a listener: the provider is auto-disposed and would close
  // the OCR engine under our feet if it were only read.
  late final ProviderSubscription<TextLineRecognizer> _recognizerSubscription;
  late final TextLineRecognizer _recognizer;
  CameraController? _camera;
  CameraDescription? _description;
  bool _failed = false;
  bool _processing = false;
  bool _done = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _recognizerSubscription = ref.listenManual(textLineRecognizerProvider, (_, __) {});
    _recognizer = _recognizerSubscription.read();
    _openCamera();
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _description = back;
      setState(() => _camera = controller);
      await controller.startImageStream(_onFrame);
    } on Object {
      // Any failure to open the camera (denied, missing, plugin error) ends
      // in the same place: typing the data by hand.
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final description = _description;
    final now = DateTime.now();
    if (_processing || _done || description == null || now.difference(_lastFrame) < _minFrameGap) return;
    _processing = true;
    _lastFrame = now;
    try {
      final lines = await _recognizer.recognizeLines(image, description);
      final confirmed = _filter.add(MrzParser.parseLines(lines));
      if (confirmed != null && !_done && mounted) {
        _done = true;
        await HapticFeedback.mediumImpact();
        widget.onScanned(confirmed);
      }
    } on Exception {
      _filter.reset(); // a bad frame is not fatal: the next one may be fine
    } finally {
      _processing = false;
    }
  }

  @override
  void dispose() {
    final camera = _camera;
    if (camera != null) {
      if (camera.value.isStreamingImages) camera.stopImageStream();
      camera.dispose();
    }
    _recognizerSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    if (_failed || (camera != null && !camera.value.isInitialized)) {
      return IdentityPage(
        onClose: widget.onClose,
        actions: [FilledButton(onPressed: widget.onManual, child: const Text('Saisir les informations'))],
        child: const CenteredMessage(icon: Icons.no_photography_outlined, message: 'La caméra n\'est pas disponible.'),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null && camera.value.isInitialized) _Preview(controller: camera) else const SizedBox.shrink(),
          const IgnorePointer(child: CustomPaint(painter: _FramePainter())),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(icon: const Icon(Icons.close, color: Colors.white), tooltip: 'Fermer', onPressed: widget.onClose),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Cadre les lignes de « < » en bas du document.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: widget.onManual,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Saisir à la main'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    if (size == null) return const SizedBox.shrink();
    // previewSize is reported in landscape; the screen is portrait.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size.height, height: size.width, child: CameraPreview(controller)),
      ),
    );
  }
}

/// Dims everything but a document-shaped window.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width - 32;
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.45), width: width, height: width * 0.64),
      const Radius.circular(16),
    );
    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(window)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black54);
    canvas.drawRRect(
      window,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
