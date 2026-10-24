import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../models/verification.dart';
import 'api_service.dart';

export '../models/verification.dart';

/// Verification endpoints (levels 1 and 2). CONTRACT: docs/verification/CONTRAT.md.
/// [HttpVerificationApi] is the real implementation; tests use fakes.
abstract class VerificationApi {
  /// `POST /api/verification/face/session`. A 429 maps to a failure whose
  /// error is `daily_limit_reached`.
  Future<ApiResponse<FaceSession>> startFaceSession(FacePurpose purpose);

  /// `POST /api/verification/face/submit`, one JPEG per challenge, in order.
  Future<ApiResponse<VerificationOutcome>> submitFace(String sessionId, List<Uint8List> frames);

  /// `POST /api/verification/identity`: live frames plus the chip files.
  Future<ApiResponse<VerificationOutcome>> submitIdentity(
    String sessionId,
    List<Uint8List> frames,
    ChipReadResult chip,
  );

  /// `GET /api/verification/status`.
  Future<ApiResponse<VerificationStatus>> getStatus();

  /// `DELETE /api/verification/face/reference`: withdraws biometric consent
  /// (deletes the stored face reference and removes the photo badge).
  Future<ApiResponse<void>> deleteFaceReference();
}

/// Guided live capture: shows the camera, asks for each [challenges] pose in
/// turn, checks it on-device (ML Kit) and returns one JPEG per challenge, or
/// null if the user cancelled. The server re-checks everything.
abstract class LivenessCapture {
  Future<List<Uint8List>?> capture(BuildContext context, List<FaceChallenge> challenges);
}
