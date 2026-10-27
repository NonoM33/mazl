import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_api.dart';

/// Server shapes written from docs/couple/CONTRAT.md (§1, §2), not from the
/// parser: if the parser drifts from the contract, the tests that use these
/// shapes fail.
Map<String, dynamic> contractCouple({
  int id = 12,
  int partnerId = 45,
  String partnerName = 'Myriam',
  String? partnerPicture,
  String status = 'in_relationship',
}) =>
    {
      'id': id,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_picture': partnerPicture,
      'started_at': '2026-10-20T10:00:00.000Z',
      'met_on_mazl_at': '2026-10-01T09:30:00.000Z',
      'status': status,
    };

/// `request` as `POST /api/couple/request` renders it (§2).
Map<String, dynamic> contractSentRequest({int id = 77, int targetId = 45}) => {
      'id': id,
      'requester_id': 7,
      'target_id': targetId,
      'status': 'pending',
      'created_at': '2026-10-23T08:00:00.000Z',
      'target_name': 'Myriam',
      'target_picture': null,
    };

/// An item of `received` in `GET /api/couple/requests`.
Map<String, dynamic> contractReceivedRequest({int id = 91, int requesterId = 45}) => {
      'id': id,
      'requester_id': requesterId,
      'target_id': 7,
      'status': 'pending',
      'created_at': '2026-10-23T08:05:00.000Z',
      'requester_name': 'Myriam',
      'requester_picture': null,
      'target_name': 'Moi',
      'target_picture': null,
    };

/// A fake server behind the real [CoupleApi] methods.
class FakeCoupleApi implements CoupleApi {
  Map<String, dynamic>? couple;

  /// `premium` as `GET /api/couple` renders it (ESPACE-COUPLE.md §1); null =
  /// a server that does not send it yet.
  Map<String, dynamic>? premium;
  List<Map<String, dynamic>> sent = [];
  List<Map<String, dynamic>> received = [];

  /// When set, the matching call fails with this server error.
  String? sendError;
  String? respondError;
  String? endError;

  /// The sentence sent with each archive call.
  final List<String> archiveMessages = [];
  bool unreachable = false;

  /// What the acceptance returns as `couple` (null = field missing).
  Map<String, dynamic>? acceptedCouple;

  final List<String> calls = [];
  int getCoupleCount = 0;

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendCoupleRequest(int targetUserId) async {
    calls.add('send:$targetUserId');
    if (sendError != null) return ApiResponse.failure(sendError!, ApiErrorKind.server);
    final request = contractSentRequest(targetId: targetUserId);
    sent = [request];
    return ApiResponse.success({'success': true, 'request': request});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> respondToCoupleRequest({
    required int requestId,
    required bool accept,
  }) async {
    calls.add('${accept ? 'accept' : 'reject'}:$requestId');
    if (respondError != null) return ApiResponse.failure(respondError!, ApiErrorKind.server);
    received = [];
    if (!accept) return ApiResponse.success({'success': true, 'action': 'rejected'});
    couple = acceptedCouple;
    return ApiResponse.success({
      'success': true,
      'action': 'accepted',
      if (acceptedCouple != null) 'couple': acceptedCouple,
    });
  }

  @override
  Future<ApiResponse<void>> cancelCoupleRequest(int requestId) async {
    calls.add('cancel:$requestId');
    sent = [];
    return ApiResponse.success(null);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getCoupleRequests() async {
    calls.add('requests');
    if (unreachable) return ApiResponse.failure('offline', ApiErrorKind.network);
    return ApiResponse.success({'success': true, 'sent': sent, 'received': received});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getCoupleData() async {
    calls.add('couple');
    getCoupleCount++;
    if (unreachable) return ApiResponse.failure('offline', ApiErrorKind.network);
    return ApiResponse.success({
      'success': true,
      'couple': couple,
      'milestones': [],
      if (premium != null) 'premium': premium,
    });
  }

  @override
  Future<ApiResponse<void>> archiveAllConversationsExcept(
    int partnerUserId, {
    required String message,
  }) async {
    calls.add('archive:$partnerUserId');
    archiveMessages.add(message);
    return ApiResponse.success(null);
  }

  /// When set, the status update fails with this server error.
  String? statusError;
  final List<String> statuses = [];

  @override
  Future<ApiResponse<void>> updateCoupleStatus(
    int coupleId,
    String relationshipStatus,
  ) async {
    calls.add('status:$coupleId:$relationshipStatus');
    if (statusError != null) {
      return ApiResponse.failure(statusError!, ApiErrorKind.server);
    }
    statuses.add(relationshipStatus);
    final current = couple;
    if (current != null) couple = {...current, 'status': relationshipStatus};
    return ApiResponse.success(null);
  }

  @override
  Future<ApiResponse<void>> endCouple(int coupleId) async {
    calls.add('end:$coupleId');
    if (endError != null) return ApiResponse.failure(endError!, ApiErrorKind.server);
    couple = null;
    return ApiResponse.success(null);
  }
}
