import 'package:http/http.dart' as http;

import 'premium_transport.dart';

// Typed client of the read receipts setting (docs/premium/MONETISATION.md §4):
// `GET /api/premium/settings` (field `send_read_receipts`) and
// `PUT /api/profile/read-receipts { enabled }`. The server holds the value;
// the app shows what it answers. Failures are typed here, the screen words
// them, and the server's own text is never shown.

enum ReadReceiptsErrorKind { sessionExpired, server, timeout, network, unknown }

class ReadReceiptsException implements Exception {
  const ReadReceiptsException(this.kind, {this.status});

  final ReadReceiptsErrorKind kind;

  /// HTTP status, null for network failures.
  final int? status;

  @override
  String toString() => '$runtimeType:${kind.name}:${status ?? 0}';
}

abstract interface class ReadReceiptsApi {
  /// Whether the member sends read receipts, as the server holds it.
  Future<bool> load();

  /// Turns the sending on or off; returns what the server now holds.
  Future<bool> set(bool enabled);
}

class HttpReadReceiptsApi implements ReadReceiptsApi {
  HttpReadReceiptsApi({PremiumTransport? transport})
    : _transport = transport ?? PremiumTransport.app();

  /// For tests: the client the requests go through.
  HttpReadReceiptsApi.withClient({
    required String baseUrl,
    required String? Function() token,
    required http.Client Function() clientFactory,
  }) : _transport = PremiumTransport(
         baseUrl: baseUrl,
         token: token,
         clientFactory: clientFactory,
       );

  final PremiumTransport _transport;

  @override
  Future<bool> load() async {
    final reply = await _send('GET', '/api/premium/settings');
    return _flag(reply);
  }

  @override
  Future<bool> set(bool enabled) async {
    final reply = await _send(
      'PUT',
      '/api/profile/read-receipts',
      body: {'enabled': enabled},
    );
    return _flag(reply);
  }

  bool _flag(TransportReply reply) {
    final data = reply.data;
    final held = data is Map<String, dynamic>
        ? data['send_read_receipts']
        : null;
    if (held is! bool) {
      throw ReadReceiptsException(
        ReadReceiptsErrorKind.unknown,
        status: reply.status,
      );
    }
    return held;
  }

  Future<TransportReply> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final TransportReply reply;
    try {
      reply = await _transport.send(
        method,
        path,
        body: body,
        sendBody: method != 'GET',
      );
    } on TransportFailure catch (failure) {
      throw ReadReceiptsException(switch (failure.kind) {
        TransportFailureKind.timeout => ReadReceiptsErrorKind.timeout,
        TransportFailureKind.network => ReadReceiptsErrorKind.network,
      });
    }
    final status = reply.status;
    final kind = switch (status) {
      401 => ReadReceiptsErrorKind.sessionExpired,
      >= 500 => ReadReceiptsErrorKind.server,
      _ when !reply.isSuccess => ReadReceiptsErrorKind.unknown,
      _ => null,
    };
    if (kind != null) throw ReadReceiptsException(kind, status: status);
    return reply;
  }
}
