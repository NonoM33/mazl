import 'demo_couple_daily_state.dart';
import 'demo_couple_fixtures.dart';
import 'demo_couple_state.dart';
import 'demo_photos.dart';
import 'demo_routes.dart';
import 'demo_store.dart';

/// Routes de l'espace couple quotidien en démo (docs/couple/ESPACE-COUPLE.md) :
/// mêmes formes et mêmes refus que le vrai serveur. Ces routes passent AVANT
/// le « tout autre chemin du couple rend 404 » de [DemoCoupleRoutes].
abstract final class DemoCoupleDailyRoutes {
  static DemoReply _ok(Map<String, dynamic> body) =>
      DemoReply({'success': true, ...body});

  static DemoReply _fail(int status, String error) =>
      DemoReply({'success': false, 'error': error}, status: status);

  static int _id(RegExpMatch m, [int group = 1]) => int.parse(m.group(group)!);

  static DemoCoupleState get _state => DemoStore.couple;
  static DemoCoupleDailyState get _daily => _state.daily;

  static DateTime _tick() {
    final now = DemoStore.clock();
    _state.settle(now);
    return now;
  }

  /// Une route qui exige un couple : 400 « Not in a couple », comme le serveur.
  static DemoHandler _inCouple(
    DemoReply Function(DemoRequest r, RegExpMatch m, DateTime now) handler,
  ) => (r, m) {
    final now = _tick();
    if (!_state.inCouple) return _fail(400, 'Not in a couple');
    return handler(r, m, now);
  };

  /// La conciergerie est réservée à MAZL Couple (402).
  static DemoHandler _premium(
    DemoReply Function(DemoRequest r, RegExpMatch m, DateTime now) handler,
  ) => _inCouple((r, m, now) {
    if (!_daily.premiumActive) {
      return _fail(402, 'couple_subscription_required');
    }
    return handler(r, m, now);
  });

  static Map<String, dynamic> premiumPayload(DateTime now) => {
    'active': _daily.premiumActive,
    'paidBy': _daily.premiumActive ? 'partner' : null,
    'renewsAt': _daily.premiumActive
        ? now.add(const Duration(days: 19)).toUtc().toIso8601String()
        : null,
  };

  // --- Aujourd'hui ---

  static String _partnerName() =>
      (_state.couple?['partner_name'] as String?) ?? 'Partenaire';

  static DemoReply _today(DemoRequest r, RegExpMatch m, DateTime now) {
    final couple = _state.couple!;
    final question = _daily.question();
    final events = DemoCoupleFixtures.events(now);
    final partner = _partnerName();
    final shabbat = _nextWeekday(now, DateTime.friday);
    final upcoming = <Map<String, dynamic>>[
      {
        'kind': 'ritual',
        'title': 'Shabbat ensemble',
        'at': DateTime(
          shabbat.year,
          shabbat.month,
          shabbat.day,
          18,
        ).toUtc().toIso8601String(),
        'subtitle': 'Allumage des bougies · Paris',
        'refId': 1,
      },
      {
        'kind': 'event',
        'title': events.first['title'],
        'at': events.first['event_date'],
        'subtitle': '${events.first['city']} · ${events.first['event_time']}',
        'refId': events.first['id'],
      },
      {
        'kind': 'date',
        'title': 'Un an de votre rencontre',
        'at': now.add(const Duration(days: 12)).toUtc().toIso8601String(),
        'subtitle': 'La conciergerie peut s\'en charger',
        'refId': 1,
      },
      for (final date in _state.dates())
        {
          'kind': 'date',
          'title': date['title'],
          'at': '${date['date']}',
          'subtitle': null,
          'refId': date['id'],
        },
    ]..sort((a, b) => '${a['at']}'.compareTo('${b['at']}'));
    final outing = _outings(now, null).firstWhere(
      (o) => o['kind'] == 'activity',
      orElse: () => <String, dynamic>{},
    );
    return _ok({
      'data': {
        'days': DemoCoupleDailyState.dayCount,
        'partner': {
          'id': couple['partner_id'],
          'name': partner,
          'picture': couple['partner_picture'],
        },
        'question': {
          'id': question['id'],
          'text': question['text'],
          'myAnswered': question['myAnswer'] != null,
          'partnerAnswered': true,
        },
        'upcoming': upcoming.take(5).toList(),
        'outing': outing.isEmpty ? null : outing,
        'mood': {
          'mine': _daily.myMood,
          'partner': DemoCoupleDailyState.partnerMood,
        },
        'checkin': {
          'due': _daily.myScores == null,
          'period': _daily.period(now),
        },
        'premium': premiumPayload(now),
      },
    });
  }

