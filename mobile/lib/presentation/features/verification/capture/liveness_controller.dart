import 'dart:ui';

import '../../../../core/services/verification_api.dart';
import '../../../../core/vision/face_pose_detector.dart';

/// Thresholds of the on-device pose check. The server re-checks with its own
/// (stricter) numbers: front |yaw| < 0.12, lateral |yaw| > 0.22 (nose offset
/// ratio), so these only decide when the phone takes the still.
class LivenessThresholds {
  const LivenessThresholds({
    this.frontMaxYaw = 10,
    this.lateralMinYaw = 18,
    this.lateralMaxYaw = 45,
    this.minFaceWidthRatio = 0.30,
    this.maxCenterOffset = 0.20,
    this.hold = const Duration(milliseconds: 400),
  });

  /// Front pose: |yaw| must stay under this many degrees.
  final double frontMaxYaw;

  /// Left / right pose: |yaw| must exceed this...
  final double lateralMinYaw;

  /// ...without going so far that the face can no longer be recognised.
  final double lateralMaxYaw;

  /// Face box width over frame width. 0.30 of a 720 px wide frame leaves an
  /// eye distance well above the 60 px the server demands.
  final double minFaceWidthRatio;

  /// Max distance of the face centre from the frame centre, as a fraction of
  /// the frame size.
  final double maxCenterOffset;

  /// How long the pose must be held before the still is taken.
  final Duration hold;
}

enum LivenessPhase { guiding, capturing, completed, expired, cancelled }

/// What the user should fix, when the pose is not accepted yet.
enum PoseFeedback {
  noFace,
  multipleFaces,
  tooSmall,
  offCenter,
  lookStraight,
  turnMore,
  turnLess,
  turnOtherWay,
  holding,
}

/// State machine of the guided capture. Pure Dart: feed it detector output and
/// timestamps, it says when to take each still. Frames are not handled here.
///
/// Left / right: the yaw sign a user's left produces depends on the platform
/// and on mirroring, and the server only requires the two lateral frames to
/// have OPPOSITE signs. So unless [leftYawSign] is given, the first lateral
/// pose accepts either direction and the second one must be the opposite.
class LivenessController {
  LivenessController({
    required List<FaceChallenge> challenges,
    required this.deadline,
    this.thresholds = const LivenessThresholds(),
    int? leftYawSign,
  })  : challenges = List.unmodifiable(challenges),
        _configuredLeftSign = leftYawSign {
    assert(challenges.isNotEmpty);
    assert(leftYawSign == null || leftYawSign == 1 || leftYawSign == -1);
  }

  final List<FaceChallenge> challenges;
  final DateTime deadline;
  final LivenessThresholds thresholds;
  final int? _configuredLeftSign;

  LivenessPhase _phase = LivenessPhase.guiding;
  PoseFeedback _feedback = PoseFeedback.noFace;
  int _index = 0;
  DateTime? _holdSince;
  double? _acceptedYaw;
  int? _leftSign;
  int? _rightSign;

  LivenessPhase get phase => _phase;
  PoseFeedback get feedback => _feedback;

  /// Index of the step being asked (equals [challenges] length when done).
  int get index => _index;
  int get captured => _index;
  FaceChallenge get current => challenges[_index.clamp(0, challenges.length - 1)];
  bool get isFinished =>
      _phase == LivenessPhase.completed || _phase == LivenessPhase.expired || _phase == LivenessPhase.cancelled;

  /// 0..1 progress of the current hold.
  double holdProgress(DateTime now) {
    final since = _holdSince;
    if (since == null || _phase != LivenessPhase.guiding) return 0;
    final ratio = now.difference(since).inMilliseconds / thresholds.hold.inMilliseconds;
    return ratio.clamp(0.0, 1.0);
  }

  /// Marks the session expired when [deadline] passed. Returns true if so.
  bool checkExpiry(DateTime now) {
    if (isFinished) return _phase == LivenessPhase.expired;
    if (!now.isBefore(deadline)) {
      _phase = LivenessPhase.expired;
      _holdSince = null;
      return true;
    }
    return false;
  }

