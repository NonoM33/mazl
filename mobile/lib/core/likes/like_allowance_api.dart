import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../services/auth_service.dart';
import 'like_allowance.dart';

// Typed HTTP client for `GET /api/likes/allowance`. Failures are typed here
// and the screen decides what to do; the server's own error text is never
// shown, nor logged.

/// Why the allowance could not be read.
enum LikeAllowanceErrorKind { sessionExpired, server, timeout, network, unknown }

class LikeAllowanceException implements Exception {
  const LikeAllowanceException(this.kind, {this.status});

  final LikeAllowanceErrorKind kind;

  /// HTTP status, null for network failures.
  final int? status;

  @override
  String toString() => '$runtimeType:${kind.name}:${status ?? 0}';
}

abstract interface class LikeAllowanceApi {
  /// What the member can still like today, as the server counts it.
  Future<LikeAllowance> getAllowance();
}

const _requestTimeout = Duration(seconds: 15);

class HttpLikeAllowanceApi implements LikeAllowanceApi {
  HttpLikeAllowanceApi({
    required this.baseUrl,
    required this.token,
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  /// The app's client: its base URL and the signed-in member's token.
  factory HttpLikeAllowanceApi.app() => HttpLikeAllowanceApi(
    baseUrl: Env.apiBaseUrl,
    token: () => AuthService().currentUser?.jwtToken,
  );

  final String baseUrl;
  final String? Function() token;

  /// A client per call, like `http.get`, so the demo client installed with
  /// `runWithClient` is the one that answers in demo mode.
  final http.Client Function() _clientFactory;

  @override
  Future<LikeAllowance> getAllowance() async {
    final jwt = token();
    final client = _clientFactory();
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/api/likes/allowance'),
            headers: {if (jwt != null) 'Authorization': 'Bearer $jwt'},
          )
          .timeout(_requestTimeout);
      return _allowanceOf(response);
    } on TimeoutException {
      throw const LikeAllowanceException(LikeAllowanceErrorKind.timeout);
    } on SocketException {
      throw const LikeAllowanceException(LikeAllowanceErrorKind.network);
    } on http.ClientException {
      throw const LikeAllowanceException(LikeAllowanceErrorKind.network);
    } finally {
      client.close();
    }
  }

  LikeAllowance _allowanceOf(http.Response response) {
    final status = response.statusCode;
    if (status == 401) {
      throw LikeAllowanceException(LikeAllowanceErrorKind.sessionExpired, status: status);
    }
    if (status >= 500) {
      throw LikeAllowanceException(LikeAllowanceErrorKind.server, status: status);
    }
    final allowance = status == 200 ? _parse(response.bodyBytes) : null;
    if (allowance == null) {
      throw LikeAllowanceException(LikeAllowanceErrorKind.unknown, status: status);
    }
    return allowance;
  }

  LikeAllowance? _parse(List<int> body) {
    try {
      final decoded = jsonDecode(utf8.decode(body));
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) return null;
      return LikeAllowance.tryParse(decoded['allowance']);
    } on FormatException {
      return null;
    }
  }
}