  static DateTime _nextWeekday(DateTime from, int weekday) {
    final day = DateTime(from.year, from.month, from.day);
    return day.add(Duration(days: (weekday - day.weekday + 7) % 7));
  }

  static DemoReply _mood(DemoRequest r, RegExpMatch m, DateTime now) {
    final mood = r.body['mood'];
    if (!const ['great', 'good', 'meh', 'talk'].contains(mood)) {
      return _fail(400, 'Invalid input');
    }
    _daily.myMood = mood as String;
    return _ok({});
  }

  // --- Sorties ---

  static List<Map<String, dynamic>> _outings(DateTime now, String? filter) {
    final all = <Map<String, dynamic>>[
      for (final e in DemoCoupleFixtures.events(now))
        {
          'id': e['id'],
          'kind': 'event',
          'title': e['title'],
          'subtitle': '${e['location']} · ${e['city']}',
          'imageUrl': DemoPhotos.outing(1000 + (e['id'] as int)),
          'city': e['city'],
          'startsAt': e['event_date'],
          'priceCents': e['price_cents'],
          'kosher': e['is_kosher'] == true,
          'saved': false,
        },
      for (final a in DemoCoupleFixtures.activities())
        {
          'id': a['id'],
          'kind': 'activity',
          'title': a['title'],
          'subtitle': '${a['location']} · ${a['city']}',
          'imageUrl': DemoPhotos.outing(a['id'] as int),
          'city': a['city'],
          'startsAt': null,
          'priceCents': a['price_cents'],
          'kosher': a['is_kosher'] == true,
          'saved': _state.isSaved(a['id'] as int),
        },
    ];
    final tomorrow = now.add(const Duration(days: 2));
    final week = now.add(const Duration(days: 8));
    bool within(Map<String, dynamic> o, DateTime limit) {
      final at = DateTime.tryParse('${o['startsAt']}');
      return at == null || at.isBefore(limit);
    }

    return switch (filter) {
      'tonight' => [
        for (final o in all)
          if (within(o, tomorrow) && o['kind'] == 'activity' ||
              o['kind'] == 'event' && within(o, tomorrow))
            o,
      ],
      'week' => [
        for (final o in all)
          if (within(o, week)) o,
      ],
      'kosher' => [
        for (final o in all)
          if (o['kosher'] == true) o,
      ],
      'cheap' => [
        for (final o in all)
          if ((o['priceCents'] as int?) != null &&
              (o['priceCents'] as int) <= 5000)
            o,
      ],
      'mazl' => [
        for (final o in all)
          if (o['kind'] == 'event') o,
      ],
      _ => all,
    };
  }

  static DemoReply _outingsRoute(DemoRequest r, RegExpMatch m, DateTime now) {
    final items = _outings(now, r.query['filter']);
    final featured = items.where((o) => o['kind'] == 'event').firstOrNull;
    return _ok({
      'data': {
        'featured': featured,
        'items': [
          for (final o in items)
            if (o != featured) o,
        ],
      },
    });
  }

  // --- Rituels ---

  static DemoReply _ritualPatch(DemoRequest r, RegExpMatch m, DateTime now) {
    final enabled = r.body['enabled'];
    if (enabled is! bool) return _fail(400, 'Invalid input');
    final ritual = _daily.setRitualEnabled(_id(m), enabled);
    return ritual == null
        ? _fail(404, 'Ritual not found')
        : _ok({'data': ritual});
  }

  // --- Question ---

  static DemoReply _coupleOnly(int coupleId, DemoReply Function() ok) =>
      _state.couple?['id'] == coupleId ? ok() : _fail(403, 'Forbidden');

  static DemoReply _answer(DemoRequest r, RegExpMatch m, DateTime now) {
    final coupleId = _id(m);
    return _coupleOnly(coupleId, () {
      final text = r.body['answer'];
      if (text is! String || !_daily.answer(_id(m, 2), text)) {
        return _fail(404, 'Question not found');
      }
      return _ok({});
    });
  }

  // --- Bilan ---

  static DemoReply _submitCheckin(DemoRequest r, RegExpMatch m, DateTime now) {
    final scores = <String, int>{};
    for (final theme in const ['talk', 'time', 'close']) {
      final value = r.body[theme];
      if (value is! num || value < 1 || value > 5) {
        return _fail(400, 'Invalid input');
      }
      scores[theme] = value.toInt();
    }
    if (!_daily.submitCheckin(scores)) {
      return _fail(409, 'checkin_already_done');
    }
    return _ok({'data': _daily.checkin(now)});
  }

