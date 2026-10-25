import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/session_guard.dart';
import 'religious_data_consent.dart';

/// Error codes carried by a failed [ApiResponse] of [PrivacyConsentApi].
abstract class PrivacyConsentError {
  /// The version sent is no longer the current wording (409).
  static const versionOutdated = 'consent_version_outdated';

  /// Too many requests (429).
  static const rateLimited = 'rate_limited';
}

/// Privacy consent endpoints (docs/web/adr/W06-rgpd-article9.md).
/// [HttpPrivacyConsentApi] is the real implementation; tests use fakes.
abstract class PrivacyConsentApi {
  /// `GET /api/privacy/consents`, the `religious_data` entry.
  Future<ApiResponse<ReligiousDataConsent>> religiousData();

  /// `PUT /api/privacy/consents/religious_data`. Refusing or withdrawing
  /// (`granted: false`) erases the four practice fields on the server.
  Future<ApiResponse<void>> decideReligiousData({
    required bool granted,
    required String version,
  });
}

class HttpPrivacyConsentApi implements PrivacyConsentApi {
  HttpPrivacyConsentApi({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? requestTimeout,
  }) : _client = SessionGuardClient(client),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _token = tokenProvider ?? (() => AuthService().currentUser?.jwtToken),
       _timeout = requestTimeout ?? ApiConfig.requestTimeout;

  static const _consentsPath = '/api/privacy/consents';

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
  Future<ApiResponse<ReligiousDataConsent>> religiousData() => _guard(() async {
    final response = await _client
        .get(_uri(_consentsPath), headers: _headers)
        .timeout(_timeout);
    final failure = _failureOf<ReligiousDataConsent>(response);
    if (failure != null) return failure;
    final consents = _json(response)['consents'];
    final entry = consents is Map<String, dynamic>
        ? consents['religious_data']
        : null;
    if (entry is! Map<String, dynamic>) {
      throw const FormatException('religious_data');
    }
    return ApiResponse.success(ReligiousDataConsent.fromJson(entry));
  });

  @override
  Future<ApiResponse<void>> decideReligiousData({
    required bool granted,
    required String version,
  }) => _guard(() async {
    final response = await _client
        .put(
          _uri('$_consentsPath/religious_data'),
          headers: _headers,
          body: jsonEncode({
            'granted': granted,
            'version': version,
            'source': 'app',
          }),
        )
        .timeout(_timeout);
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
        PrivacyConsentError.rateLimited,
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
      debugPrint('Privacy consent API error: ${e.runtimeType}');
      return ApiResponse.failure('unknown_error', ApiErrorKind.unknown);
    }
  }
}
