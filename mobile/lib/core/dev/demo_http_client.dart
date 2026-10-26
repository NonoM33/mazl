import 'dart:convert';

import 'package:http/http.dart' as http;

import 'demo_routes.dart';
import 'dev_session.dart';

/// Client HTTP du mode démo.
///
/// Session fictive inactive : transmet chaque requête, intacte, au client
/// interne. Session active : répond depuis les données fictives (méthode +
/// chemin, hôte ignoré) après [latency] ; seule la lecture des photos de
/// démo, en https sur images.unsplash.com, part sur le réseau.
class DemoHttpClient extends http.BaseClient {
  DemoHttpClient(
    this._inner, {
    this.latency = const Duration(milliseconds: 200),
  });

  final http.Client _inner;
  final Duration latency;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!DevSession.isActive || _isDemoPhoto(request)) {
      return _inner.send(request);
    }

    await Future<void>.delayed(latency);
    final files = await _files(request);
    final reply = DemoRoutes.respond(
      DemoRequest(
        request.method,
        request.url.path,
        request.url.queryParameters,
        _jsonBody(request),
        files: files,
      ),
    );
    return http.StreamedResponse(
      Stream.value(utf8.encode(reply.json)),
      reply.status,
      request: request,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// Une photo de démo (lib/core/dev/demo_photos.dart) : rien d'autre ne sort.
  static bool _isDemoPhoto(http.BaseRequest request) =>
      request.method == 'GET' &&
      request.url.scheme == 'https' &&
      request.url.host == 'images.unsplash.com';

  /// Octets des fichiers d'un envoi multipart (rien n'est transmis plus loin).
  Future<List<DemoUpload>> _files(http.BaseRequest request) async => [
    if (request is http.MultipartRequest)
      for (final file in request.files)
        DemoUpload(file.field, file.filename, await file.finalize().toBytes()),
  ];

  Map<String, dynamic> _jsonBody(http.BaseRequest request) {
    if (request is http.MultipartRequest) return {...request.fields};
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
