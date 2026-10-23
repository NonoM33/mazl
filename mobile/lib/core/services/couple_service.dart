import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/couple_models.dart';
import 'api_service.dart' hide CoupleMilestone;
import 'couple_api.dart';
import 'couple_messages.dart';

export '../models/couple_models.dart';
export 'couple_messages.dart' show CoupleResult;

/// What the couple flow tells the rest of the app (screens subscribe through
/// the host widget, never through the service's internals).
sealed class CoupleFlowEvent {
  const CoupleFlowEvent();
}

/// A couple was just formed. [asRequester] is true for the member who sent the
/// request (the acceptor sees the celebration from the dialog itself).
class CoupleFormed extends CoupleFlowEvent {
  const CoupleFormed(this.couple, {required this.asRequester});
  final CoupleData couple;
  final bool asRequester;
}

/// Somebody asked this member to activate the couple mode.
class CoupleRequestReceived extends CoupleFlowEvent {
  const CoupleRequestReceived(this.request);
  final CoupleRequest request;
}

/// The request this member sent is no longer pending and no couple came out of it.
class CoupleRequestDeclined extends CoupleFlowEvent {
  const CoupleRequestDeclined({this.partnerName});
  final String? partnerName;
}

/// The other member ended the couple.
class CoupleEnded extends CoupleFlowEvent {
  const CoupleEnded({this.partnerName});
  final String? partnerName;
}

/// How this member relates to another member, for a profile screen.
enum CoupleRelation {
  none,
  requestSent,
  requestReceived,
  partner,
  coupleWithSomeoneElse,
}

/// Service to manage couple mode.
///
/// The server is the truth (contract §0.3): everything held here is a cache
/// that [refresh] re-aligns on `GET /api/couple` and `GET /api/couple/requests`.
class CoupleService extends ChangeNotifier {
  static CoupleService _instance = CoupleService._internal();
  factory CoupleService() => _instance;

  /// Swaps the application-wide instance (tests only).
  @visibleForTesting
  static set instanceForTesting(CoupleService service) => _instance = service;
  CoupleService._internal()
      : _api = ApiService(),
        _pollInterval = const Duration(seconds: 10);

  /// A service wired to a fake [CoupleApi]; never use it in production code.
  @visibleForTesting
  CoupleService.forTesting({
    required CoupleApi api,
    Duration pollInterval = const Duration(seconds: 10),
  })  : _api = api,
        _pollInterval = pollInterval;

  static const _coupleDataKey = 'couple_data';
  static const _coupleModeEnabledKey = 'couple_mode_enabled';
  static const _pendingRequestKey = 'couple_pending_request';
  static const _archiveMessage =
      "J'ai trouvé l'amour sur Mazl. Je ne suis plus disponible. Bonne chance dans votre recherche.";

  final CoupleApi _api;
  final Duration _pollInterval;
  final StreamController<CoupleFlowEvent> _events =
      StreamController<CoupleFlowEvent>.broadcast();

  CoupleData? _coupleData;
  bool _isCoupleModeEnabled = false;
  CoupleRequest? _pendingRequest;
  CoupleRequest? _receivedRequest;
  bool _isForeground = true;
  Timer? _pollTimer;
  Future<void>? _refreshing;

  Stream<CoupleFlowEvent> get events => _events.stream;
  bool get isCoupleModeEnabled => _isCoupleModeEnabled;
  CoupleData? get coupleData => _coupleData;
  bool get hasPartner => _coupleData?.partnerId != null;

  /// The request this member sent and that nobody answered yet.
  CoupleRequest? get pendingRequest => _pendingRequest;

  /// The request somebody sent to this member and that is still unanswered.
  CoupleRequest? get receivedRequest => _receivedRequest;

  /// Whether the 10 s re-read is running (only while a request is pending and
  /// the app is in the foreground).
  bool get isPolling => _pollTimer != null;

  // ===== Lifecycle =====

  /// Loads the cache for a fast start, then aligns it on the server.
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
    final pendingJson = prefs.getString(_pendingRequestKey);
    if (pendingJson != null) {
      try {
        _pendingRequest =
            CoupleRequest.fromJson(jsonDecode(pendingJson) as Map<String, dynamic>);
      } catch (e) {
        _pendingRequest = null;
      }
    }
    notifyListeners();

