import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../services/auth_service.dart';

/// What came back from the server, decoded.
class TransportReply {
  const TransportReply(this.status, this.body);

  final int status;

  /// The JSON object of the answer, null when there was none.
  final Map<String, dynamic>? body;

  /// The stable code of a refusal (`{ "success": false, "error": "<code>" }`).
  String? get errorCode {
    final error = body?['error'];
    return error is String ? error : null;
  }

  /// The `data` of a successful `{ "success": true, "data": ... }` answer.
  Object? get data => body?['data'];

  bool get isSuccess => status == 200 && body?['success'] == true;
}

/// The network could not carry the request.
enum TransportFailureKind { timeout, network }

class TransportFailure implements Exception {
  const TransportFailure(this.kind);

  final TransportFailureKind kind;
}

const _requestTimeout = Duration(seconds: 15);

/// One authenticated JSON request to the MAZL API. A client per call, like
/// `http.get`, so the demo client installed with `runWithClient` is the one
/// that answers in demo mode.
class PremiumTransport {
  PremiumTransport({
    required this.baseUrl,
    required this.token,
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  /// The app's client: its base URL and the signed-in member's token.
  factory PremiumTransport.app() => PremiumTransport(
    baseUrl: Env.apiBaseUrl,
    token: () => AuthService().currentUser?.jwtToken,
  );

  final String baseUrl;
  final String? Function() token;
  final http.Client Function() _clientFactory;

  /// [body] is JSON encoded as it is, `null` included (a JSON `null`).
  /// Without [sendBody] there is no body at all.
  Future<TransportReply> send(
    String method,
    String path, {
    Object? body,
    bool sendBody = false,
  }) async {
    final jwt = token();
    final client = _clientFactory();
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        });
      if (sendBody) request.body = jsonEncode(body);
      final streamed = await client.send(request).timeout(_requestTimeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(_requestTimeout);
      return TransportReply(response.statusCode, _decode(response.bodyBytes));
    } on TimeoutException {
      throw const TransportFailure(TransportFailureKind.timeout);
    } on SocketException {
      throw const TransportFailure(TransportFailureKind.network);
    } on http.ClientException {
      throw const TransportFailure(TransportFailureKind.network);
    } finally {
      client.close();
    }
  }

  Map<String, dynamic>? _decode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
