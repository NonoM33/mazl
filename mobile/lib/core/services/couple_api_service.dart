import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/couple_activity.dart';
import '../models/couple_event.dart';
import '../models/couple_space.dart';
import 'api_service.dart';

/// Why a couple content call failed. The UI reads [CoupleFailure.kind] to
/// choose a state and to say it in the member's language; [CoupleFailure.message]
/// is an English diagnostic for the logs and never reaches the screen.
enum CoupleFailureKind {
  /// No connection, timeout or unreachable server.
  network,

  /// The activity or event does not exist (any more).
  notFound,

  /// The caller is not in a couple (server answers "Not in a couple").
  notInCouple,

  /// The event has no seat left.
  full,

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

/// The three verbs the couple content routes use. Lets tests feed the service
/// the JSON shapes of the backend without any network.
abstract class CoupleTransport {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> delete(String path);
}

class _ApiServiceTransport implements CoupleTransport {
  ApiService get _api => ApiService();

  @override
  Future<Map<String, dynamic>> get(String path) => _api.get(path);

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _api.post(path, body);

  @override
  Future<Map<String, dynamic>> delete(String path) => _api.delete(path);
}

/// Couple content: activities feed, saved activities, events and the couple
/// space (stats, dates, bucket list, memories). The server is the truth
/// (docs/couple/CONTRAT.md section 0.3): a failure is reported, it never
/// becomes an empty list.
class CoupleApiService {
  CoupleApiService({CoupleTransport? transport})
    : _transport = transport ?? _ApiServiceTransport();

  final CoupleTransport _transport;

  // ============ ACTIVITIES ============

  Future<CoupleResult<List<CoupleActivity>>> getActivities({
    int limit = 20,
    int offset = 0,
    String? category,
  }) {
    var path = '/api/couple/activities?limit=$limit&offset=$offset';
    if (category != null) {
      path += '&category=${Uri.encodeQueryComponent(category)}';
    }
    return _call(
      () => _transport.get(path),
      (r) => _list(r, 'activities', CoupleActivity.fromJson),
    );
  }

  Future<CoupleResult<CoupleActivity>> getActivity(int id) => _call(
    () => _transport.get('/api/couple/activities/$id'),
    (r) => _object(r, 'activity', CoupleActivity.fromJson),
  );

  Future<CoupleResult<void>> saveActivity(int activityId, {String? notes}) =>
      _call(
        () => _transport.post('/api/couple/activities/$activityId/save', {
          if (notes != null) 'notes': notes,
        }),
        (_) {},
      );

  Future<CoupleResult<void>> passActivity(int activityId) => _call(
    () => _transport.post('/api/couple/activities/$activityId/pass', {}),
    (_) {},
  );

  Future<CoupleResult<List<CoupleActivity>>> getSavedActivities() => _call(
    () => _transport.get('/api/couple/saved'),
    (r) => _list(r, 'activities', CoupleActivity.fromJson),
  );

  Future<CoupleResult<void>> removeSavedActivity(int activityId) =>
      _call(() => _transport.delete('/api/couple/saved/$activityId'), (_) {});

  // ============ EVENTS ============

  Future<CoupleResult<List<CoupleEvent>>> getEvents({
    int limit = 20,
    int offset = 0,
    String? category,
  }) {
    var path = '/api/couple/events?limit=$limit&offset=$offset';
    if (category != null) {
      path += '&category=${Uri.encodeQueryComponent(category)}';
    }
    return _call(
      () => _transport.get(path),
      (r) => _list(r, 'events', CoupleEvent.fromJson),
    );
  }

  Future<CoupleResult<CoupleEvent>> getEvent(int id) => _call(
    () => _transport.get('/api/couple/events/$id'),
    (r) => _object(r, 'event', CoupleEvent.fromJson),
  );

  Future<CoupleResult<void>> registerForEvent(int eventId) => _call(
    () => _transport.post('/api/couple/events/$eventId/register', {}),
    (_) {},
  );

  Future<CoupleResult<void>> cancelEventRegistration(int eventId) => _call(
    () => _transport.delete('/api/couple/events/$eventId/register'),
    (_) {},
  );

  Future<CoupleResult<List<CoupleEvent>>> getRegisteredEvents() => _call(
    () => _transport.get('/api/couple/events/registered'),
    (r) => _list(r, 'events', CoupleEvent.fromJson),
  );

  // ============ STATS ============

  Future<CoupleResult<CoupleStatsSnapshot>> getStats() =>
      _call(() => _transport.get('/api/couple/stats'), (r) {
        final stats = r['stats'];
        if (stats is! Map<String, dynamic>) {
          throw const FormatException('stats is not an object');
        }
        return CoupleStatsSnapshot(
          stats: CoupleStats.fromJson(stats),
          achievements: _list(r, 'achievements', CoupleAchievement.fromJson),
        );
      });

  // ============ DATES ============

