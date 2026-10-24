import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/providers/identity_providers.dart';
import '../../../../core/verification/mrz/mrz_data.dart';
import '../../../../core/verification/mrz/mrz_parser.dart';
import '../../../../core/vision/text_line_recognizer.dart';
import '../../../../l10n/l10n.dart';
import 'identity_layout.dart';
import 'identity_parts.dart';
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
    final l10n = context.l10n;
    if (_failed || (camera != null && !camera.value.isInitialized)) {
      return IdentityNotice(
        dark: true,
        eyebrow: l10n.verificationStepLabel(1, 3),
        icon: LucideIcons.cameraOff,
        title: l10n.verificationCameraNotAvailable,
        body: l10n.verificationScanUnavailableBody,
        onClose: widget.onClose,
        actions: [IdentityPrimaryButton(l10n.verificationScanEnterDetails, onPressed: widget.onManual)],
      );
    }
    return IdentityPage(
      dark: true,
      eyebrow: l10n.verificationStepLabel(1, 3),
      onClose: widget.onClose,
      title: l10n.verificationScanTitle,
      subtitle: l10n.verificationScanHint,
      actions: [IdentityLinkButton(l10n.verificationScanManual, onPressed: widget.onManual)],
      child: _ScanFrame(camera: camera),
    );
  }
}

/// The camera in a rounded window with corner ticks; the band where the two
/// MRZ lines must sit is outlined in the accent colour.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.camera});

  final CameraController? camera;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = camera;
    return Semantics(
      label: context.l10n.verificationScanFrameSemantics,
      child: AspectRatio(
        aspectRatio: 1.45,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: ColoredBox(
                color: scheme.surfaceContainer,
                child: controller != null && controller.value.isInitialized ? _Preview(controller: controller) : null,
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.primary, width: 1.5),
                ),
              ),
            ),
            IgnorePointer(child: CustomPaint(painter: _CornerTicksPainter(scheme.onSurface))),
          ],
        ),
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

/// Four L-shaped ticks hugging the rounded corners of the window.
class _CornerTicksPainter extends CustomPainter {
  const _CornerTicksPainter(this.color);

  final Color color;

  static const _r = _ScanFrame._radius;
  static const _len = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const radius = Radius.circular(_r);
    final w = size.width;
    final h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, _len)
          ..lineTo(0, _r)
          ..arcToPoint(const Offset(_r, 0), radius: radius)
          ..lineTo(_len, 0),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w - _len, 0)
          ..lineTo(w - _r, 0)
          ..arcToPoint(Offset(w, _r), radius: radius)
          ..lineTo(w, _len),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w, h - _len)
          ..lineTo(w, h - _r)
          ..arcToPoint(Offset(w - _r, h), radius: radius)
          ..lineTo(w - _len, h),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(_len, h)
          ..lineTo(_r, h)
          ..arcToPoint(Offset(0, h - _r), radius: radius)
          ..lineTo(0, h - _len),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CornerTicksPainter old) => old.color != color;
}
