import '../models/couple_daily.dart';
import 'auth_service.dart';
import 'couple_call.dart';

/// The routes of the daily couple space (docs/couple/ESPACE-COUPLE.md): today,
/// mood, outings, rituals, the question of the day, the monthly check-in and
/// the concierge.
///
/// A route the server does not have yet (404) is not an error for a list: it
/// reads as an empty one ([CoupleFailureKind.routeMissing] is turned into the
/// empty value by the methods that say so), so that a screen never crashes or
/// shows a failure for a feature that is simply not deployed.
class CoupleDailyApi {
  CoupleDailyApi({CoupleTransport? transport, int? Function()? callerId})
    : _caller = CoupleCaller(transport: transport),
      _callerId = callerId;

  /// The client the app uses: the concierge conversations tell the signed-in
  /// member's messages from the other member's.
  factory CoupleDailyApi.forApp() => CoupleDailyApi(
    callerId: () => int.tryParse(AuthService().currentUser?.id ?? ''),
  );

  final CoupleCaller _caller;

  /// Who is reading the concierge conversations: tells the member's own
  /// messages from the other member's.
  final int? Function()? _callerId;

  CoupleTransport get _transport => _caller.transport;

  /// Turns "the route does not exist" into [empty].
  Future<CoupleResult<T>> _orEmpty<T>(
    Future<CoupleResult<T>> call,
    T empty,
  ) async {
    final result = await call;
    return result.failureOrNull?.kind == CoupleFailureKind.routeMissing
        ? CoupleOk(empty)
        : result;
  }

  // ------------------------------------------------------------------ today

  /// `GET /api/couple/today`. A missing route stays a failure: the screen
  /// builds its page from the couple it already knows.
  Future<CoupleResult<CoupleToday>> getToday() => _caller.call(
    () => _transport.get('/api/couple/today'),
    (r) => CoupleToday.fromJson(couplePayload(r)),
  );

  Future<CoupleResult<void>> setMood(CoupleMoodChoice mood) => _caller.call(
    () => _transport.post('/api/couple/mood', {'mood': mood.wire}),
    (_) {},
  );

  // ---------------------------------------------------------------- outings

  Future<CoupleResult<OutingsPage>> getOutings([OutingFilter? filter]) =>
      _orEmpty(
        _caller.call(
          () => _transport.get(
            filter == null
                ? '/api/couple/outings'
                : '/api/couple/outings?filter=${filter.wire}',
          ),
          (r) => OutingsPage.fromJson(couplePayload(r)),
        ),
        OutingsPage.empty,
      );

  // --------------------------------------------------------------- rituals

  Future<CoupleResult<List<CoupleRitual>>> getRituals() => _orEmpty(
    _caller.call(
      () => _transport.get('/api/couple/rituals'),
      (r) => _caller.list(couplePayload(r), 'rituals', CoupleRitual.fromJson),
    ),
    const <CoupleRitual>[],
  );

  Future<CoupleResult<CoupleRitual>> setRitualEnabled(int id, bool enabled) =>
      _caller.call(
        () => _transport.patch('/api/couple/rituals/$id', {'enabled': enabled}),
        (r) => _ritual(r),
      );

  Future<CoupleResult<CoupleRitual>> addRitual({
    required String title,
    int? weekday,
    String? time,
    int remindMinutes = 60,
  }) => _caller.call(
    () => _transport.post('/api/couple/rituals', {
      'kind': 'custom',
      'title': title,
      'weekday': ?weekday,
      'time': ?time,
      'remind_minutes': remindMinutes,
      'enabled': true,
    }),
    (r) => _ritual(r),
  );

  Future<CoupleResult<void>> deleteRitual(int id) =>
      _caller.call(() => _transport.delete('/api/couple/rituals/$id'), (_) {});

  CoupleRitual _ritual(Map<String, dynamic> response) {
    final payload = couplePayload(response);
    final raw = payload['ritual'];
    return CoupleRitual.fromJson(raw is Map<String, dynamic> ? raw : payload);
  }