  // --- Conciergerie ---

  static DemoReply _thread(Map<String, dynamic>? thread) =>
      thread == null ? _fail(404, 'Request not found') : _ok({'data': thread});

  static final List<DemoRoute> routes = [
    DemoRoute('GET', '/api/couple/today', _inCouple(_today)),
    DemoRoute('POST', '/api/couple/mood', _inCouple(_mood)),
    DemoRoute('GET', '/api/couple/outings', _inCouple(_outingsRoute)),
    DemoRoute(
      'GET',
      '/api/couple/rituals',
      _inCouple(
        (r, m, now) => _ok({
          'data': {'rituals': _daily.rituals()},
        }),
      ),
    ),
    DemoRoute(
      'POST',
      '/api/couple/rituals',
      _inCouple((r, m, now) {
        final title = r.body['title'];
        if (title is! String || title.trim().isEmpty) {
          return _fail(400, 'Invalid input');
        }
        return _ok({'data': _daily.addRitual(r.body)});
      }),
    ),
    DemoRoute('PATCH', '/api/couple/rituals/(\\d+)', _inCouple(_ritualPatch)),
    DemoRoute(
      'DELETE',
      '/api/couple/rituals/(\\d+)',
      _inCouple(
        (r, m, now) => _daily.deleteRitual(_id(m))
            ? _ok({})
            : _fail(404, 'Ritual not found'),
      ),
    ),
    DemoRoute(
      'PATCH',
      '/api/couple/(\\d+)/status',
      _inCouple((r, m, now) {
        final status = r.body['relationshipStatus'];
        const allowed = ['dating', 'in_relationship', 'engaged', 'married'];
        if (!allowed.contains(status)) return _fail(400, 'Invalid input');
        return _state.setStatus(_id(m), status as String)
            ? _ok({})
            : _fail(403, 'Forbidden');
      }),
    ),
    DemoRoute(
      'GET',
      '/api/couple/(\\d+)/question',
      _inCouple(
        (r, m, now) =>
            _coupleOnly(_id(m), () => _ok({'question': _daily.question()})),
      ),
    ),
    DemoRoute(
      'POST',
      '/api/couple/(\\d+)/question/(\\d+)/answer',
      _inCouple(_answer),
    ),
    DemoRoute(
      'GET',
      '/api/couple/(\\d+)/questions',
      _inCouple(
        (r, m, now) =>
            _coupleOnly(_id(m), () => _ok({'questions': _daily.history(now)})),
      ),
    ),
    DemoRoute(
      'GET',
      '/api/couple/checkin',
      _inCouple((r, m, now) => _ok({'data': _daily.checkin(now)})),
    ),
    DemoRoute('POST', '/api/couple/checkin', _inCouple(_submitCheckin)),
    DemoRoute(
      'GET',
      '/api/couple/concierge',
      _premium(
        (r, m, now) => _ok({
          'data': {'requests': _daily.conciergeList(now)},
        }),
      ),
    ),
    DemoRoute(
      'POST',
      '/api/couple/concierge',
      _premium((r, m, now) {
        final text = r.body['text'];
        if (text is! String || text.trim().isEmpty) {
          return _fail(400, 'Invalid input');
        }
        return _ok({'data': _daily.createRequest(r.body, now)});
      }),
    ),
    DemoRoute(
      'GET',
      '/api/couple/concierge/(\\d+)',
      _premium((r, m, now) => _thread(_daily.conciergeThread(_id(m), now))),
    ),
    DemoRoute(
      'POST',
      '/api/couple/concierge/(\\d+)/messages',
      _premium((r, m, now) {
        final text = r.body['text'];
        if (text is! String || text.trim().isEmpty) {
          return _fail(400, 'Invalid input');
        }
        return _thread(_daily.sendMessage(_id(m), text, now));
      }),
    ),
    DemoRoute(
      'POST',
      '/api/couple/concierge/(\\d+)/choose',
      _premium((r, m, now) {
        final index = r.body['index'];
        if (index is! int) return _fail(400, 'Invalid input');
        return _thread(_daily.choose(_id(m), index, now));
      }),
    ),
    DemoRoute(
      'POST',
      '/api/couple/concierge/(\\d+)/cancel',
      _premium((r, m, now) => _thread(_daily.cancel(_id(m), now))),
    ),
  ];
}
