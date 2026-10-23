import 'package:mazl/core/services/couple_api_service.dart';

/// Answers of one route: a decoded JSON object, or an exception to throw.
typedef CoupleRoute = Map<String, dynamic> Function(Map<String, dynamic> body);

/// A transport that only knows the routes a test declares. An undeclared
/// request fails loudly: a lenient fake would turn a typo in a path into a
/// silent success.
class FakeCoupleTransport implements CoupleTransport {
  final Map<String, CoupleRoute> routes = {};

  /// Every request made, as `METHOD /path` (query string included).
  final List<String> calls = [];

  /// Body of the last request per `METHOD /path`.
  final Map<String, Map<String, dynamic>> bodies = {};

  void on(String request, CoupleRoute route) => routes[request] = route;

  void reply(String request, Map<String, dynamic> response) =>
      routes[request] = (_) => response;

  void fail(String request, Object error) =>
      routes[request] = (_) => throw error;

  int count(String request) => calls.where((c) => c == request).length;

  Future<Map<String, dynamic>> _handle(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final key = '$method $path';
    calls.add(key);
    bodies[key] = body;
    final route = routes[key];
    if (route == null) throw StateError('No route declared for $key');
    return route(body);
  }

  @override
  Future<Map<String, dynamic>> get(String path) => _handle('GET', path, {});

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _handle('POST', path, body);

  @override
  Future<Map<String, dynamic>> delete(String path) =>
      _handle('DELETE', path, {});
}
