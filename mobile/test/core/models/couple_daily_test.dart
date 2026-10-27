import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_daily.dart';

// The shapes below are written from docs/couple/ESPACE-COUPLE.md (§1 to §7),
// not from the decoders.

Map<String, dynamic> _outing({
  Object? kind = 'activity',
  Object? title = 'Spa',
}) => {
  'id': 4,
  'kind': kind,
  'title': title,
  'subtitle': 'Marais',
  'imageUrl': 'https://example.com/spa.jpg',
  'city': 'Paris',
  'startsAt': null,
  'priceCents': 12000,
  'kosher': true,
  'saved': false,
};

Map<String, dynamic> _today() => {
  'days': 214,
  'partner': {'id': 45, 'name': 'David', 'picture': null},
  'question': {
    'id': 8,
    'text': 'Quel geste ?',
    'myAnswered': false,
    'partnerAnswered': true,
  },
  'upcoming': [
    {
      'kind': 'date',
      'title': 'Un an',
      'at': '2026-11-09T08:00:00.000Z',
      'subtitle': 'Dans 12 jours',
      'refId': 3,
    },
  ],
  'outing': null,
  'mood': {'mine': null, 'partner': 'good'},
  'checkin': {'due': true, 'period': '2026-11'},
  'premium': {'active': true, 'paidBy': 'partner', 'renewsAt': null},
};

