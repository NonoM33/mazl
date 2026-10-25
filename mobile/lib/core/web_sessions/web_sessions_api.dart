import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_guard.dart';
import 'web_session_models.dart';

/// Error codes carried by a failed [ApiResponse] of [WebSessionsApi].
abstract class WebSessionsError {
  /// Unknown, expired or already scanned code (404).
  static const pairingNotFound = 'pairing_not_found';

  /// The request was already approved or denied (409).
  static const pairingNotPending = 'pairing_not_pending';

  /// Too many scans (429).
  static const rateLimited = 'rate_limited';
}

/// Web login endpoints used by the app (docs/web/adr/W02-sessions-web.md).
/// [HttpWebSessionsApi] is the real implementation; tests use fakes.
abstract class WebSessionsApi {
  /// `POST /api/web/pairings/scan` with `{code}`.
  Future<ApiResponse<WebPairing>> scan(String code);

  /// `POST /api/web/pairings/:id/approve`.
  Future<ApiResponse<void>> approve(String pairingId);

  /// `POST /api/web/pairings/:id/deny`.
  Future<ApiResponse<void>> deny(String pairingId);

  /// `GET /api/web/sessions`.
  Future<ApiResponse<List<WebSession>>> listSessions();

  /// `DELETE /api/web/sessions/:id`.
  Future<ApiResponse<void>> revoke(String sessionId);

  /// `DELETE /api/web/sessions`: every computer.
  Future<ApiResponse<void>> revokeAll();
}

class HttpWebSessionsApi implements WebSessionsApi {
  HttpWebSessionsApi({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? requestTimeout,
  }) : _client = SessionGuardClient(client),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _token = tokenProvider ?? (() => AuthService().currentUser?.jwtToken),
       _timeout = requestTimeout ?? ApiConfig.requestTimeout;

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _token;
  final Duration _timeout;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _headers {
    final token = _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ApiResponse<WebPairing>> scan(String code) => _guard(() async {
    final response = await _client
        .post(
          _uri('/api/web/pairings/scan'),
          headers: _headers,
          body: jsonEncode({'code': code}),
        )
        .timeout(_timeout);
    final failure = _failureOf<WebPairing>(response);
    if (failure != null) return failure;
    final pairing = _json(response)['pairing'];
    if (pairing is! Map<String, dynamic>) {
      throw const FormatException('pairing');
    }
    return ApiResponse.success(WebPairing.fromJson(pairing));
  });

  @override
  Future<ApiResponse<void>> approve(String pairingId) => _send(
    'POST',
    '/api/web/pairings/${Uri.encodeComponent(pairingId)}/approve',
  );

  @override
  Future<ApiResponse<void>> deny(String pairingId) =>
      _send('POST', '/api/web/pairings/${Uri.encodeComponent(pairingId)}/deny');

  @override
  Future<ApiResponse<List<WebSession>>> listSessions() => _guard(() async {
    final response = await _client
        .get(_uri('/api/web/sessions'), headers: _headers)
        .timeout(_timeout);
    final failure = _failureOf<List<WebSession>>(response);
    if (failure != null) return failure;
    final raw = _json(response)['sessions'];
    if (raw is! List) throw const FormatException('sessions');
    return ApiResponse.success([
      for (final item in raw) WebSession.fromJson(item as Map<String, dynamic>),
    ]);
  });

  @override
  Future<ApiResponse<void>> revoke(String sessionId) =>
      _send('DELETE', '/api/web/sessions/${Uri.encodeComponent(sessionId)}');

  @override
  Future<ApiResponse<void>> revokeAll() => _send('DELETE', '/api/web/sessions');

  Future<ApiResponse<void>> _send(String method, String path) =>
      _guard(() async {
        final request = http.Request(method, _uri(path))
          ..headers.addAll(_headers);
        final streamed = await _client.send(request).timeout(_timeout);
        final response = await http.Response.fromStream(
          streamed,
        ).timeout(_timeout);
        return _failureOf<void>(response) ?? ApiResponse<void>.success(null);
      });

  Map<String, dynamic> _json(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('unexpected response body');
    }
    return decoded;
  }

  ApiResponse<T>? _failureOf<T>(http.Response response) {
    if (response.statusCode == 429) {
      return ApiResponse.failure(
        WebSessionsError.rateLimited,
        ApiErrorKind.server,
      );
    }
    Map<String, dynamic>? body;
    try {
      body = _json(response);
    } on FormatException {
      body = null;
    }
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (ok && body != null && body['success'] != false) return null;
    final code = body?['error'];
    return ApiResponse.failure(
      code is String ? code : 'http_${response.statusCode}',
      ApiErrorKind.server,
    );
  }

  Future<ApiResponse<T>> _guard<T>(
    Future<ApiResponse<T>> Function() action,
  ) async {
    try {
      return await action();
    } on TimeoutException {
      return ApiResponse.failure('timeout', ApiErrorKind.timeout);
    } on SocketException {
      return ApiResponse.failure('network', ApiErrorKind.network);
    } on http.ClientException {
      return ApiResponse.failure('network', ApiErrorKind.network);
    } on FormatException {
      return ApiResponse.failure('invalid_response', ApiErrorKind.server);
    } catch (e) {
      debugPrint('Web sessions API error: ${e.runtimeType}');
      return ApiResponse.failure('unknown_error', ApiErrorKind.unknown);
    }
  }
}