  /// Feeds one detector result. Returns true when the pose has been held long
  /// enough: the caller must now take the still and call [captureSucceeded] or
  /// [captureFailed]. While capturing, observations are ignored.
  bool observe(List<FacePose> faces, DateTime now) {
    if (checkExpiry(now) || _phase != LivenessPhase.guiding) return false;

    final verdict = _evaluate(faces);
    _feedback = verdict.feedback;
    if (!verdict.accepted) {
      _holdSince = null;
      return false;
    }

    _acceptedYaw = verdict.yaw;
    _holdSince ??= now;
    if (now.difference(_holdSince!) >= thresholds.hold) {
      _phase = LivenessPhase.capturing;
      return true;
    }
    return false;
  }

  /// The still of the current step was taken.
  void captureSucceeded() {
    if (_phase != LivenessPhase.capturing) return;
    final yaw = _acceptedYaw;
    if (yaw != null) {
      if (current == FaceChallenge.left) _leftSign = yaw.sign.toInt();
      if (current == FaceChallenge.right) _rightSign = yaw.sign.toInt();
    }
    _index++;
    _holdSince = null;
    _acceptedYaw = null;
    _feedback = PoseFeedback.noFace;
    _phase = _index >= challenges.length ? LivenessPhase.completed : LivenessPhase.guiding;
  }

  /// Taking the still failed: ask the same pose again.
  void captureFailed() {
    if (_phase != LivenessPhase.capturing) return;
    _holdSince = null;
    _acceptedYaw = null;
    _phase = LivenessPhase.guiding;
  }

  void cancel() {
    if (_phase != LivenessPhase.completed) _phase = LivenessPhase.cancelled;
    _holdSince = null;
  }

  /// Sign (+1 / -1) the yaw must have for [challenge], or null when any sign
  /// is acceptable (first lateral step with no configured convention).
  int? _requiredSign(FaceChallenge challenge) {
    final configured = _configuredLeftSign;
    if (configured != null) return challenge == FaceChallenge.left ? configured : -configured;
    final other = challenge == FaceChallenge.left ? _rightSign : _leftSign;
    return other == null ? null : -other;
  }

  _Verdict _evaluate(List<FacePose> faces) {
    if (faces.isEmpty) return const _Verdict(PoseFeedback.noFace);
    if (faces.length > 1) return const _Verdict(PoseFeedback.multipleFaces);

    final face = faces.single;
    final frame = face.frameSize;
    if (face.box.width / frame.width < thresholds.minFaceWidthRatio) {
      return const _Verdict(PoseFeedback.tooSmall);
    }
    final Offset centre = face.box.center;
    if ((centre.dx / frame.width - 0.5).abs() > thresholds.maxCenterOffset ||
        (centre.dy / frame.height - 0.5).abs() > thresholds.maxCenterOffset) {
      return const _Verdict(PoseFeedback.offCenter);
    }

    final yaw = face.yawDegrees;
    if (current == FaceChallenge.front) {
      return yaw.abs() < thresholds.frontMaxYaw
          ? _Verdict(PoseFeedback.holding, accepted: true, yaw: yaw)
          : const _Verdict(PoseFeedback.lookStraight);
    }

    final required = _requiredSign(current);
    if (required != null && yaw.sign.toInt() != required && yaw.abs() > thresholds.frontMaxYaw) {
      return const _Verdict(PoseFeedback.turnOtherWay);
    }
    if (yaw.abs() > thresholds.lateralMaxYaw) return const _Verdict(PoseFeedback.turnLess);
    if (yaw.abs() <= thresholds.lateralMinYaw) return const _Verdict(PoseFeedback.turnMore);
    if (required != null && yaw.sign.toInt() != required) {
      return const _Verdict(PoseFeedback.turnOtherWay);
    }
    return _Verdict(PoseFeedback.holding, accepted: true, yaw: yaw);
  }
}

class _Verdict {
  const _Verdict(this.feedback, {this.accepted = false, this.yaw});

  final PoseFeedback feedback;
  final bool accepted;
  final double? yaw;
}
