import 'demo_couple_state.dart';
import 'demo_fixtures.dart';
import 'demo_routes.dart';
import 'demo_store.dart';

/// Routes du mode couple en démo : mêmes formes et mêmes refus que le vrai
/// serveur (`docs/couple/CONTRAT.md`, `src/features/couple/`). Aucune ne rend
/// 503 : un chemin `/api/couple…` inconnu rend 404, comme le routeur du
/// serveur.
abstract final class DemoCoupleRoutes {
  static DemoReply _ok(Map<String, dynamic> body) =>
      DemoReply({'success': true, ...body});

  static DemoReply _fail(int status, String error) =>
      DemoReply({'success': false, 'error': error}, status: status);

  static int _id(RegExpMatch m) => int.parse(m.group(1)!);

  static DemoCoupleState get _state => DemoStore.couple;

  /// Relit l'état à l'horloge de la démo : c'est ici qu'une demande assez
  /// ancienne devient un couple.
  static DateTime _tick() {
    final now = DemoStore.clock();
    _state.settle(now);
    return now;
  }

  /// Route qui exige un couple : 400 « Not in a couple » sinon, comme le
  /// serveur.
  static DemoHandler _inCouple(
    DemoReply Function(DemoRequest r, RegExpMatch m, DateTime now) handler,
  ) => (r, m) {
    final now = _tick();
    if (!_state.inCouple) return _fail(400, 'Not in a couple');
    return handler(r, m, now);
  };

  static DemoHandler _open(
    DemoReply Function(DemoRequest r, RegExpMatch m, DateTime now) handler,
  ) =>
      (r, m) => handler(r, m, _tick());

  static int _int(DemoRequest r, String key, int fallback) =>
      int.tryParse(r.query[key] ?? '') ?? fallback;

  static Map<String, dynamic> _couplePayload() => {
    'couple': _state.couple,
    'milestones': <Object>[],
  };

  // --- Demandes et couple ---

  static DemoReply _sendRequest(DemoRequest r, RegExpMatch m, DateTime now) {
    final raw = r.body['target_user_id'];
    final target = raw is num ? raw.toInt() : 0;
    if (target <= 0) return _fail(400, 'target_user_id required');
    if (target == DemoFixtures.meId) {
      return _fail(400, 'Cannot send a couple request to yourself');
    }
    if (!DemoStore.isMatch(target)) return _fail(403, 'not_matched');
    if (_state.inCouple) {
      return _fail(400, 'One of the users is already in a couple');
    }
    if (_state.hasPendingWith(target)) {
      return _fail(400, 'A pending couple request already exists');
    }
    return _ok({'request': _state.send(target, now)});
  }

  static DemoReply _respond(DemoRequest r, RegExpMatch m, DateTime now) {
    final action = r.body['action'];
    if (action != 'accept' && action != 'reject') {
      return _fail(400, 'Invalid input');
    }
    return switch (_state.respond(_id(m))) {
      DemoRequestOutcome.forbidden => _fail(403, 'Forbidden'),
      _ => _fail(404, 'Couple request not found'),
    };
  }

  static DemoReply _cancel(DemoRequest r, RegExpMatch m, DateTime now) =>
      switch (_state.cancel(_id(m))) {
        DemoRequestOutcome.ok => _ok({}),
        DemoRequestOutcome.notPending => _fail(
          409,
          'Couple request is no longer pending',
        ),
        _ => _fail(404, 'Couple request not found'),
      };

  static DemoReply _end(DemoRequest r, RegExpMatch m, DateTime now) =>
      _state.end(_id(m)) ? _ok({}) : _fail(403, 'Forbidden');

  // --- Activités ---

  static DemoReply _activityDetail(DemoRequest r, RegExpMatch m, DateTime n) {
    final activity = _state.activity(_id(m));
    return activity == null
        ? _fail(404, 'Activity not found')
        : _ok({'activity': activity});
  }

  static DemoReply _saveActivity(DemoRequest r, RegExpMatch m, DateTime now) {
    if (_state.activity(_id(m)) == null) {
      return _fail(404, 'Activity not found');
    }
    final notes = r.body['notes'];
    _state.save(_id(m), notes is String ? notes : null, now);
    return _ok({});
  }

  static DemoReply _passActivity(DemoRequest r, RegExpMatch m, DateTime now) {
    if (_state.activity(_id(m)) == null) {
      return _fail(404, 'Activity not found');
    }
    _state.pass(_id(m));
    return _ok({});
  }

  // --- Évènements ---

  static DemoReply _eventDetail(DemoRequest r, RegExpMatch m, DateTime now) {
    final event = _state.event(_id(m), now);
    return event == null
        ? _fail(404, 'Event not found')
        : _ok({'event': event});
  }

  static DemoReply _registerEvent(DemoRequest r, RegExpMatch m, DateTime now) {
    final event = _state.event(_id(m), now);
    if (event == null) return _fail(404, 'Event not found');
    final registration = _state.register(event, now);
    return registration == null
        ? _fail(400, 'Event is full')
        : _ok({'registration': registration});
  }

