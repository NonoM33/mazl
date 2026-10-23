import 'dart:convert';

import 'package:http/http.dart' as http;

import 'demo_routes.dart';
import 'dev_session.dart';

/// Client HTTP du mode démo.
///
/// Session fictive inactive : transmet chaque requête, intacte, au client
/// interne. Session active : ne transmet JAMAIS rien, répond depuis les
/// données fictives (méthode + chemin, hôte ignoré) après [latency].
class DemoHttpClient extends http.BaseClient {
  DemoHttpClient(
    this._inner, {
    this.latency = const Duration(milliseconds: 200),
  });

  final http.Client _inner;
  final Duration latency;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!DevSession.isActive) return _inner.send(request);

    await Future<void>.delayed(latency);
    final reply = DemoRoutes.respond(
      DemoRequest(
        request.method,
        request.url.path,
        request.url.queryParameters,
        _jsonBody(request),
      ),
    );
    return http.StreamedResponse(
      Stream.value(utf8.encode(reply.json)),
      reply.status,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Map<String, dynamic> _jsonBody(http.BaseRequest request) {
    if (request is! http.Request || request.body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(request.body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  @override
  void close() => _inner.close();
}
