import 'package:flutter/material.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/web_sessions/web_session_models.dart';
import 'package:mazl/core/web_sessions/web_sessions_api.dart';

WebSession fakeSession(
  String id, {
  String browser = 'Chrome sur macOS',
  WebSessionMethod method = WebSessionMethod.qr,
  DateTime? lastSeen,
}) => WebSession(
  id: id,
  browser: browser,
  method: method,
  createdAt: DateTime(2026, 10, 20),
  lastSeenAt: lastSeen ?? DateTime(2026, 10, 24, 11, 55),
  expiresAt: DateTime(2026, 10, 27),
  current: false,
);

class FakeWebSessionsApi implements WebSessionsApi {
  FakeWebSessionsApi({List<WebSession>? sessions}) : sessions = sessions ?? [];

  List<WebSession> sessions;
  ApiResponse<WebPairing>? scanResult;
  ApiResponse<void> approveResult = ApiResponse<void>.success(null);
  bool listFails = false;
  final calls = <String>[];

  @override
  Future<ApiResponse<WebPairing>> scan(String code) async {
    calls.add('scan:$code');
    return scanResult ??
        ApiResponse.success(
          WebPairing(
            id: 'p1',
            browser: 'Chrome sur macOS',
            address: '198.51.100.x',
            createdAt: DateTime(2026, 10, 24, 14, 5),
            expiresAt: DateTime(2026, 10, 24, 14, 7),
          ),
        );
  }

  @override
  Future<ApiResponse<void>> approve(String pairingId) async {
    calls.add('approve:$pairingId');
    return approveResult;
  }

  @override
  Future<ApiResponse<void>> deny(String pairingId) async {
    calls.add('deny:$pairingId');
    return ApiResponse<void>.success(null);
  }

  @override
  Future<ApiResponse<List<WebSession>>> listSessions() async {
    calls.add('list');
    if (listFails) return ApiResponse.failure('network', ApiErrorKind.network);
    return ApiResponse.success(List.of(sessions));
  }

  @override
  Future<ApiResponse<void>> revoke(String sessionId) async {
    calls.add('revoke:$sessionId');
    sessions.removeWhere((s) => s.id == sessionId);
    return ApiResponse<void>.success(null);
  }

  @override
  Future<ApiResponse<void>> revokeAll() async {
    calls.add('revokeAll');
    sessions.clear();
    return ApiResponse<void>.success(null);
  }
}

/// A "camera" that reports whatever the test pushes through [emit].
class FakeCamera {
  ValueChanged<String>? _onCode;

  Widget build(BuildContext context, ValueChanged<String> onCode) {
    _onCode = onCode;
    return const ColoredBox(color: Colors.black);
  }

  void emit(String raw) => _onCode!(raw);
}
