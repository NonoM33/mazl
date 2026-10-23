import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// http_parser ships with `http` and is the only way to type a multipart part.
// ignore: depend_on_referenced_packages
import 'package:http_parser/http_parser.dart' show MediaType;

import 'api_service.dart';
import 'auth_service.dart';
import 'verification_api.dart';

/// Real [VerificationApi]. CONTRACT: docs/verification/CONTRAT.md §3 and §4.
///
/// Images only ever travel as in-memory bytes: nothing is written to disk and
/// nothing is logged.
class HttpVerificationApi implements VerificationApi {
  HttpVerificationApi({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? requestTimeout,
    Duration? uploadTimeout,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _token = tokenProvider ?? (() => AuthService().currentUser?.jwtToken),
        _requestTimeout = requestTimeout ?? ApiConfig.requestTimeout,
        _uploadTimeout = uploadTimeout ?? const Duration(seconds: 60);

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _token;
  final Duration _requestTimeout;

  /// Uploads of several JPEGs followed by server-side face analysis.
  final Duration _uploadTimeout;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _headers {
    final token = _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ApiResponse<FaceSession>> startFaceSession(FacePurpose purpose) async {
    return _guard(() async {
      final response = await _client
          .post(
            _uri('/api/verification/face/session'),
            headers: _headers,
            body: jsonEncode({'purpose': purpose.name}),
          )
          .timeout(_requestTimeout);
      final failure = _failureOf<FaceSession>(response);
      if (failure != null) return failure;
      return ApiResponse.success(FaceSession.fromJson(_json(response)));
    });
  }

  @override
  Future<ApiResponse<VerificationOutcome>> submitFace(String sessionId, List<Uint8List> frames) async {
    return _guard(() async {
      final request = http.MultipartRequest('POST', _uri('/api/verification/face/submit'));
      _addAuth(request);
      request.fields['session_id'] = sessionId;
      _addFrames(request, frames);
      return _sendOutcome(request);
    });
  }

  @override
  Future<ApiResponse<VerificationOutcome>> submitIdentity(
    String sessionId,
    List<Uint8List> frames,
    ChipReadResult chip,
  ) async {
    return _guard(() async {
      final request = http.MultipartRequest('POST', _uri('/api/verification/identity'));
      _addAuth(request);
      request.fields['session_id'] = sessionId;
      _addFrames(request, frames);
      request.files
        ..add(http.MultipartFile.fromBytes('dg1', chip.dg1, filename: 'dg1.bin'))
        ..add(http.MultipartFile.fromBytes('dg2', chip.dg2, filename: 'dg2.bin'))
        ..add(http.MultipartFile.fromBytes('sod', chip.sod, filename: 'sod.bin'));
      return _sendOutcome(request);
    });
  }

  @override
  Future<ApiResponse<VerificationStatus>> getStatus() async {
    return _guard(() async {
      final response = await _client
          .get(_uri('/api/verification/status'), headers: _headers)
          .timeout(_requestTimeout);
      final failure = _failureOf<VerificationStatus>(response);
      if (failure != null) return failure;
      return ApiResponse.success(VerificationStatus.fromJson(_json(response)));
    });
  }

  @override
  Future<ApiResponse<void>> deleteFaceReference() async {
    return _guard(() async {
      final response = await _client
          .delete(_uri('/api/verification/face/reference'), headers: _headers)
          .timeout(_requestTimeout);
      final failure = _failureOf<void>(response);
      if (failure != null) return failure;
      return ApiResponse<void>.success(null);
    });
  }

  void _addAuth(http.MultipartRequest request) {
    final token = _token();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
  }

  void _addFrames(http.MultipartRequest request, List<Uint8List> frames) {
    for (var i = 0; i < frames.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        'frame_$i',
        frames[i],
        filename: 'frame_$i.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }
  }

  Future<ApiResponse<VerificationOutcome>> _sendOutcome(http.MultipartRequest request) async {
    final streamed = await _client.send(request).timeout(_uploadTimeout);
    final response = await http.Response.fromStream(streamed).timeout(_uploadTimeout);
    final failure = _failureOf<VerificationOutcome>(response);
    if (failure != null) return failure;
    return ApiResponse.success(VerificationOutcome.fromJson(_json(response)));
  }

  Map<String, dynamic> _json(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) throw const FormatException('unexpected response body');
    return decoded;
  }

  /// Maps non-2xx answers and `success: false` bodies to a failure carrying
  /// the server error code. 429 is always the daily quota.
  ApiResponse<T>? _failureOf<T>(http.Response response) {
    if (response.statusCode == 429) {
      return ApiResponse.failure('daily_limit_reached', ApiErrorKind.server);
    }
    Map<String, dynamic>? body;
    try {
      body = _json(response);
    } on FormatException {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = body?['error'];
      return ApiResponse.failure(code is String ? code : 'http_${response.statusCode}', ApiErrorKind.server);
    }
    if (body == null) return ApiResponse.failure('invalid_response', ApiErrorKind.server);
    if (body['success'] == false) {
      final code = body['error'];
      return ApiResponse.failure(code is String ? code : 'unknown_error', ApiErrorKind.server);
    }
    return null;
  }

  Future<ApiResponse<T>> _guard<T>(Future<ApiResponse<T>> Function() action) async {
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
      debugPrint('Verification API error: ${e.runtimeType}');
      return ApiResponse.failure('unknown_error', ApiErrorKind.unknown);
    }
  }
}
