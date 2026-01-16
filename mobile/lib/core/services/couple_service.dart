import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Couple request status
enum CoupleRequestStatus {
  none,
  pending,    // Request sent, waiting for response
  received,   // Request received from someone else
  accepted,
  rejected,
}

/// Couple request model
class CoupleRequest {
  final int id;
  final int requesterId;
  final String requesterName;
  final String? requesterPicture;
  final int targetId;
  final CoupleRequestStatus status;
  final DateTime createdAt;

  CoupleRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPicture,
    required this.targetId,
    required this.status,
    required this.createdAt,
  });

  factory CoupleRequest.fromJson(Map<String, dynamic> json) {
    return CoupleRequest(
      id: json['id'] as int,
      requesterId: json['requester_id'] as int,
      requesterName: json['requester_name'] as String? ?? 'Utilisateur',
      requesterPicture: json['requester_picture'] as String?,
      targetId: json['target_id'] as int,
      status: CoupleRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CoupleRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
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
  String get displayName {
    switch (this) {
      case RelationshipStatus.single:
        return 'Celibataire';
      case RelationshipStatus.dating:
        return 'En train de dater';
      case RelationshipStatus.inRelationship:
        return 'En couple';
      case RelationshipStatus.engaged:
        return 'Fiance(e)';
      case RelationshipStatus.married:
        return 'Marie(e)';
    }
  }

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

  bool get isInCouple {
    return this == RelationshipStatus.inRelationship ||
        this == RelationshipStatus.engaged ||
        this == RelationshipStatus.married;
  }
}

/// Model for couple data
class CoupleData {
  final int? partnerId;
  final String? partnerName;
  final String? partnerPicture;
  final DateTime? relationshipStartDate;
  final DateTime? metOnMazlDate;
  final RelationshipStatus status;
  final int daysTogetherStreak;
  final List<CoupleMilestone> milestones;

  CoupleData({
    this.partnerId,
    this.partnerName,
    this.partnerPicture,
    this.relationshipStartDate,
    this.metOnMazlDate,
    this.status = RelationshipStatus.single,
    this.daysTogetherStreak = 0,
    this.milestones = const [],
  });

  int get daysTogether {
    if (relationshipStartDate == null) return 0;
    return DateTime.now().difference(relationshipStartDate!).inDays;
  }

  Map<String, dynamic> toJson() => {
        'partnerId': partnerId,
        'partnerName': partnerName,
        'partnerPicture': partnerPicture,
        'relationshipStartDate': relationshipStartDate?.toIso8601String(),
        'metOnMazlDate': metOnMazlDate?.toIso8601String(),
        'status': status.index,
        'daysTogetherStreak': daysTogetherStreak,
      };

  factory CoupleData.fromJson(Map<String, dynamic> json) => CoupleData(
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

/// Service to manage couple mode
class CoupleService {
  static final CoupleService _instance = CoupleService._internal();
  factory CoupleService() => _instance;
  CoupleService._internal();

  static const _coupleDataKey = 'couple_data';
  static const _coupleModeEnabledKey = 'couple_mode_enabled';

  final ApiService _apiService = ApiService();
  CoupleData? _coupleData;
  bool _isCoupleModeEnabled = false;

  bool get isCoupleModeEnabled => _isCoupleModeEnabled;
  CoupleData? get coupleData => _coupleData;
  bool get hasPartner => _coupleData?.partnerId != null;

  /// Initialize the service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isCoupleModeEnabled = prefs.getBool(_coupleModeEnabledKey) ?? false;

    final coupleDataJson = prefs.getString(_coupleDataKey);
    if (coupleDataJson != null) {
      try {
        _coupleData = CoupleData.fromJson(jsonDecode(coupleDataJson));
      } catch (e) {
        _coupleData = null;
      }
    }
  }

  /// Enable couple mode
  Future<void> enableCoupleMode({
    required int partnerId,
    required String partnerName,
    String? partnerPicture,
    DateTime? relationshipStartDate,
  }) async {
    _coupleData = CoupleData(
      partnerId: partnerId,
      partnerName: partnerName,
      partnerPicture: partnerPicture,
      relationshipStartDate: relationshipStartDate ?? DateTime.now(),
      metOnMazlDate: DateTime.now(),
      status: RelationshipStatus.inRelationship,
    );
    _isCoupleModeEnabled = true;

    await _saveData();

    // Notify backend
    // await _apiService.enableCoupleMode(partnerId);
  }

  /// Disable couple mode
  Future<void> disableCoupleMode() async {
    _isCoupleModeEnabled = false;
    _coupleData = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coupleDataKey);
    await prefs.setBool(_coupleModeEnabledKey, false);
  }

  /// Update relationship status
  Future<void> updateStatus(RelationshipStatus status) async {
    if (_coupleData != null) {
      _coupleData = CoupleData(
        partnerId: _coupleData!.partnerId,
        partnerName: _coupleData!.partnerName,
        partnerPicture: _coupleData!.partnerPicture,
        relationshipStartDate: _coupleData!.relationshipStartDate,
        metOnMazlDate: _coupleData!.metOnMazlDate,
        status: status,
        daysTogetherStreak: _coupleData!.daysTogetherStreak,
      );
      await _saveData();
    }
  }

  /// Save data to preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coupleModeEnabledKey, _isCoupleModeEnabled);
    if (_coupleData != null) {
      await prefs.setString(_coupleDataKey, jsonEncode(_coupleData!.toJson()));
    }
  }

  /// Get daily questions for couple
  List<DailyQuestion> getDailyQuestions() {
    return [
      DailyQuestion(
        id: '1',
        question: 'Quel est ton moment prefere de la semaine ensemble ?',
        category: 'Connection',
      ),
      DailyQuestion(
        id: '2',
        question: 'Si on pouvait voyager n\'importe ou, ou irais-tu ?',
        category: 'Reves',
      ),
      DailyQuestion(
        id: '3',
        question: 'Qu\'est-ce qui t\'a fait sourire aujourd\'hui ?',
        category: 'Quotidien',
      ),
      DailyQuestion(
        id: '4',
        question: 'Comment aimerais-tu celebrer notre prochain Shabbat ?',
        category: 'Judaisme',
        options: [
          'Diner romantique a la maison',
          'Invitation chez des amis',
          'Restaurant cacher',
          'Shabbaton communautaire',
        ],
      ),
      DailyQuestion(
        id: '5',
        question: 'Quel trait de caractere admires-tu le plus chez moi ?',
        category: 'Appreciation',
      ),
    ];
  }

  /// Get milestones
  List<CoupleMilestone> getMilestones() {
    final daysTogether = _coupleData?.daysTogether ?? 0;

    return [
      CoupleMilestone(
        id: 'first_week',
        title: 'Premiere semaine',
        description: '7 jours ensemble',
        emoji: '',
        isAchieved: daysTogether >= 7,
        achievedAt: daysTogether >= 7
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 7))
            : null,
      ),
      CoupleMilestone(
        id: 'first_month',
        title: 'Premier mois',
        description: '30 jours d\'amour',
        emoji: '',
        isAchieved: daysTogether >= 30,
        achievedAt: daysTogether >= 30
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 30))
            : null,
      ),
      CoupleMilestone(
        id: 'three_months',
        title: 'Trimestre',
        description: '3 mois de bonheur',
        emoji: '',
        isAchieved: daysTogether >= 90,
        achievedAt: daysTogether >= 90
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 90))
            : null,
      ),
      CoupleMilestone(
        id: 'six_months',
        title: 'Mi-annee',
        description: '6 mois main dans la main',
        emoji: '',
        isAchieved: daysTogether >= 180,
        achievedAt: daysTogether >= 180
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 180))
            : null,
      ),
      CoupleMilestone(
        id: 'first_year',
        title: 'Premiere annee',
        description: '365 jours de Mazl',
        emoji: '',
        isAchieved: daysTogether >= 365,
        achievedAt: daysTogether >= 365
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 365))
            : null,
      ),
    ];
  }

  /// Get couple activities suggestions
  List<Map<String, dynamic>> getCoupleActivities() {
    return [
      {
        'title': 'Cuisine Shabbat',
        'description': 'Preparez le repas de Shabbat ensemble',
        'icon': 'utensils',
        'category': 'Maison',
      },
      {
        'title': 'Etude Torah',
        'description': 'Apprenez la Paracha ensemble',
        'icon': 'book',
        'category': 'Spirituel',
      },
      {
        'title': 'Date night',
        'description': 'Sortie restaurant ou cinema',
        'icon': 'heart',
        'category': 'Romance',
      },
      {
        'title': 'Sport ensemble',
        'description': 'Course, yoga, randonnee...',
        'icon': 'dumbbell',
        'category': 'Bien-etre',
      },
      {
        'title': 'Hesed ensemble',
        'description': 'Action caritative en couple',
        'icon': 'hand-heart',
        'category': 'Communaute',
      },
      {
        'title': 'Voyage',
        'description': 'Planifiez votre prochaine escapade',
        'icon': 'plane',
        'category': 'Aventure',
      },
    ];
  }

  // ===== COUPLE REQUEST SYSTEM =====

  CoupleRequest? _pendingRequest;
  CoupleRequest? _receivedRequest;

  CoupleRequest? get pendingRequest => _pendingRequest;
  CoupleRequest? get receivedRequest => _receivedRequest;

  /// Check if there's a pending request with a specific user
  CoupleRequestStatus getRequestStatusWithUser(int userId) {
    if (_pendingRequest != null && _pendingRequest!.targetId == userId) {
      return CoupleRequestStatus.pending;
    }
    if (_receivedRequest != null && _receivedRequest!.requesterId == userId) {
      return CoupleRequestStatus.received;
    }
    return CoupleRequestStatus.none;
  }

  /// Send a couple mode request to a match
  Future<bool> sendCoupleRequest({
    required int targetUserId,
    required String targetName,
    String? targetPicture,
  }) async {
    try {
      // Call API to send request
      final response = await _apiService.sendCoupleRequest(targetUserId);

      if (response.success) {
        _pendingRequest = CoupleRequest(
          id: response.data?['id'] ?? 0,
          requesterId: 0, // Will be filled by backend
          requesterName: '',
          targetId: targetUserId,
          status: CoupleRequestStatus.pending,
          createdAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CoupleService: Error sending couple request: $e');
      return false;
    }
  }

  /// Accept a couple request
  Future<bool> acceptCoupleRequest(CoupleRequest request) async {
    try {
      final response = await _apiService.respondToCoupleRequest(
        requestId: request.id,
        accept: true,
      );

      if (response.success) {
        // Enable couple mode with the requester
        await enableCoupleMode(
          partnerId: request.requesterId,
          partnerName: request.requesterName,
          partnerPicture: request.requesterPicture,
        );
        _receivedRequest = null;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CoupleService: Error accepting couple request: $e');
      return false;
    }
  }

  /// Reject a couple request
  Future<bool> rejectCoupleRequest(CoupleRequest request) async {
    try {
      final response = await _apiService.respondToCoupleRequest(
        requestId: request.id,
        accept: false,
      );

      if (response.success) {
        _receivedRequest = null;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CoupleService: Error rejecting couple request: $e');
      return false;
    }
  }

  /// Cancel a pending request
  Future<bool> cancelCoupleRequest() async {
    if (_pendingRequest == null) return false;

    try {
      final response = await _apiService.cancelCoupleRequest(_pendingRequest!.id);

      if (response.success) {
        _pendingRequest = null;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CoupleService: Error cancelling couple request: $e');
      return false;
    }
  }

  /// Fetch pending requests (sent and received)
  Future<void> fetchPendingRequests() async {
    try {
      final response = await _apiService.getCoupleRequests();

      if (response.success && response.data != null) {
        final sent = response.data!['sent'] as List<dynamic>?;
        final received = response.data!['received'] as List<dynamic>?;

        if (sent != null && sent.isNotEmpty) {
          _pendingRequest = CoupleRequest.fromJson(sent.first);
        } else {
          _pendingRequest = null;
        }

        if (received != null && received.isNotEmpty) {
          _receivedRequest = CoupleRequest.fromJson(received.first);
        } else {
          _receivedRequest = null;
        }
      }
    } catch (e) {
      debugPrint('CoupleService: Error fetching couple requests: $e');
    }
  }

  /// Archive all other conversations when entering couple mode
  Future<void> archiveOtherConversations() async {
    try {
      await _apiService.archiveAllConversationsExcept(
        _coupleData?.partnerId ?? 0,
        message: "J'ai trouve l'amour sur Mazl! Je ne suis plus disponible. Bonne chance dans ta recherche!",
      );
    } catch (e) {
      debugPrint('CoupleService: Error archiving conversations: $e');
    }
  }
}
