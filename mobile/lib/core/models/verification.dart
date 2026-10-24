import 'dart:typed_data';

// Verification models. CONTRACT: docs/verification/CONTRAT.md (backend).
// Reason codes are kept as the raw server strings and translated in the UI.

enum FaceChallenge { front, left, right }

FaceChallenge faceChallengeFromJson(String value) => switch (value) {
      'front' => FaceChallenge.front,
      'left' => FaceChallenge.left,
      'right' => FaceChallenge.right,
      _ => throw FormatException('unknown challenge: $value'),
    };

enum FacePurpose { photo, identity }

class FaceSession {
  final String sessionId;
  final List<FaceChallenge> challenges;
  final DateTime expiresAt;

  const FaceSession({required this.sessionId, required this.challenges, required this.expiresAt});

  factory FaceSession.fromJson(Map<String, dynamic> json) => FaceSession(
        sessionId: json['session_id'] as String,
        challenges: (json['challenges'] as List<dynamic>).map((c) => faceChallengeFromJson(c as String)).toList(),
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

/// Outcome of a selfie or identity submission. [reason] is a server code
/// (`no_face`, `pose_mismatch`, `document_expired`...) when [verified] is false.
class VerificationOutcome {
  final bool verified;
  final String? reason;

  /// Per profile photo comparison, only present on a successful level 1 selfie.
  final List<PhotoMatch> photoMatches;

  const VerificationOutcome({required this.verified, this.reason, this.photoMatches = const []});

  factory VerificationOutcome.fromJson(Map<String, dynamic> json) => VerificationOutcome(
        verified: json['verified'] == true,
        reason: json['reason'] as String?,
        photoMatches: (json['photo_matches'] as List<dynamic>? ?? const [])
            .map((m) => PhotoMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

/// Whether one profile photo shows the person who took the live selfie.
class PhotoMatch {
  final int photoId;
  final bool match;

  const PhotoMatch({required this.photoId, required this.match});

  factory PhotoMatch.fromJson(Map<String, dynamic> json) => PhotoMatch(
        photoId: (json['photo_id'] as num).toInt(),
        match: json['match'] == true,
      );
}

class VerificationStep {
  final bool verified;
  final DateTime? verifiedAt;
  final int attemptsToday;

  const VerificationStep({required this.verified, this.verifiedAt, this.attemptsToday = 0});

  factory VerificationStep.fromJson(Map<String, dynamic>? json) => VerificationStep(
        verified: json?['verified'] == true,
        verifiedAt: json?['verified_at'] == null ? null : DateTime.parse(json!['verified_at'] as String),
        attemptsToday: (json?['attempts_today'] as num?)?.toInt() ?? 0,
      );
}

class VerificationStatus {
  final VerificationStep photo;
  final VerificationStep identity;

  /// `none`, `photo` or `identity`.
  final String level;

  /// Legacy flags, still sent by the server: any level counts.
  final bool isVerified;

  /// Set when the daily attempt quota is used up.
  final DateTime? nextAttemptTime;

  const VerificationStatus({
    required this.photo,
    required this.identity,
    required this.level,
    this.isVerified = false,
    this.nextAttemptTime,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) => VerificationStatus(
        photo: VerificationStep.fromJson(json['photo'] as Map<String, dynamic>?),
        identity: VerificationStep.fromJson(json['identity'] as Map<String, dynamic>?),
        level: json['level'] as String? ?? 'none',
        isVerified: json['is_verified'] == true,
        nextAttemptTime:
            json['next_attempt_time'] == null ? null : DateTime.tryParse(json['next_attempt_time'] as String),
      );
}

/// Raw elementary files read from the document chip, sent as-is to the server.
/// Never written to disk, never logged.
class ChipReadResult {
  final Uint8List dg1;
  final Uint8List dg2;
  final Uint8List sod;

  const ChipReadResult({required this.dg1, required this.dg2, required this.sod});
}