void main() {
  group('couplePayload', () {
    test('reads the data envelope, else the answer itself', () {
      expect(
        couplePayload({
          'success': true,
          'data': {'a': 1},
        }),
        {'a': 1},
      );
      expect(couplePayload({'success': true, 'a': 1}), {
        'success': true,
        'a': 1,
      });
    });
  });

  group('CoupleToday', () {
    test('decodes the documented answer', () {
      final today = CoupleToday.fromJson(_today());
      expect(today.days, 214);
      expect(today.partnerName, 'David');
      expect(today.partnerPicture, isNull);
      expect(today.question?.partnerAnswered, isTrue);
      expect(today.question?.myAnswered, isFalse);
      expect(today.upcoming.single.kind, CoupleUpcomingKind.date);
      expect(today.upcoming.single.at.toUtc().month, 11);
      expect(today.outing, isNull);
      expect(today.myMood, isNull);
      expect(today.partnerMood, CoupleMoodChoice.good);
      expect(today.checkinDue, isTrue);
      expect(today.checkinPeriod, '2026-11');
      expect(today.premium.active, isTrue);
      expect(today.premium.paidBy, CouplePayer.partner);
    });

    test('a missing partner is malformed, not a default', () {
      final json = _today()..remove('partner');
      expect(() => CoupleToday.fromJson(json), throwsFormatException);
    });

    test('an upcoming item of an unknown kind is malformed', () {
      final json = _today();
      (json['upcoming'] as List).first['kind'] = 'party';
      expect(() => CoupleToday.fromJson(json), throwsFormatException);
    });

    test('a server without premium or mood reads as not subscribed', () {
      final json = _today()
        ..remove('premium')
        ..remove('mood');
      final today = CoupleToday.fromJson(json);
      expect(today.premium.active, isFalse);
      expect(today.premium.paidBy, isNull);
      expect(today.myMood, isNull);
    });
  });

  group('CouplePremium', () {
    test('anything but an object is inactive', () {
      expect(CouplePremium.fromJson(null).active, isFalse);
      expect(CouplePremium.fromJson('yes').active, isFalse);
    });

    test('active needs a true, not a truthy value', () {
      expect(CouplePremium.fromJson({'active': 'true'}).active, isFalse);
      expect(CouplePremium.fromJson({'active': true}).active, isTrue);
    });
  });

  group('Outing', () {
    test('decodes camelCase and snake_case keys', () {
      final camel = Outing.fromJson(_outing());
      expect(camel.imageUrl, 'https://example.com/spa.jpg');
      expect(camel.priceCents, 12000);
      expect(camel.kosher, isTrue);
      final snake = Outing.fromJson({
        'id': 1,
        'kind': 'event',
        'title': 'Dîner',
        'image_url': 'https://example.com/a.jpg',
        'starts_at': '2026-11-06T18:30:00Z',
        'price_cents': '3500',
      });
      expect(snake.isEvent, isTrue);
      expect(snake.imageUrl, 'https://example.com/a.jpg');
      expect(snake.startsAt, isNotNull);
      expect(snake.priceCents, 3500);
    });

    test('an unknown kind or a missing title is malformed', () {
      expect(
        () => Outing.fromJson(_outing(kind: 'spa')),
        throwsFormatException,
      );
      expect(
        () => Outing.fromJson(_outing(title: null)),
        throwsFormatException,
      );
      expect(() => Outing.fromJson(_outing(title: '')), throwsFormatException);
    });

    test('copyWith only flips the saved flag', () {
      final saved = Outing.fromJson(_outing()).copyWith(saved: true);
      expect(saved.saved, isTrue);
      expect(saved.title, 'Spa');
    });
  });

  group('OutingsPage', () {
    test('a featured outing and the items', () {
      final page = OutingsPage.fromJson({
        'featured': _outing(kind: 'event'),
        'items': [_outing(), _outing()],
      });
      expect(page.featured?.isEvent, isTrue);
      expect(page.items, hasLength(2));
    });

    test('items must be a list', () {
      expect(
        () => OutingsPage.fromJson({'featured': null}),
        throwsFormatException,
      );
    });
  });

  group('CoupleRitual', () {
    test('decodes the table columns and the answer spelling', () {
      final ritual = CoupleRitual.fromJson({
        'id': 2,
        'kind': 'weekly',
        'title': 'Soirée sans écran',
        'weekday': 2,
        'time': '20:00',
        'enabled': false,
        'remind_minutes': 60,
      });
      expect(ritual.kind, CoupleRitualKind.weekly);
      expect(ritual.weekday, 2);
      expect(ritual.time, '20:00');
      expect(ritual.enabled, isFalse);
      expect(ritual.remindMinutes, 60);
      expect(ritual.copyWith(enabled: true).enabled, isTrue);
    });

    test('Shabbat has no fixed time', () {
      final ritual = CoupleRitual.fromJson({
        'id': 1,
        'kind': 'shabbat',
        'title': 'Shabbat ensemble',
        'weekday': 5,
        'time': null,
        'enabled': true,
        'remindMinutes': 60,
      });
      expect(ritual.time, isNull);
      expect(ritual.remindMinutes, 60);
    });

    test('an unknown kind is malformed', () {
      expect(
        () => CoupleRitual.fromJson({'id': 1, 'kind': 'x', 'title': 'a'}),
        throwsFormatException,
      );
    });
  });

  group('CoupleQuestion', () {
    test('the partner answer stays null until I answered', () {
      final unanswered = CoupleQuestion.fromJson({
        'id': 8,
        'text': 'Quel geste ?',
        'myAnswer': null,
        'partnerAnswer': null,
      });
      expect(unanswered.answered, isFalse);
      expect(unanswered.partnerAnswer, isNull);
      final answered = CoupleQuestion.fromJson({
        'id': 8,
        'text': 'Quel geste ?',
        'myAnswer': 'Le café.',
        'partnerAnswer': 'Les fleurs.',
      });
      expect(answered.answered, isTrue);
      expect(answered.partnerAnswer, 'Les fleurs.');
    });

    test('a history line needs my answer', () {
      expect(
        () => CoupleQuestionEntry.fromJson({'id': 1, 'text': 'Q'}),
        throwsFormatException,
      );
      final entry = CoupleQuestionEntry.fromJson({
        'id': 1,
        'text': 'Q',
        'myAnswer': 'A',
        'partnerAnswer': null,
        'askedOn': '2026-10-26',
      });
      expect(entry.partnerAnswer, isNull);
      expect(entry.askedOn?.day, 26);
    });
  });

  group('CoupleCheckin', () {
    test('before anybody answered', () {
      final checkin = CoupleCheckin.fromJson({
        'period': '2026-11',
        'mine': null,
        'partnerDone': false,
        'summary': null,
      });
      expect(checkin.answered, isFalse);
      expect(checkin.summary, isNull);
    });

    test('once both answered: the summary, never the other notes', () {
      final checkin = CoupleCheckin.fromJson({
        'period': '2026-11',
        'mine': {'talk': 4, 'time': 2, 'close': 5},
        'partnerDone': true,
        'summary': {'aligned': 2, 'lowest': 'time', 'trend': 'down'},
      });
      expect(checkin.mine?.scoreOf(CheckinTheme.time), 2);
      expect(checkin.summary?.aligned, 2);
      expect(checkin.summary?.lowest, CheckinTheme.time);
      expect(checkin.summary?.trend, CheckinTrend.down);
    });

    test('the trend may be null (first month)', () {
      final summary = CheckinSummary.fromJson({
        'aligned': 3,
        'lowest': 'talk',
        'trend': null,
      });
      expect(summary.trend, isNull);
    });

    test('a note outside 1..5 and an aligned outside 0..3 are malformed', () {
      expect(
        () => CheckinScores.fromJson({'talk': 6, 'time': 1, 'close': 1}),
        throwsFormatException,
      );
      expect(
        () => CheckinSummary.fromJson({'aligned': 4, 'lowest': 'talk'}),
        throwsFormatException,
      );
      expect(
        () => CheckinSummary.fromJson({'aligned': 1, 'lowest': 'money'}),
        throwsFormatException,
      );
    });

    test('scores serialize to the body of POST /api/couple/checkin', () {
      expect(const CheckinScores(talk: 4, time: 2, close: 5).toJson(), {
        'talk': 4,
        'time': 2,
        'close': 5,
      });
    });
  });

  group('concierge', () {
    Map<String, dynamic> summary({
      Object? step = 1,
      Object? status = 'proposed',
    }) => {
      'id': 7,
      'title': 'Dîner surprise',
      'status': status,
      'wantedAt': '2026-11-09',
      'updatedAt': '2026-10-27T08:00:00Z',
      'step': step,
    };

    test('a summary with its step', () {
      final line = ConciergeSummary.fromJson(
        summary(step: 2, status: 'chosen'),
      );
      expect(line.status, ConciergeStatus.chosen);
      expect(line.step, 2);
      expect(line.isOpen, isTrue);
      expect(
        ConciergeSummary.fromJson(summary(status: 'cancelled')).isOpen,
        isFalse,
      );
    });

    test('"new" is the status of a request the assistant could not answer', () {
      expect(
        ConciergeSummary.fromJson(summary(status: 'new')).status,
        ConciergeStatus.fresh,
      );
    });

    test('an unknown status or a step outside 1..3 is malformed', () {
      expect(
        () => ConciergeSummary.fromJson(summary(status: 'lost')),
        throwsFormatException,
      );
      expect(
        () => ConciergeSummary.fromJson(summary(step: 4)),
        throwsFormatException,
      );
    });

    test('a thread: options, messages and whose they are', () {
      final thread = ConciergeThread.fromJson({
        'request': {
          'id': 7,
          'title': 'Dîner surprise',
          'status': 'proposed',
          'wanted_at': '2026-11-09',
          'city': 'Paris 16e',
          'options': [
            {
              'title': 'Restaurant casher',
              'details': 'Salle calme',
              'priceHint': 'environ 120 €',
            },
            {'title': 'Dîner à domicile', 'details': 'Un chef'},
          ],
          'chosen_index': null,
        },
        'messages': [
          {
            'id': 1,
            'role': 'member',
            'authorId': 12,
            'text': 'Un dîner calme.',
            'createdAt': '2026-10-27T08:00:00Z',
          },
          {'id': 2, 'role': 'member', 'authorId': 45, 'text': 'Sans musique.'},
          {
            'id': 3,
            'role': 'assistant',
            'authorId': null,
            'text': 'Trois idées.',
          },
          {'id': 4, 'role': 'staff', 'text': 'Réservé.'},
        ],
      }, callerId: 12);
      expect(thread.request.canChoose, isTrue);
      expect(thread.request.options.first.priceHint, 'environ 120 €');
      expect(thread.request.options.last.priceHint, isNull);
      expect(thread.request.chosenIndex, isNull);
      expect(thread.request.wantedAt?.day, 9);
      expect(
        [for (final m in thread.messages) m.mine],
        [true, false, false, false],
      );
      expect(thread.messages.map((m) => m.role), [
        ConciergeRole.member,
        ConciergeRole.member,
        ConciergeRole.assistant,
        ConciergeRole.staff,
      ]);
    });

    test('once chosen there is nothing left to choose', () {
      final request = ConciergeRequest.fromJson({
        'id': 7,
        'title': 'T',
        'status': 'chosen',
        'options': [
          {'title': 'A', 'details': 'a'},
        ],
        'chosenIndex': 0,
      });
      expect(request.canChoose, isFalse);
      expect(request.chosenIndex, 0);
    });

    test('a thread without its messages is malformed', () {
      expect(
        () => ConciergeThread.fromJson({
          'request': {'id': 1, 'title': 'T', 'status': 'new'},
        }),
        throwsFormatException,
      );
    });

    test('a message of an unknown role is malformed', () {
      expect(
        () => ConciergeMessage.fromJson({'id': 1, 'role': 'bot', 'text': 'x'}),
        throwsFormatException,
      );
    });
  });
}
