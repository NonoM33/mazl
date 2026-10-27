// Models of the couple mode (requests, couple, milestones, questions).
// Decoding of the server shapes follows docs/couple/CONTRAT.md §1 and §2.

/// Couple request status
enum CoupleRequestStatus {
  none,
  pending,    // Request sent, waiting for response
  received,   // Request received from someone else
  accepted,
  rejected,
}

/// A couple request, as rendered by the server (contract §2).
///
/// Two shapes exist: the one RECEIVED (`requester_name`, `requester_picture`)
/// and the one SENT (`target_name`, `target_picture`); the response of
/// `POST /api/couple/request` is wrapped in `{ request: ... }`.
class CoupleRequest {
  final int id;
  final int requesterId;
  final String requesterName;
  final String? requesterPicture;
  final int targetId;
  final String? targetName;
  final String? targetPicture;
  final CoupleRequestStatus status;
  final DateTime? createdAt;

  const CoupleRequest({
    required this.id,
    required this.requesterId,
    this.requesterName = '',
    this.requesterPicture,
    required this.targetId,
    this.targetName,
    this.targetPicture,
    this.status = CoupleRequestStatus.pending,
    this.createdAt,
  });

  /// The shape [CoupleRequest.fromJson] reads back (local cache).
  Map<String, dynamic> toJson() => {
        'id': id,
        'requester_id': requesterId,
        'requester_name': requesterName,
        'requester_picture': requesterPicture,
        'target_id': targetId,
        'target_name': targetName,
        'target_picture': targetPicture,
        'status': status.name,
        'created_at': createdAt?.toIso8601String(),
      };

  factory CoupleRequest.fromJson(Map<String, dynamic> json) {
    return CoupleRequest(
      id: parseCoupleId(json['id']) ?? 0,
      requesterId: parseCoupleId(json['requester_id']) ?? 0,
      requesterName: json['requester_name'] as String? ?? '',
      requesterPicture: json['requester_picture'] as String?,
      targetId: parseCoupleId(json['target_id']) ?? 0,
      targetName: json['target_name'] as String?,
      targetPicture: json['target_picture'] as String?,
      status: CoupleRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CoupleRequestStatus.pending,
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// Parses an id that may arrive as an int, a number or a numeric string.
int? parseCoupleId(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Relationship status for the user
enum RelationshipStatus {
  single,
  dating,
  inRelationship,
  engaged,
  married,
}

extension RelationshipStatusExtension on RelationshipStatus {
  String get emoji {
    switch (this) {
      case RelationshipStatus.single:
        return '';
      case RelationshipStatus.dating:
        return '';
      case RelationshipStatus.inRelationship:
        return '';
      case RelationshipStatus.engaged:
        return '';
      case RelationshipStatus.married:
        return '';
    }
  }

  /// The value `PATCH /api/couple/:id/status` accepts, `null` for a status a
  /// couple cannot have (`single`).
  String? get serverValue => switch (this) {
    RelationshipStatus.single => null,
    RelationshipStatus.dating => 'dating',
    RelationshipStatus.inRelationship => 'in_relationship',
    RelationshipStatus.engaged => 'engaged',
    RelationshipStatus.married => 'married',
  };

  bool get isInCouple {
    return this == RelationshipStatus.inRelationship ||
        this == RelationshipStatus.engaged ||
        this == RelationshipStatus.married;
  }
}

/// Model for couple data
class CoupleData {
  /// Backend couple row id (required to end the couple via DELETE /api/couple/:coupleId).
  final int? coupleId;
  final int? partnerId;
  final String? partnerName;
  final String? partnerPicture;
  final DateTime? relationshipStartDate;
  final DateTime? metOnMazlDate;
  final RelationshipStatus status;
  final int daysTogetherStreak;
  final List<CoupleMilestone> milestones;

  CoupleData({
    this.coupleId,
    this.partnerId,
    this.partnerName,
    this.partnerPicture,
    this.relationshipStartDate,
    this.metOnMazlDate,
    this.status = RelationshipStatus.single,
    this.daysTogetherStreak = 0,
    this.milestones = const [],
  });

  /// Decodes the couple as the SERVER renders it (contract §1), seen from the
  /// caller: `GET /api/couple`, the acceptance response and `couple:accepted`.
  factory CoupleData.fromServer(Map<String, dynamic> json) => CoupleData(
        coupleId: parseCoupleId(json['id']),
        partnerId: parseCoupleId(json['partner_id']),
        partnerName: json['partner_name'] as String?,
        partnerPicture: json['partner_picture'] as String?,
        relationshipStartDate:
            DateTime.tryParse(json['started_at']?.toString() ?? ''),
        metOnMazlDate:
            DateTime.tryParse(json['met_on_mazl_at']?.toString() ?? ''),
        status: _statusFromServer(json['status']),
      );

  static RelationshipStatus _statusFromServer(dynamic raw) {
    switch (raw) {
      case 'dating':
        return RelationshipStatus.dating;
      case 'engaged':
        return RelationshipStatus.engaged;
      case 'married':
        return RelationshipStatus.married;
      default:
        return RelationshipStatus.inRelationship;
    }
  }

  int get daysTogether {
    if (relationshipStartDate == null) return 0;
    return DateTime.now().difference(relationshipStartDate!).inDays;
  }

  Map<String, dynamic> toJson() => {
        'coupleId': coupleId,
        'partnerId': partnerId,
        'partnerName': partnerName,
        'partnerPicture': partnerPicture,
        'relationshipStartDate': relationshipStartDate?.toIso8601String(),
        'metOnMazlDate': metOnMazlDate?.toIso8601String(),
        'status': status.index,
        'daysTogetherStreak': daysTogetherStreak,
      };

  factory CoupleData.fromJson(Map<String, dynamic> json) => CoupleData(
        coupleId: json['coupleId'],
        partnerId: json['partnerId'],
        partnerName: json['partnerName'],
        partnerPicture: json['partnerPicture'],
        relationshipStartDate: json['relationshipStartDate'] != null
            ? DateTime.parse(json['relationshipStartDate'])
            : null,
        metOnMazlDate: json['metOnMazlDate'] != null
            ? DateTime.parse(json['metOnMazlDate'])
            : null,
        status: RelationshipStatus.values[json['status'] ?? 0],
        daysTogetherStreak: json['daysTogetherStreak'] ?? 0,
      );
}

/// Model for couple milestones
class CoupleMilestone {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime? achievedAt;
  final bool isAchieved;

  CoupleMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    this.achievedAt,
    this.isAchieved = false,
  });
}

/// Daily question for couples
class DailyQuestion {
  final String id;
  final String question;
  final String category;
  final List<String>? options;
  final bool isAnswered;
  final String? myAnswer;
  final String? partnerAnswer;

  DailyQuestion({
    required this.id,
    required this.question,
    required this.category,
    this.options,
    this.isAnswered = false,
    this.myAnswer,
    this.partnerAnswer,
  });
}
