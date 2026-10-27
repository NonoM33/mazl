import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Why a couple content call failed. The UI reads [CoupleFailure.kind] to
/// choose a state and to say it in the member's language; [CoupleFailure.message]
/// is an English diagnostic for the logs and never reaches the screen.
enum CoupleFailureKind {
  /// No connection, timeout or unreachable server.
  network,

  /// The activity or event does not exist (any more).
  notFound,

  /// The route itself is not there (a server that predates it): the screens
  /// show their empty state, never an error.
  routeMissing,

  /// The caller is not in a couple (server answers "Not in a couple").
  notInCouple,

  /// The event has no seat left.
  full,

  /// The couple has no MAZL Couple subscription (402).
  subscriptionRequired,

  /// The daily budget of assistant messages is spent (429).
  rateLimited,

  /// The monthly check-in was already answered (409).
  alreadyDone,

  /// The server refused or failed.
  server,

  /// The answer did not have the documented shape.
  malformed,
}

class CoupleFailure implements Exception {
  const CoupleFailure(this.kind, this.message, {this.detail});

  final CoupleFailureKind kind;

  /// Short diagnostic token for the logs (`timeout`, `unreachable`…), never
  /// shown: the screens write the cause from [kind].
  final String message;

  /// Technical detail for the logs, never shown.
  final String? detail;

  @override
  String toString() => [runtimeType, kind.name, message, detail].join(':');
}

/// Outcome of a call: a value or a [CoupleFailure], never a swallowed error.
sealed class CoupleResult<T> {
  const CoupleResult();

  bool get isOk => this is CoupleOk<T>;

  T? get valueOrNull => switch (this) {
    CoupleOk<T>(:final value) => value,
    CoupleFailed<T>() => null,
  };

  CoupleFailure? get failureOrNull => switch (this) {
    CoupleOk<T>() => null,
    CoupleFailed<T>(:final failure) => failure,
  };
}

final class CoupleOk<T> extends CoupleResult<T> {
  const CoupleOk(this.value);
  final T value;
}

final class CoupleFailed<T> extends CoupleResult<T> {
  const CoupleFailed(this.failure);
  final CoupleFailure failure;
}

/// The verbs the couple routes use. Lets tests feed the services the JSON
/// shapes of the backend without any network.
abstract class CoupleTransport {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> delete(String path);
}

class ApiServiceTransport implements CoupleTransport {
  ApiService get _api => ApiService();

  @override
  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body);

  @override
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body);

  @override
  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic> body = const {},
  ]) async {
    final response = await _api.sendRaw(method, path, body);
    return decodeCoupleBody(response.statusCode, response.body);
  }
}

/// The JSON object of an answer. A 404 that carries no JSON (the router of a
/// server that does not know the route yet) becomes the same refusal a known
/// route would give, so that the screens fall back to their empty state.
/// What a server that has no such route answers (and what a 404 without JSON
/// is read as).
const _routeMissingText = 'not_found';

@visibleForTesting
Map<String, dynamic> decodeCoupleBody(int status, String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    if (status != 404) rethrow;
  }
  if (status == 404) return {'success': false, 'error': _routeMissingText};
  throw const FormatException('json:object');
}

/// Runs the couple routes: turns what the transport throws and what the
/// server refuses into a [CoupleResult], and decodes the answer strictly (a
/// field of the wrong shape is a `malformed` failure, never a default).
class CoupleCaller {
  CoupleCaller({CoupleTransport? transport})
    : transport = transport ?? ApiServiceTransport();

  final CoupleTransport transport;

  Future<CoupleResult<T>> call<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Map<String, dynamic> response) decode,
  ) async {
    final Map<String, dynamic> response;
    try {
      response = await request();
    } on TimeoutException catch (e) {
      return _failed(CoupleFailureKind.network, 'timeout', e);
    } on SocketException catch (e) {
      return _failed(CoupleFailureKind.network, 'no-connection', e);
    } on http.ClientException catch (e) {
      return _failed(CoupleFailureKind.network, 'unreachable', e);
    } on FormatException catch (e) {
      return _failed(CoupleFailureKind.malformed, 'malformed', e);
    }

    if (response['success'] != true) {
      final error = response['error'];
      return _failed(_kindOf(error), _messageOf(error), error);
    }
    try {
      return CoupleOk(decode(response));
    } on FormatException catch (e) {
      return _failed(CoupleFailureKind.malformed, 'malformed', e);
    } on TypeError catch (e) {
      return _failed(CoupleFailureKind.malformed, 'malformed', e);
    }
  }

  CoupleFailed<T> _failed<T>(
    CoupleFailureKind kind,
    String message,
    Object? detail,
  ) {
    debugPrint('CoupleApi: ${kind.name} - $detail');
    return CoupleFailed(CoupleFailure(kind, message, detail: '$detail'));
  }

  // The routes answer `{ success: false, error: "<text>" }`; that text is the
  // only discriminator the shared HTTP client keeps.
  static final _serverNotInCouple = RegExp(r'^Not in a couple$');
  static final _serverNotFound = RegExp(r'^(Activity|Event) not found$');
  static final _serverRouteMissing = RegExp(
    r'^not.?found$',
    caseSensitive: false,
  );
  static final _serverFull = RegExp(r'^Event is full$');

  CoupleFailureKind _kindOf(Object? error) {
    final text = error is String ? error : '';
    if (_serverNotInCouple.hasMatch(text)) return CoupleFailureKind.notInCouple;
    if (_serverNotFound.hasMatch(text)) return CoupleFailureKind.notFound;
    if (_serverRouteMissing.hasMatch(text)) {
      return CoupleFailureKind.routeMissing;
    }
    if (_serverFull.hasMatch(text)) return CoupleFailureKind.full;
    return switch (text) {
      'couple_subscription_required' => CoupleFailureKind.subscriptionRequired,
      'concierge_rate_limited' => CoupleFailureKind.rateLimited,
      'checkin_already_done' => CoupleFailureKind.alreadyDone,
      _ => CoupleFailureKind.server,
    };
  }

  String _messageOf(Object? error) => switch (_kindOf(error)) {
    CoupleFailureKind.notInCouple => 'not-in-couple',
    CoupleFailureKind.notFound => 'not-found',
    CoupleFailureKind.routeMissing => 'route-missing',
    CoupleFailureKind.full => 'event-full',
    CoupleFailureKind.subscriptionRequired => 'subscription-required',
    CoupleFailureKind.rateLimited => 'rate-limited',
    CoupleFailureKind.alreadyDone => 'already-done',
    _ => 'server-error',
  };

  List<T> list<T>(
    Map<String, dynamic> response,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = response[key];
    if (raw is! List) throw FormatException('list:$key');
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          fromJson(item)
        else
          throw FormatException('item:$key'),
    ];
  }

  T object<T>(
    Map<String, dynamic> response,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = response[key];
    if (raw is! Map<String, dynamic>) {
      throw FormatException('object:$key');
    }
    return fromJson(raw);
  }
}
