import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/verification_api.dart';
import '../../../../core/vision/face_pose_detector.dart';
import 'liveness_controller.dart';
import 'liveness_texts.dart';

enum _Stage { starting, permissionDenied, cameraUnavailable, running }

/// Full screen guided capture: pops with one JPEG per challenge, or null.
///
/// Frames live in memory only. Camera frames are analysed one at a time; the
/// stills come from `takePicture`, whose temp file is deleted right away.
class LivenessCaptureScreen extends StatefulWidget {
  const LivenessCaptureScreen({
    super.key,
    required this.challenges,
    required this.detector,
    required this.timeout,
    this.leftYawSign,
  });

  final List<FaceChallenge> challenges;
  final FacePoseDetector detector;
  final Duration timeout;
  final int? leftYawSign;

  @override
  State<LivenessCaptureScreen> createState() => _LivenessCaptureScreenState();
}

class _LivenessCaptureScreenState extends State<LivenessCaptureScreen> with WidgetsBindingObserver {
  late final LivenessController _liveness;
  final List<Uint8List> _frames = [];
  CameraController? _camera;
  Timer? _clock;
  _Stage _stage = _Stage.starting;
  bool _analysing = false;
  bool _permanentlyDenied = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveness = LivenessController(
      challenges: widget.challenges,
      deadline: DateTime.now().add(widget.timeout),
      leftYawSign: widget.leftYawSign,
    );
    _clock = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
    unawaited(_start());
  }

  @override
  void dispose() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    final camera = _camera;
    _camera = null;
    if (camera != null) unawaited(_release(camera));
    _frames.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stage == _Stage.permissionDenied) unawaited(_start());
  }

  Future<void> _release(CameraController camera) async {
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } on CameraException {
      // already stopped
    }
    await camera.dispose();
  }

  Future<void> _start() async {
    final status = await Permission.camera.request();
    if (_closed) return;
    if (!status.isGranted) {
      setState(() {
        _stage = _Stage.permissionDenied;
        _permanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => throw CameraException('no_front_camera', 'No front camera'),
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_closed) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _stage = _Stage.running);
      await _startStream();
    } on CameraException catch (e) {
      debugPrint('Liveness camera error: ${e.code}');
      if (!_closed) setState(() => _stage = _Stage.cameraUnavailable);
    }
  }

  Future<void> _startStream() async {
    final camera = _camera;
    if (camera == null || camera.value.isStreamingImages) return;
    await camera.startImageStream(_onFrame);
  }

  void _onFrame(CameraImage image) {
    final camera = _camera;
    if (_analysing || camera == null || _liveness.phase != LivenessPhase.guiding) return;
    _analysing = true;
    unawaited(_analyse(image, camera.description));
  }

  Future<void> _analyse(CameraImage image, CameraDescription description) async {
    try {
      final faces = await widget.detector.detect(image, description);
      if (_closed) return;
      final now = DateTime.now();
      final shouldCapture = _liveness.observe(faces, now);
      setState(() {});
      if (shouldCapture) await _takeStill();
    } catch (e) {
      debugPrint('Liveness detection error: ${e.runtimeType}');
    } finally {
      _analysing = false;
    }
  }

  Future<void> _takeStill() async {
    final camera = _camera;
    if (camera == null) return;
    XFile? file;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      file = await camera.takePicture();
      final bytes = await file.readAsBytes();
      _frames.add(bytes);
      _liveness.captureSucceeded();
    } on CameraException catch (e) {
      debugPrint('Liveness still error: ${e.code}');
      _liveness.captureFailed();
    } finally {
      if (file != null) await _deleteQuietly(file.path);
    }
    if (!mounted) return;
    if (_liveness.phase == LivenessPhase.completed) {
      Navigator.of(context).pop(List<Uint8List>.unmodifiable(_frames));
      return;
    }
    setState(() {});
    try {
      await _startStream();
    } on CameraException catch (e) {
      debugPrint('Liveness stream restart error: ${e.code}');
      if (!_closed) setState(() => _stage = _Stage.cameraUnavailable);
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // already gone
    }
  }

  void _tick() {
    if (_closed) return;
    if (_liveness.checkExpiry(DateTime.now())) {
      final camera = _camera;
      if (camera != null && camera.value.isStreamingImages) unawaited(camera.stopImageStream());
      setState(() {});
    } else if (_liveness.phase == LivenessPhase.guiding) {
      setState(() {}); // keeps the hold ring moving
    }
  }

  void _cancel() {
    _liveness.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _body(context)),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_liveness.phase == LivenessPhase.expired) {
      return _Message(
        title: 'Session expirée',
        body: 'Le temps imparti est écoulé. Tu peux recommencer.',
        action: 'Fermer',
        onAction: _cancel,
      );
    }
    switch (_stage) {
      case _Stage.starting:
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      case _Stage.permissionDenied:
        return _Message(
          title: 'Caméra nécessaire',
          body: 'MAZL utilise la caméra frontale pour vérifier que tu es bien la personne de tes photos.',
          action: _permanentlyDenied ? 'Ouvrir les réglages' : 'Autoriser la caméra',
          onAction: () => _permanentlyDenied ? openAppSettings() : _start(),
          secondary: 'Annuler',
          onSecondary: _cancel,
        );
      case _Stage.cameraUnavailable:
        return _Message(
          title: 'Caméra indisponible',
          body: 'Impossible de démarrer la caméra frontale.',
          action: 'Fermer',
          onAction: _cancel,
        );
      case _Stage.running:
        return _preview(context);
    }
  }

  Widget _preview(BuildContext context) {
    final camera = _camera;
    if (camera == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final hint = poseFeedbackText(_liveness.feedback);
    final progress = _liveness.holdProgress(now);
    return Stack(
      fit: StackFit.expand,
      children: [
        _CoverPreview(camera: camera),
        CustomPaint(painter: _OvalGuidePainter(progress: progress)),
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            tooltip: 'Annuler',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _cancel,
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 56,
          child: Text(
            challengeInstruction(_liveness.current),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: hint == null
                    ? null
                    : Text(hint, style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              _ProgressDots(total: widget.challenges.length, done: _liveness.captured),
            ],
          ),
        ),
      ],
    );
  }
}

/// Camera preview scaled to cover the whole screen, without distortion.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    final size = camera.value.previewSize;
    if (size == null) return const SizedBox.shrink();
    // previewSize is reported in sensor (landscape) orientation.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: size.height, height: size.width, child: CameraPreview(camera)),
      ),
    );
  }
}

class _OvalGuidePainter extends CustomPainter {
  const _OvalGuidePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.47),
      width: size.width * 0.72,
      height: size.width * 0.72 * 1.3,
    );
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.7),
    );
    if (progress > 0) {
      canvas.drawArc(
        oval,
        -1.5708,
        6.28318 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF22C55E),
      );
    }
  }

  @override
  bool shouldRepaint(_OvalGuidePainter old) => old.progress != progress;
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < done ? Colors.white : Colors.white24,
              border: i == done ? Border.all(color: Colors.white, width: 1.5) : null,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.secondary,
    this.onSecondary,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(action)),
            if (secondary != null) TextButton(onPressed: onSecondary, child: Text(secondary!)),
          ],
        ),
      ),
    );
  }
}
