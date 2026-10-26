import 'api_service.dart';

/// What the app tells the MAZL server about this phone's APNs token. A fake in
/// the tests, [ApiPushDeviceServer] in the app.
abstract interface class PushDeviceServer {
  /// `PUT /api/push/devices`. Idempotent. Throws when the server refuses.
  Future<void> register({required String token, required String environment});

  /// `DELETE /api/push/devices`. Idempotent. Throws when the server refuses.
  Future<void> unregister({required String token});
}

class PushDeviceRequestFailed implements Exception {
  const PushDeviceRequestFailed(this.method, this.statusCode);

  final String method;
  final int statusCode;

  @override
  String toString() => [runtimeType, method, statusCode].join(' ');
}

/// Talks to the server with the signed-in member's session token.
class ApiPushDeviceServer implements PushDeviceServer {
  ApiPushDeviceServer({ApiService? api}) : _injected = api;

  static const String _path = '/api/push/devices';

  final ApiService? _injected;

  /// Resolved on first use, not at construction: the API client reaches the
  /// auth service, which builds the push service, which builds this.
  ApiService get _api => _injected ?? ApiService();

  @override
  Future<void> register({
    required String token,
    required String environment,
  }) async {
    final response = await _api.putRaw(_path, {
      'token': token,
      'environment': environment,
    });
    if (response.statusCode != 200) {
      throw PushDeviceRequestFailed('PUT', response.statusCode);
    }
  }

  @override
  Future<void> unregister({required String token}) async {
    final response = await _api.deleteWithBody(_path, {'token': token});
    if (response.statusCode != 200) {
      throw PushDeviceRequestFailed('DELETE', response.statusCode);
    }
  }
}
