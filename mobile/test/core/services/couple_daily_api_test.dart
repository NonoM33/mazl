import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_daily.dart';
import 'package:mazl/core/services/couple_call.dart';
import 'package:mazl/core/services/couple_daily_api.dart';

import '../../mocks/fake_couple_transport.dart';

Map<String, dynamic> _ok(Map<String, dynamic> body) => {
  'success': true,
  ...body,
};
Map<String, dynamic> _error(String text) => {'success': false, 'error': text};

Map<String, dynamic> _thread() => {
  'request': {'id': 7, 'title': 'Dîner', 'status': 'proposed'},
  'messages': [
    {'id': 1, 'role': 'member', 'text': 'Un dîner.'},
  ],
};

void main() {
  late FakeCoupleTransport transport;
  late CoupleDailyApi api;

  setUp(() {
    transport = FakeCoupleTransport();
    api = CoupleDailyApi(transport: transport, callerId: () => 12);
  });

  group('routes the server does not have yet', () {
    // A server older than the contract answers 404; Hono's own 404 carries
    // no JSON, `decodeCoupleBody` turns it into this refusal.
    test('a list reads as empty, never as a failure', () async {
      for (final path in [
        'GET /api/couple/outings',
        'GET /api/couple/rituals',
        'GET /api/couple/12/questions',
        'GET /api/couple/concierge',
      ]) {
        transport.reply(path, _error('not_found'));
      }
      expect((await api.getOutings()).valueOrNull?.items, isEmpty);
      expect((await api.getRituals()).valueOrNull, isEmpty);
      expect((await api.getQuestionHistory(12)).valueOrNull, isEmpty);
      expect((await api.getConcierge()).valueOrNull, isEmpty);
    });

    test('the question and the check-in read as absent', () async {
      transport
        ..reply('GET /api/couple/12/question', _error('Not Found'))
        ..reply('GET /api/couple/checkin', _error('Not Found'));
      final question = await api.getQuestion(12);
      expect(question.isOk, isTrue);
      expect(question.valueOrNull, isNull);
      final checkin = await api.getCheckin();
      expect(checkin.isOk, isTrue);
      expect(checkin.valueOrNull, isNull);
    });

    test('today stays a failure of kind routeMissing', () async {
      transport.reply('GET /api/couple/today', _error('Not Found'));
      expect(
        (await api.getToday()).failureOrNull?.kind,
        CoupleFailureKind.routeMissing,
      );
    });

    test('a 404 without JSON is the same refusal', () {
      expect(decodeCoupleBody(404, '404 Not Found'), {
        'success': false,
        'error': 'not_found',
      });
      expect(
        () => decodeCoupleBody(500, '<html>oops</html>'),
        throwsFormatException,
      );
      expect(decodeCoupleBody(402, '{"success":false,"error":"x"}'), {
        'success': false,
        'error': 'x',
      });
    });
  });

  group('refusals', () {
    test('402 couple_subscription_required, 429 and 409 have a kind', () async {
      transport
        ..reply(
          'GET /api/couple/concierge',
          _error('couple_subscription_required'),
        )
        ..reply(
          'POST /api/couple/concierge/7/messages',
          _error('concierge_rate_limited'),
        )
        ..reply('POST /api/couple/checkin', _error('checkin_already_done'));
      expect(
        (await api.getConcierge()).failureOrNull?.kind,
        CoupleFailureKind.subscriptionRequired,
      );
      expect(
        (await api.sendConciergeMessage(7, 'Bonjour')).failureOrNull?.kind,
        CoupleFailureKind.rateLimited,
      );
      expect(
        (await api.submitCheckin(
          const CheckinScores(talk: 3, time: 3, close: 3),
        )).failureOrNull?.kind,
        CoupleFailureKind.alreadyDone,
      );
    });

    test('a network failure is network, an odd body is malformed', () async {
      transport
        ..fail('GET /api/couple/today', const SocketException('down'))
        ..reply('GET /api/couple/checkin', _ok({'data': 'oops'}));
      expect(
        (await api.getToday()).failureOrNull?.kind,
        CoupleFailureKind.network,
      );
      expect(
        (await api.getCheckin()).failureOrNull?.kind,
        CoupleFailureKind.malformed,
      );
    });

    test(
      'a field of the wrong shape is malformed, not an empty value',
      () async {
        transport.reply(
          'GET /api/couple/today',
          _ok({
            'data': {
              'days': 'many',
              'partner': {'id': 1, 'name': 'D'},
            },
          }),
        );
        expect(
          (await api.getToday()).failureOrNull?.kind,
          CoupleFailureKind.malformed,
        );
      },
    );
  });

  group('requests', () {
    test('outings: the filter goes in the query', () async {
      transport.reply(
        'GET /api/couple/outings?filter=kosher',
        _ok({
          'data': {'featured': null, 'items': <Object>[]},
        }),
      );
      expect((await api.getOutings(OutingFilter.kosher)).isOk, isTrue);
      expect(transport.count('GET /api/couple/outings?filter=kosher'), 1);
    });

    test('mood, ritual switch and ritual creation', () async {
      transport
        ..reply('POST /api/couple/mood', _ok({}))
        ..reply(
          'PATCH /api/couple/rituals/3',
          _ok({
            'data': {
              'id': 3,
              'kind': 'weekly',
              'title': 'Appeler les parents',
              'enabled': true,
            },
          }),
        )
        ..reply(
          'POST /api/couple/rituals',
          _ok({
            'data': {
              'ritual': {
                'id': 9,
                'kind': 'custom',
                'title': 'Marche',
                'enabled': true,
              },
            },
          }),
        );
      await api.setMood(CoupleMoodChoice.talk);
      expect(transport.bodies['POST /api/couple/mood'], {'mood': 'talk'});

      final ritual = (await api.setRitualEnabled(3, true)).valueOrNull;
      expect(ritual?.enabled, isTrue);
      expect(transport.bodies['PATCH /api/couple/rituals/3'], {
        'enabled': true,
      });

      final added = (await api.addRitual(
        title: 'Marche',
        weekday: 0,
      )).valueOrNull;
      expect(added?.id, 9);
      expect(
        transport.bodies['POST /api/couple/rituals'],
        containsPair('kind', 'custom'),
      );
      expect(
        transport.bodies['POST /api/couple/rituals'],
        containsPair('weekday', 0),
      );
      expect(
        transport.bodies['POST /api/couple/rituals']!.containsKey('time'),
        isFalse,
      );
    });

    test('the answer goes to the question of the couple', () async {
      transport.reply('POST /api/couple/12/question/8/answer', _ok({}));
      final result = await api.answerQuestion(
        coupleId: 12,
        questionId: 8,
        answer: 'Le café.',
      );
      expect(result.isOk, isTrue);
      expect(transport.bodies['POST /api/couple/12/question/8/answer'], {
        'answer': 'Le café.',
      });
    });

    test('the check-in sends the three notes', () async {
      transport.reply(
        'POST /api/couple/checkin',
        _ok({
          'data': {
            'period': '2026-11',
            'mine': {'talk': 4, 'time': 2, 'close': 5},
            'partnerDone': false,
            'summary': null,
          },
        }),
      );
      final checkin = (await api.submitCheckin(
        const CheckinScores(talk: 4, time: 2, close: 5),
      )).valueOrNull;
      expect(checkin?.mine?.close, 5);
      expect(transport.bodies['POST /api/couple/checkin'], {
        'talk': 4,
        'time': 2,
        'close': 5,
      });
    });

    test('a concierge request: text, day, city and kind', () async {
      transport.reply('POST /api/couple/concierge', _ok({'data': _thread()}));
      await api.createConcierge(
        text: 'Un dîner',
        wantedAt: DateTime(2026, 11, 9),
        city: 'Paris',
        kind: ConciergeKind.table,
      );
      expect(transport.bodies['POST /api/couple/concierge'], {
        'text': 'Un dîner',
        'wantedAt': '2026-11-09',
        'city': 'Paris',
        'kind': 'table',
      });
    });

    test('choosing an idea and cancelling answer with the thread', () async {
      transport
        ..reply('POST /api/couple/concierge/7/choose', _ok({'data': _thread()}))
        ..reply(
          'POST /api/couple/concierge/7/cancel',
          _ok({'data': _thread()}),
        );
      final chosen = await api.chooseConciergeOption(7, 2);
      expect(chosen.valueOrNull?.request.id, 7);
      expect(transport.bodies['POST /api/couple/concierge/7/choose'], {
        'index': 2,
      });
      expect((await api.cancelConcierge(7)).isOk, isTrue);
    });

    test('the thread tells my messages from my partner\'s', () async {
      transport.reply(
        'GET /api/couple/concierge/7',
        _ok({
          'request': {'id': 7, 'title': 'T', 'status': 'new'},
          'messages': [
            {'id': 1, 'role': 'member', 'authorId': 12, 'text': 'a'},
            {'id': 2, 'role': 'member', 'authorId': 45, 'text': 'b'},
          ],
        }),
      );
      final thread = (await api.getConciergeThread(7)).valueOrNull!;
      expect([for (final m in thread.messages) m.mine], [true, false]);
    });
  });
}
