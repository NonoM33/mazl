import '../models/couple_activity.dart';
import '../models/couple_event.dart';
import '../models/couple_space.dart';
import 'couple_call.dart';

export 'couple_call.dart';

/// Couple content: activities feed, saved activities, events and the couple
/// space (stats, dates, bucket list, memories). The server is the truth
/// (docs/couple/CONTRAT.md section 0.3): a failure is reported, it never
/// becomes an empty list.
class CoupleApiService {
  CoupleApiService({CoupleTransport? transport})
    : _caller = CoupleCaller(transport: transport);

  final CoupleCaller _caller;
  CoupleTransport get _transport => _caller.transport;

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
    return _caller.call(
      () => _transport.get(path),
      (r) => _caller.list(r, 'activities', CoupleActivity.fromJson),
    );
  }

  Future<CoupleResult<CoupleActivity>> getActivity(int id) => _caller.call(
    () => _transport.get('/api/couple/activities/$id'),
    (r) => _caller.object(r, 'activity', CoupleActivity.fromJson),
  );

  Future<CoupleResult<void>> saveActivity(int activityId, {String? notes}) =>
      _caller.call(
        () => _transport.post('/api/couple/activities/$activityId/save', {
          if (notes != null) 'notes': notes,
        }),
        (_) {},
      );

  Future<CoupleResult<void>> passActivity(int activityId) => _caller.call(
    () => _transport.post('/api/couple/activities/$activityId/pass', {}),
    (_) {},
  );

  Future<CoupleResult<List<CoupleActivity>>> getSavedActivities() => _caller.call(
    () => _transport.get('/api/couple/saved'),
    (r) => _caller.list(r, 'activities', CoupleActivity.fromJson),
  );

  Future<CoupleResult<void>> removeSavedActivity(int activityId) =>
      _caller.call(() => _transport.delete('/api/couple/saved/$activityId'), (_) {});

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
    return _caller.call(
      () => _transport.get(path),
      (r) => _caller.list(r, 'events', CoupleEvent.fromJson),
    );
  }

  Future<CoupleResult<CoupleEvent>> getEvent(int id) => _caller.call(
    () => _transport.get('/api/couple/events/$id'),
    (r) => _caller.object(r, 'event', CoupleEvent.fromJson),
  );

  Future<CoupleResult<void>> registerForEvent(int eventId) => _caller.call(
    () => _transport.post('/api/couple/events/$eventId/register', {}),
    (_) {},
  );

  Future<CoupleResult<void>> cancelEventRegistration(int eventId) => _caller.call(
    () => _transport.delete('/api/couple/events/$eventId/register'),
    (_) {},
  );

  Future<CoupleResult<List<CoupleEvent>>> getRegisteredEvents() => _caller.call(
    () => _transport.get('/api/couple/events/registered'),
    (r) => _caller.list(r, 'events', CoupleEvent.fromJson),
  );

  // ============ STATS ============

  Future<CoupleResult<CoupleStatsSnapshot>> getStats() =>
      _caller.call(() => _transport.get('/api/couple/stats'), (r) {
        final stats = r['stats'];
        if (stats is! Map<String, dynamic>) {
          throw const FormatException('stats is not an object');
        }
        return CoupleStatsSnapshot(
          stats: CoupleStats.fromJson(stats),
          achievements: _caller.list(r, 'achievements', CoupleAchievement.fromJson),
        );
      });

  // ============ DATES ============

  Future<CoupleResult<List<CoupleDate>>> getDates() => _caller.call(
    () => _transport.get('/api/couple/dates'),
    (r) => _caller.list(r, 'dates', CoupleDate.fromJson),
  );

  Future<CoupleResult<void>> addDate({
    required String title,
    required String date,
    required String type,
    bool isRecurring = true,
    int remindDaysBefore = 7,
    String? notes,
  }) => _caller.call(
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

  Future<CoupleResult<List<BucketListItem>>> getBucketList() => _caller.call(
    () => _transport.get('/api/couple/bucket-list'),
    (r) => _caller.list(r, 'items', BucketListItem.fromJson),
  );

  Future<CoupleResult<void>> addBucketListItem({
    required String title,
    String? description,
    String? category,
    String? targetDate,
  }) => _caller.call(
    () => _transport.post('/api/couple/bucket-list', {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (targetDate != null) 'targetDate': targetDate,
    }),
    (_) {},
  );

  Future<CoupleResult<void>> completeBucketListItem(int itemId) => _caller.call(
    () => _transport.post('/api/couple/bucket-list/$itemId/complete', {}),
    (_) {},
  );

  // ============ MEMORIES ============

  Future<CoupleResult<List<CoupleMemory>>> getMemories() => _caller.call(
    () => _transport.get('/api/couple/memories'),
    (r) => _caller.list(r, 'memories', CoupleMemory.fromJson),
  );

  Future<CoupleResult<void>> addMemory({
    required String type,
    String? title,
    String? content,
    String? imageUrl,
    String? memoryDate,
    String? location,
  }) => _caller.call(
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
}