  // --- Contenus propres au couple ---

  static DemoReply _complete(DemoRequest r, RegExpMatch m, DateTime now) {
    final item = _state.completeBucketItem(_id(m), now);
    return item == null
        ? _fail(404, 'Bucket list item not found')
        : _ok({'item': item});
  }

  static final List<DemoRoute> routes = [
    DemoRoute('POST', '/api/couple', (r, m) {
      _tick();
      return _fail(403, 'couple_request_required');
    }),
    DemoRoute('GET', '/api/couple', (r, m) {
      _tick();
      return _ok(_couplePayload());
    }),
    DemoRoute('POST', '/api/couple/request', _open(_sendRequest)),
    DemoRoute('GET', '/api/couple/requests', (r, m) {
      _tick();
      return _ok({'sent': _state.sentViews(), 'received': <Object>[]});
    }),
    DemoRoute('PUT', '/api/couple/request/(\\d+)', _open(_respond)),
    DemoRoute('DELETE', '/api/couple/request/(\\d+)', _open(_cancel)),
    DemoRoute('POST', '/api/couple/archive-conversations', (r, m) {
      _tick();
      return _ok({});
    }),
    DemoRoute('DELETE', '/api/couple/(\\d+)', _open(_end)),

    DemoRoute(
      'GET',
      '/api/couple/activities',
      _inCouple(
        (r, m, now) => _ok({
          'activities': _state.feed(
            _int(r, 'limit', 20),
            _int(r, 'offset', 0),
            r.query['category'],
          ),
        }),
      ),
    ),
    DemoRoute('GET', '/api/couple/activities/(\\d+)', _open(_activityDetail)),
    DemoRoute(
      'POST',
      '/api/couple/activities/(\\d+)/save',
      _inCouple(_saveActivity),
    ),
    DemoRoute(
      'POST',
      '/api/couple/activities/(\\d+)/pass',
      _inCouple(_passActivity),
    ),
    DemoRoute(
      'GET',
      '/api/couple/saved',
      _inCouple((r, m, now) => _ok({'activities': _state.saved()})),
    ),
    DemoRoute(
      'DELETE',
      '/api/couple/saved/(\\d+)',
      _inCouple((r, m, now) {
        _state.removeSaved(_id(m));
        return _ok({});
      }),
    ),

    DemoRoute(
      'GET',
      '/api/couple/events',
      _open(
        (r, m, now) => _ok({
          'events': _state.events(
            now,
            _int(r, 'limit', 20),
            _int(r, 'offset', 0),
            r.query['category'],
          ),
        }),
      ),
    ),
    DemoRoute(
      'GET',
      '/api/couple/events/registered',
      _inCouple((r, m, now) => _ok({'events': _state.registeredEvents(now)})),
    ),
    DemoRoute('GET', '/api/couple/events/(\\d+)', _open(_eventDetail)),
    DemoRoute(
      'POST',
      '/api/couple/events/(\\d+)/register',
      _inCouple(_registerEvent),
    ),
    DemoRoute(
      'DELETE',
      '/api/couple/events/(\\d+)/register',
      _inCouple((r, m, now) {
        _state.unregister(_id(m));
        return _ok({});
      }),
    ),

    DemoRoute(
      'GET',
      '/api/couple/dates',
      _inCouple((r, m, now) => _ok({'dates': _state.dates()})),
    ),
    DemoRoute(
      'POST',
      '/api/couple/dates',
      _inCouple((r, m, now) => _ok({'date': _state.addDate(r.body, now)})),
    ),
    DemoRoute(
      'GET',
      '/api/couple/bucket-list',
      _inCouple((r, m, now) => _ok({'items': _state.bucketList()})),
    ),
    DemoRoute(
      'POST',
      '/api/couple/bucket-list',
      _inCouple(
        (r, m, now) => _ok({'item': _state.addBucketItem(r.body, now)}),
      ),
    ),
    DemoRoute(
      'POST',
      '/api/couple/bucket-list/(\\d+)/complete',
      _inCouple(_complete),
    ),
    DemoRoute(
      'GET',
      '/api/couple/memories',
      _inCouple((r, m, now) => _ok({'memories': _state.memories()})),
    ),
    DemoRoute(
      'POST',
      '/api/couple/memories',
      _inCouple((r, m, now) => _ok({'memory': _state.addMemory(r.body, now)})),
    ),
    DemoRoute(
      'GET',
      '/api/couple/stats',
      _inCouple(
        (r, m, now) =>
            _ok({'stats': _state.stats(), 'achievements': <Object>[]}),
      ),
    ),

    // Tout autre chemin du mode couple : 404, jamais 503.
    DemoRoute('*', '/api/couple(?:/.*)?', (r, m) => _fail(404, 'Not Found')),
  ];
}