  Future<CoupleResult<List<CoupleDate>>> getDates() => _call(
    () => _transport.get('/api/couple/dates'),
    (r) => _list(r, 'dates', CoupleDate.fromJson),
  );

  Future<CoupleResult<void>> addDate({
    required String title,
    required String date,
    required String type,
    bool isRecurring = true,
    int remindDaysBefore = 7,
    String? notes,
  }) => _call(
    () => _transport.post('/api/couple/dates', {
      'title': title,
      'date': date,
      'type': type,
      'isRecurring': isRecurring,
      'remindDaysBefore': remindDaysBefore,
      if (notes != null) 'notes': notes,
    }),
    (_) {},
  );

  // ============ BUCKET LIST ============

  Future<CoupleResult<List<BucketListItem>>> getBucketList() => _call(
    () => _transport.get('/api/couple/bucket-list'),
    (r) => _list(r, 'items', BucketListItem.fromJson),
  );

  Future<CoupleResult<void>> addBucketListItem({
    required String title,
    String? description,
    String? category,
    String? targetDate,
  }) => _call(
    () => _transport.post('/api/couple/bucket-list', {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (targetDate != null) 'targetDate': targetDate,
    }),
    (_) {},
  );

  Future<CoupleResult<void>> completeBucketListItem(int itemId) => _call(
    () => _transport.post('/api/couple/bucket-list/$itemId/complete', {}),
    (_) {},
  );

  // ============ MEMORIES ============

  Future<CoupleResult<List<CoupleMemory>>> getMemories() => _call(
    () => _transport.get('/api/couple/memories'),
    (r) => _list(r, 'memories', CoupleMemory.fromJson),
  );

  Future<CoupleResult<void>> addMemory({
    required String type,
    String? title,
    String? content,
    String? imageUrl,
    String? memoryDate,
    String? location,
  }) => _call(
    () => _transport.post('/api/couple/memories', {
      'type': type,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (memoryDate != null) 'memoryDate': memoryDate,
      if (location != null) 'location': location,
    }),
    (_) {},
  );

  // ============ INTERNALS ============

  Future<CoupleResult<T>> _call<T>(
    Future<Map<String, dynamic>> Function() request,
    T Function(Map<String, dynamic> response) decode,
  ) async {
    final Map<String, dynamic> response;
    try {
      response = await request();
    } on TimeoutException catch (e) {
      return _failed(
        CoupleFailureKind.network,
        'timeout',
        e,
      );
    } on SocketException catch (e) {
      return _failed(
        CoupleFailureKind.network,
        'no-connection',
        e,
      );
    } on http.ClientException catch (e) {
      return _failed(
        CoupleFailureKind.network,
        'unreachable',
        e,
      );
    } on FormatException catch (e) {
      return _failed(
        CoupleFailureKind.malformed,
        'malformed',
        e,
      );
    }

    if (response['success'] != true) {
      final error = response['error'];
      return _failed(_kindOf(error), _messageOf(error), error);
    }
    try {
      return CoupleOk(decode(response));
    } on FormatException catch (e) {
      return _failed(
        CoupleFailureKind.malformed,
        'malformed',
        e,
      );
    } on TypeError catch (e) {
      return _failed(
        CoupleFailureKind.malformed,
        'malformed',
        e,
      );
    }
  }

  CoupleFailed<T> _failed<T>(
    CoupleFailureKind kind,
    String message,
    Object? detail,
  ) {
    debugPrint('CoupleApiService: ${kind.name} - $detail');
    return CoupleFailed(CoupleFailure(kind, message, detail: '$detail'));
  }

  // The routes answer `{ success: false, error: "<english text>" }`; that text
  // is the only discriminator the shared HTTP client keeps.
  static final _serverNotInCouple = RegExp(r'^Not in a couple$');
  static final _serverNotFound = RegExp(r'^(Activity|Event) not found$');
  static final _serverFull = RegExp(r'^Event is full$');

  CoupleFailureKind _kindOf(Object? error) {
    final text = error is String ? error : '';
    if (_serverNotInCouple.hasMatch(text)) return CoupleFailureKind.notInCouple;
    if (_serverNotFound.hasMatch(text)) return CoupleFailureKind.notFound;
    if (_serverFull.hasMatch(text)) return CoupleFailureKind.full;
    return CoupleFailureKind.server;
  }

  String _messageOf(Object? error) => switch (_kindOf(error)) {
    CoupleFailureKind.notInCouple => 'not-in-couple',
    CoupleFailureKind.notFound => 'not-found',
    CoupleFailureKind.full => 'event-full',
    _ => 'server-error',
  };

  List<T> _list<T>(
    Map<String, dynamic> response,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = response[key];
    if (raw is! List) throw FormatException('$key is not a list');
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          fromJson(item)
        else
          throw FormatException('$key holds a non-object item'),
    ];
  }

  T _object<T>(
    Map<String, dynamic> response,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = response[key];
    if (raw is! Map<String, dynamic>) {
      throw FormatException('$key is not an object');
    }
    return fromJson(raw);
  }
}