    await refresh();
  }

  /// Forgets everything (sign-out): another member may sign in next.
  Future<void> reset() async {
    _stopPolling();
    _isCoupleModeEnabled = false;
    _coupleData = null;
    _pendingRequest = null;
    _receivedRequest = null;
    await _clearData();
    notifyListeners();
  }

  void onPaused() {
    _isForeground = false;
    _updatePolling();
  }

  /// Back in the foreground: re-align on the server right away (contract §3).
  Future<void> onResumed() async {
    _isForeground = true;
    await refresh();
  }

  // ===== Server alignment =====

  /// Re-reads the couple then the requests. Calls overlap safely: a second
  /// call while one is in flight waits for that one.
  Future<void> refresh() {
    return _refreshing ??= _refreshOnce().whenComplete(() => _refreshing = null);
  }

  Future<void> _refreshOnce() async {
    final inCouple = await _syncCouple();
    await _syncRequests(coupleKnown: inCouple != null);
    _updatePolling();
  }

  /// Returns whether the server says "in a couple", or null when unknown
  /// (network error: the local state is kept, never silently disabled).
  Future<bool?> _syncCouple() async {
    try {
      final response = await _api.getCoupleData();
      if (!response.success || response.data == null) return null;

      final raw = response.data!['couple'];
      if (raw is Map<String, dynamic>) {
        final couple = CoupleData.fromServer(raw);
        final formedFromMyRequest = !_isCoupleModeEnabled && _pendingRequest != null;
        await _enterCouple(couple);
        if (formedFromMyRequest) {
          await _archiveOtherConversations();
          _events.add(CoupleFormed(couple, asRequester: true));
        }
        return true;
      }

      if (_isCoupleModeEnabled || _coupleData != null) {
        final partnerName = _coupleData?.partnerName;
        await _leaveLocally();
        _events.add(CoupleEnded(partnerName: partnerName));
      }
      return false;
    } catch (e) {
      debugPrint('CoupleService: sync of the couple failed: $e');
      return null;
    }
  }

  Future<void> _syncRequests({required bool coupleKnown}) async {
    try {
      final response = await _api.getCoupleRequests();
      if (!response.success || response.data == null) return;

      if (_isCoupleModeEnabled) {
        await _setRequests(pending: null, received: null);
        return;
      }

      final sent = response.data!['sent'];
      final received = response.data!['received'];
      final pending = sent is List && sent.isNotEmpty
          ? CoupleRequest.fromJson(sent.first as Map<String, dynamic>)
          : null;
      final incoming = received is List && received.isNotEmpty
          ? CoupleRequest.fromJson(received.first as Map<String, dynamic>)
          : null;

      final previousPending = _pendingRequest;
      final previousIncomingId = _receivedRequest?.id;
      await _setRequests(pending: pending, received: incoming);

      if (pending == null && previousPending != null && coupleKnown) {
        _events.add(CoupleRequestDeclined(partnerName: previousPending.targetName));
      }
      if (incoming != null && incoming.id != previousIncomingId) {
        _events.add(CoupleRequestReceived(incoming));
      }
    } catch (e) {
      debugPrint('CoupleService: sync of the requests failed: $e');
    }
  }

  // ===== Actions =====

  /// Sends a couple request to a match. Nothing is pending on failure.
  Future<CoupleResult> sendCoupleRequest({
    required int targetUserId,
    required String targetName,
    String? targetPicture,
  }) async {
    final response = await _api.sendCoupleRequest(targetUserId);
    if (!response.success) {
      return CoupleResult.failure(
        coupleErrorMessage(response.error, response.errorKind),
      );
    }

    // Contract §2: the request is wrapped in `{ request: {...} }`.
    final raw = response.data?['request'];
    if (raw is! Map<String, dynamic>) {
      await refresh();
      return _pendingRequest != null
          ? const CoupleResult.ok()
          : const CoupleResult.failure(
              'Une erreur est survenue, réessayez dans un instant.');
    }

    final sent = CoupleRequest.fromJson(raw);
    await _setRequests(
      pending: CoupleRequest(
        id: sent.id,
        requesterId: sent.requesterId,
        targetId: sent.targetId == 0 ? targetUserId : sent.targetId,
        targetName: sent.targetName ?? targetName,
        targetPicture: sent.targetPicture ?? targetPicture,
        status: CoupleRequestStatus.pending,
        createdAt: sent.createdAt,
      ),
      received: _receivedRequest,
    );
    _updatePolling();
    return const CoupleResult.ok();
  }

  /// Cancels the request this member sent, using its real server id.
  Future<CoupleResult> cancelCoupleRequest() async {
    final pending = _pendingRequest;
    if (pending == null) return const CoupleResult.ok();

    final response = await _api.cancelCoupleRequest(pending.id);
    if (!response.success) {
      // It may have been answered meanwhile: re-align before reporting.
      await refresh();
      return CoupleResult.failure(
        coupleErrorMessage(response.error, response.errorKind),
      );
    }
    await _setRequests(pending: null, received: _receivedRequest);
    _updatePolling();
    return const CoupleResult.ok();
  }

  /// Accepts a received request. The couple comes from the response itself
  /// (no second call), then the other conversations are archived.
  Future<CoupleResult> acceptCoupleRequest(CoupleRequest request) async {
    final response = await _api.respondToCoupleRequest(
      requestId: request.id,
      accept: true,
    );
    if (!response.success) {
      await refresh();
      return CoupleResult.failure(
        coupleErrorMessage(response.error, response.errorKind),
      );
    }

    final raw = response.data?['couple'];
    if (raw is! Map<String, dynamic>) {
      await refresh();
      return _isCoupleModeEnabled
          ? const CoupleResult.ok()
          : const CoupleResult.failure(
              'Une erreur est survenue, réessayez dans un instant.');
    }

    final couple = CoupleData.fromServer(raw);
    await _enterCouple(couple);
    await _archiveOtherConversations();
    _events.add(CoupleFormed(couple, asRequester: false));
    return const CoupleResult.ok();
  }

  /// Declines a received request.
  Future<CoupleResult> rejectCoupleRequest(CoupleRequest request) async {
    final response = await _api.respondToCoupleRequest(
      requestId: request.id,
      accept: false,
    );
    if (!response.success) {
      await refresh();
      return CoupleResult.failure(
        coupleErrorMessage(response.error, response.errorKind),
      );
    }
    await _setRequests(pending: _pendingRequest, received: null);
    return const CoupleResult.ok();
  }

  /// Ends the couple for both members. Awaits the server: on failure nothing
  /// changes locally.
  Future<CoupleResult> leaveCouple() async {
    final coupleId = _coupleData?.coupleId;
    if (coupleId == null) {
      return const CoupleResult.failure(
        'Impossible de quitter le mode couple pour le moment.',
      );
    }
    final response = await _api.endCouple(coupleId);
    if (!response.success) {
      return CoupleResult.failure(
        coupleErrorMessage(response.error, response.errorKind),
      );
    }
    await _leaveLocally();
    return const CoupleResult.ok();
  }

  // ===== Real time (contract §3): an accelerator, the sync stays the truth =====

  /// Applies a `couple:*` WebSocket message.
  Future<void> handleRealtime(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case 'couple:request':
        final raw = payload['request'];
        if (raw is! Map<String, dynamic> || _isCoupleModeEnabled) return;
        final incoming = CoupleRequest.fromJson(raw);
        final isNew = incoming.id != _receivedRequest?.id;
        await _setRequests(pending: _pendingRequest, received: incoming);
        if (isNew) _events.add(CoupleRequestReceived(incoming));
      case 'couple:accepted':
        final raw = payload['couple'];
        if (raw is! Map<String, dynamic>) {
          await refresh();
          return;
        }
        final couple = CoupleData.fromServer(raw);
        if (_isCoupleModeEnabled && _coupleData?.coupleId == couple.coupleId) return;
        await _enterCouple(couple);
        await _archiveOtherConversations();
        _events.add(CoupleFormed(couple, asRequester: true));
      case 'couple:rejected':
        final pending = _pendingRequest;
        if (pending == null) return;
        final id = parseCoupleId(payload['request_id']);
        if (id != null && id != pending.id) return;
        await _setRequests(pending: null, received: _receivedRequest);
        _updatePolling();
        _events.add(CoupleRequestDeclined(partnerName: pending.targetName));
      case 'couple:ended':
        if (!_isCoupleModeEnabled) return;
        final id = parseCoupleId(payload['couple_id']);
        final current = _coupleData?.coupleId;
        if (id != null && current != null && id != current) return;
        final partnerName = _coupleData?.partnerName;
        await _leaveLocally();
        _events.add(CoupleEnded(partnerName: partnerName));
    }
  }

  // ===== Per-member state =====

  /// How this member relates to [userId] (profile of a match).
  CoupleRelation relationWithUser(int userId) {
    if (_isCoupleModeEnabled) {
      return _coupleData?.partnerId == userId
          ? CoupleRelation.partner
          : CoupleRelation.coupleWithSomeoneElse;
    }
    if (_pendingRequest?.targetId == userId) return CoupleRelation.requestSent;
    if (_receivedRequest?.requesterId == userId) return CoupleRelation.requestReceived;
    return CoupleRelation.none;
  }

  /// Check if there's a pending request with a specific user
  CoupleRequestStatus getRequestStatusWithUser(int userId) {
    switch (relationWithUser(userId)) {
      case CoupleRelation.requestSent:
        return CoupleRequestStatus.pending;
      case CoupleRelation.requestReceived:
        return CoupleRequestStatus.received;
      case CoupleRelation.none:
      case CoupleRelation.partner:
      case CoupleRelation.coupleWithSomeoneElse:
        return CoupleRequestStatus.none;
    }
  }

  /// Update relationship status
  Future<void> updateStatus(RelationshipStatus status) async {
    final current = _coupleData;
    if (current == null) return;
    _coupleData = CoupleData(
      coupleId: current.coupleId,
      partnerId: current.partnerId,
      partnerName: current.partnerName,
      partnerPicture: current.partnerPicture,
      relationshipStartDate: current.relationshipStartDate,
      metOnMazlDate: current.metOnMazlDate,
      status: status,
      daysTogetherStreak: current.daysTogetherStreak,
    );
    await _saveData();
    notifyListeners();
  }

  // ===== Internals =====

  Future<void> _enterCouple(CoupleData couple) async {
    _coupleData = couple;
    _isCoupleModeEnabled = true;
    _pendingRequest = null;
    _receivedRequest = null;
    _stopPolling();
    await _saveData();
    notifyListeners();
  }

  Future<void> _leaveLocally() async {
    _isCoupleModeEnabled = false;
    _coupleData = null;
    await _clearData();
    notifyListeners();
  }

  Future<void> _setRequests({
    required CoupleRequest? pending,
    required CoupleRequest? received,
  }) async {
    _pendingRequest = pending;
    _receivedRequest = received;
    final prefs = await SharedPreferences.getInstance();
    if (pending == null) {
      await prefs.remove(_pendingRequestKey);
    } else {
      await prefs.setString(_pendingRequestKey, jsonEncode(pending.toJson()));
    }
    notifyListeners();
  }

  Future<void> _archiveOtherConversations() async {
    final partnerId = _coupleData?.partnerId;
    if (partnerId == null) return;
    try {
      await _api.archiveAllConversationsExcept(partnerId, message: _archiveMessage);
    } catch (e) {
      debugPrint('CoupleService: Error archiving conversations: $e');
    }
  }

  void _updatePolling() {
    final shouldPoll = _pendingRequest != null && _isForeground && !_isCoupleModeEnabled;
    if (shouldPoll && _pollTimer == null) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());
    } else if (!shouldPoll) {
      _stopPolling();
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coupleModeEnabledKey, _isCoupleModeEnabled);
    if (_coupleData != null) {
      await prefs.setString(_coupleDataKey, jsonEncode(_coupleData!.toJson()));
    }
    await prefs.remove(_pendingRequestKey);
  }

  Future<void> _clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coupleDataKey);
    await prefs.remove(_pendingRequestKey);
    await prefs.setBool(_coupleModeEnabledKey, false);
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Get daily questions for couple
  List<DailyQuestion> getDailyQuestions() {
    return [
      DailyQuestion(
        id: '1',
        question: 'Quel est votre moment préféré de la semaine ensemble ?',
        category: 'Connexion',
      ),
      DailyQuestion(
        id: '2',
        question: 'Si vous pouviez voyager n\'importe où, où iriez-vous ?',
        category: 'Rêves',
      ),
      DailyQuestion(
        id: '3',
        question: 'Qu\'est-ce qui vous a fait sourire aujourd\'hui ?',
        category: 'Quotidien',
      ),
      DailyQuestion(
        id: '4',
        question: 'Comment aimeriez-vous célébrer votre prochain Shabbat ?',
        category: 'Judaïsme',
        options: [
          'Dîner romantique à la maison',
          'Invitation chez des amis',
          'Restaurant casher',
          'Shabbaton communautaire',
        ],
      ),
      DailyQuestion(
        id: '5',
        question: 'Quel trait de caractère admirez-vous le plus chez votre partenaire ?',
        category: 'Appréciation',
      ),
    ];
  }

  /// Get milestones
  List<CoupleMilestone> getMilestones() {
    final daysTogether = _coupleData?.daysTogether ?? 0;

    return [
      CoupleMilestone(
        id: 'first_week',
        title: 'Première semaine',
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
        title: 'Mi-année',
        description: '6 mois main dans la main',
        emoji: '',
        isAchieved: daysTogether >= 180,
        achievedAt: daysTogether >= 180
            ? _coupleData?.relationshipStartDate?.add(const Duration(days: 180))
            : null,
      ),
      CoupleMilestone(
        id: 'first_year',
        title: 'Première année',
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
        'description': 'Préparez le repas de Shabbat ensemble',
        'icon': 'utensils',
        'category': 'Maison',
      },
      {
        'title': 'Étude Torah',
        'description': 'Apprenez la Paracha ensemble',
        'icon': 'book',
        'category': 'Spirituel',
      },
      {
        'title': 'Date night',
        'description': 'Sortie restaurant ou cinéma',
        'icon': 'heart',
        'category': 'Romance',
      },
      {
        'title': 'Sport ensemble',
        'description': 'Course, yoga, randonnée…',
        'icon': 'dumbbell',
        'category': 'Bien-être',
      },
      {
        'title': 'Hesed ensemble',
        'description': 'Action caritative en couple',
        'icon': 'hand-heart',
        'category': 'Communauté',
      },
      {
        'title': 'Voyage',
        'description': 'Planifiez votre prochaine escapade',
        'icon': 'plane',
        'category': 'Aventure',
      },
    ];
  }
}
