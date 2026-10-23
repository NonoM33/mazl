import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/verification_api.dart';
import '../../../../core/vision/face_pose_detector.dart';
import '../identity/identity_layout.dart';
import '../identity/identity_parts.dart';
import 'liveness_controller.dart';
import 'liveness_stage.dart';
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
      child: _screen(context),
    );
  }

  Widget _screen(BuildContext context) {
    if (_liveness.phase == LivenessPhase.expired) {
      return IdentityNotice(
        dark: true,
        icon: LucideIcons.clock,
        title: 'Session expirée',
        body: 'Le temps imparti est écoulé. Vous pouvez recommencer.',
        onClose: _cancel,
        actions: [IdentityPrimaryButton('Fermer', onPressed: _cancel)],
      );
    }
    switch (_stage) {
      case _Stage.starting:
        return IdentityPage(dark: true, onClose: _cancel, centerBody: true, child: const CircularProgressIndicator());
      case _Stage.permissionDenied:
        return IdentityNotice(
          dark: true,
          icon: LucideIcons.camera,
          title: 'Caméra nécessaire',
          body: 'MAZL utilise la caméra frontale pour vérifier que vous êtes bien la personne de vos photos.',
          onClose: _cancel,
          actions: [
            IdentityPrimaryButton(
              _permanentlyDenied ? 'Ouvrir les réglages' : 'Autoriser la caméra',
              onPressed: () => _permanentlyDenied ? openAppSettings() : _start(),
            ),
            IdentityLinkButton('Annuler', onPressed: _cancel),
          ],
        );
      case _Stage.cameraUnavailable:
        return IdentityNotice(
          dark: true,
          icon: LucideIcons.cameraOff,
          title: 'Caméra indisponible',
          body: 'Impossible de démarrer la caméra frontale.',
          onClose: _cancel,
          actions: [IdentityPrimaryButton('Fermer', onPressed: _cancel)],
        );
      case _Stage.running:
        return _preview(context);
    }
  }

  Widget _preview(BuildContext context) {
    final camera = _camera;
    if (camera == null) return const SizedBox.shrink();
    final total = widget.challenges.length;
    return LivenessStage(
      camera: _CoverPreview(camera: camera),
      instruction: challengeInstruction(_liveness.current),
      hint: poseFeedbackText(_liveness.feedback),
      holdProgress: _liveness.holdProgress(DateTime.now()),
      total: total,
      done: _liveness.captured,
      onCancel: _cancel,
    );
  }
}

/// Camera preview scaled to cover its box, without distortion.
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
