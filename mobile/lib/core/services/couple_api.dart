import 'api_service.dart';

/// The server calls the couple flow depends on (docs/couple/CONTRAT.md §2).
///
/// [ApiService] is the real implementation; tests give the flow a fake that
/// implements these same methods.
abstract class CoupleApi {
  /// `POST /api/couple/request` → `{ success, request: { id, ... } }`.
  Future<ApiResponse<Map<String, dynamic>>> sendCoupleRequest(int targetUserId);

  /// `PUT /api/couple/request/:id` → `{ success, action, couple? }`.
  Future<ApiResponse<Map<String, dynamic>>> respondToCoupleRequest({
    required int requestId,
    required bool accept,
  });

  /// `DELETE /api/couple/request/:id` (sender only).
  Future<ApiResponse<void>> cancelCoupleRequest(int requestId);

  /// `GET /api/couple/requests` → `{ success, sent: [], received: [] }`.
  Future<ApiResponse<Map<String, dynamic>>> getCoupleRequests();

  /// `GET /api/couple` → `{ success, couple: <shape> | null }`.
  Future<ApiResponse<Map<String, dynamic>>> getCoupleData();

  /// `POST /api/couple/archive-conversations`.
  Future<ApiResponse<void>> archiveAllConversationsExcept(
    int partnerUserId, {
    required String message,
  });

  /// `DELETE /api/couple/:coupleId` (either member, ends it for both).
  Future<ApiResponse<void>> endCouple(int coupleId);
}