  // --------------------------------------------------------------- question

  /// `GET /api/couple/:coupleId/question`; `null` when the server has none.
  Future<CoupleResult<CoupleQuestion?>> getQuestion(int coupleId) => _orEmpty(
    _caller.call<CoupleQuestion?>(
      () => _transport.get('/api/couple/$coupleId/question'),
      (r) {
        final raw = r['question'];
        if (raw == null) return null;
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('object:question');
        }
        return CoupleQuestion.fromJson(raw);
      },
    ),
    null,
  );

  Future<CoupleResult<void>> answerQuestion({
    required int coupleId,
    required int questionId,
    required String answer,
  }) => _caller.call(
    () => _transport.post('/api/couple/$coupleId/question/$questionId/answer', {
      'answer': answer,
    }),
    (_) {},
  );

  Future<CoupleResult<List<CoupleQuestionEntry>>> getQuestionHistory(
    int coupleId,
  ) => _orEmpty(
    _caller.call(
      () => _transport.get('/api/couple/$coupleId/questions'),
      (r) => _caller.list(r, 'questions', CoupleQuestionEntry.fromJson),
    ),
    const <CoupleQuestionEntry>[],
  );

  // ---------------------------------------------------------------- checkin

  /// `GET /api/couple/checkin`; `null` when the server has none.
  Future<CoupleResult<CoupleCheckin?>> getCheckin() => _orEmpty(
    _caller.call<CoupleCheckin?>(
      () => _transport.get('/api/couple/checkin'),
      (r) => CoupleCheckin.fromJson(couplePayload(r)),
    ),
    null,
  );

  /// `POST /api/couple/checkin`; answers with the check-in as it now stands
  /// (the summary appears only once both answered).
  Future<CoupleResult<CoupleCheckin>> submitCheckin(CheckinScores scores) =>
      _caller.call(
        () => _transport.post('/api/couple/checkin', scores.toJson()),
        (r) => CoupleCheckin.fromJson(couplePayload(r)),
      );

  // -------------------------------------------------------------- concierge

  Future<CoupleResult<List<ConciergeSummary>>> getConcierge() => _orEmpty(
    _caller.call(
      () => _transport.get('/api/couple/concierge'),
      (r) =>
          _caller.list(couplePayload(r), 'requests', ConciergeSummary.fromJson),
    ),
    const <ConciergeSummary>[],
  );

  Future<CoupleResult<ConciergeThread>> createConcierge({
    required String text,
    DateTime? wantedAt,
    String? city,
    ConciergeKind? kind,
  }) => _caller.call(
    () => _transport.post('/api/couple/concierge', {
      'text': text,
      if (wantedAt != null) 'wantedAt': _day(wantedAt),
      'city': ?city,
      if (kind != null) 'kind': kind.name,
    }),
    _thread,
  );

  Future<CoupleResult<ConciergeThread>> getConciergeThread(int id) =>
      _caller.call(() => _transport.get('/api/couple/concierge/$id'), _thread);

  Future<CoupleResult<ConciergeThread>> sendConciergeMessage(
    int id,
    String text,
  ) => _caller.call(
    () => _transport.post('/api/couple/concierge/$id/messages', {'text': text}),
    _thread,
  );

  Future<CoupleResult<ConciergeThread>> chooseConciergeOption(
    int id,
    int index,
  ) => _caller.call(
    () => _transport.post('/api/couple/concierge/$id/choose', {'index': index}),
    _thread,
  );

  Future<CoupleResult<ConciergeThread>> cancelConcierge(int id) => _caller.call(
    () => _transport.post('/api/couple/concierge/$id/cancel', {}),
    _thread,
  );

  ConciergeThread _thread(Map<String, dynamic> response) =>
      ConciergeThread.fromJson(
        couplePayload(response),
        callerId: _callerId?.call(),
      );

  static String _day(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
