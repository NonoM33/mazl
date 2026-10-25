import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'session_end.dart';

/// An HTTP client that watches the answers to the requests sent with the
/// member's token: one that says the session is over (V1-CONTRAT §5, see
/// [sessionEndForResponse]) signs the member out and brings back the login
/// screen, whichever screen made the request.
///
/// Every client of the API goes through it, so no screen has to handle a 401
/// by itself. A request without a Bearer token (the sign-in itself) is never
/// watched. The answer is handed on unchanged.
class SessionGuardClient extends http.BaseClient {
  /// Wraps [inner], by default the client `http.get` would use (the one
  /// installed with `runWithClient`, else the platform's).
  SessionGuardClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final token = _bearerOf(request);
    final status = response.statusCode;
    if (token == null || (status != 401 && status != 403)) return response;

    // Only these two answers are read: the body tells a disabled account
    // from a refused action. It is put back for the caller.
    final bytes = await response.stream.toBytes();
    final reason = sessionEndForResponse(
      status,
      utf8.decode(bytes, allowMalformed: true),
    );
    if (reason != null) {
      unawaited(AuthService().endSession(reason, requestToken: token));
    }
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      status,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

String? _bearerOf(http.BaseRequest request) {
  final header = request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return null;
  return header.substring('Bearer '.length);
}
