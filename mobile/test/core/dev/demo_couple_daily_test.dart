import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_couple_daily_state.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/models/couple_daily.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_call.dart';
import 'package:mazl/core/services/couple_daily_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Replays the REAL decoders of the daily couple space against the demo, with
/// a fake clock: what the simulator shows is what the client can read.
Future<T> _demo<T>(Future<T> Function() body) => http.runWithClient(
  body,
  () => DemoHttpClient(
    MockClient((r) async => fail('real network reached: ${r.url}')),
    latency: Duration.zero,
  ),
);

late DateTime _now;

/// Sends a request to Noémie (301) and lets the 3 s pass: returns the couple id.
Future<int> _enterCouple() async {
  final sent = await ApiService().sendCoupleRequest(301);
  expect(sent.success, isTrue, reason: sent.error);
  _now = _now.add(const Duration(seconds: 3));
  final couple = await ApiService().getCoupleData();
  return (couple.data!['couple'] as Map<String, dynamic>)['id'] as int;
}

T _ok<T>(CoupleResult<T> result) {
  expect(result.failureOrNull, isNull, reason: '${result.failureOrNull}');
  return result.valueOrNull as T;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = CoupleDailyApi();

  setUp(() {
    DevSession.start();
    _now = DateTime.now();
    DemoStore.clock = () => _now;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    DemoStore.clock = DateTime.now;
    DevSession.stop();
  });

  test('outside a couple, every route refuses with notInCouple', () async {
    await _demo(() async {
      expect(
        (await api.getToday()).failureOrNull?.kind,
        CoupleFailureKind.notInCouple,
      );
      expect(
        (await api.getCheckin()).failureOrNull?.kind,
        CoupleFailureKind.notInCouple,
      );
    });
  });

  test('today: the day 214, the partner, five upcoming at most', () async {
    await _demo(() async {
      await _enterCouple();
      final today = _ok(await api.getToday());
      expect(today.days, DemoCoupleDailyState.dayCount);
      expect(today.partnerName, 'Noémie');
      expect(today.question?.partnerAnswered, isTrue);
      expect(today.question?.myAnswered, isFalse);
      expect(today.upcoming.length, inInclusiveRange(1, 5));
      final times = [for (final u in today.upcoming) u.at];
      expect([...times]..sort(), times, reason: 'sorted by date');
      expect(today.premium.active, isTrue);
      expect(today.premium.paidBy, CouplePayer.partner);
      expect(today.checkinDue, isTrue);
    });
  });

  test('the mood is kept', () async {
    await _demo(() async {
      await _enterCouple();
      _ok(await api.setMood(CoupleMoodChoice.talk));
      expect(_ok(await api.getToday()).myMood, CoupleMoodChoice.talk);
    });
  });

  test(
    'outings: the filters narrow the list, the feature is an event',
    () async {
      await _demo(() async {
        await _enterCouple();
        final all = _ok(await api.getOutings());
        expect(all.featured?.kind, OutingKind.event);
        expect(all.items, isNotEmpty);
        final kosher = _ok(await api.getOutings(OutingFilter.kosher));
        expect(
          [if (kosher.featured != null) kosher.featured!, ...kosher.items],
          everyElement(isA<Outing>().having((o) => o.kosher, 'kosher', isTrue)),
        );
        final cheap = _ok(await api.getOutings(OutingFilter.cheap));
        expect(
          [if (cheap.featured != null) cheap.featured!, ...cheap.items],
          everyElement(
            isA<Outing>().having(
              (o) => o.priceCents ?? 99999,
              'price',
              lessThanOrEqualTo(5000),
            ),
          ),
        );
        final mazl = _ok(await api.getOutings(OutingFilter.mazl));
        expect(
          [if (mazl.featured != null) mazl.featured!, ...mazl.items],
          everyElement(isA<Outing>().having((o) => o.isEvent, 'event', isTrue)),
        );
      });
    },
  );

  test('rituals: Shabbat is on, the others off; toggle, add, delete', () async {
    await _demo(() async {
      await _enterCouple();
      var rituals = _ok(await api.getRituals());
      expect([for (final r in rituals) r.enabled], [true, false, false]);
      expect(rituals.first.kind, CoupleRitualKind.shabbat);

      final toggled = _ok(await api.setRitualEnabled(rituals[1].id, true));
      expect(toggled.enabled, isTrue);

      final added = _ok(
        await api.addRitual(
          title: 'Marche du dimanche',
          weekday: 0,
          time: '09:30',
        ),
      );
      expect(added.kind, CoupleRitualKind.custom);
      rituals = _ok(await api.getRituals());
      expect(rituals, hasLength(4));

      _ok(await api.deleteRitual(added.id));
      expect(_ok(await api.getRituals()), hasLength(3));
    });
  });

  test('the question hides the partner answer until I answered', () async {
    await _demo(() async {
      final coupleId = await _enterCouple();
      final before = _ok(await api.getQuestion(coupleId))!;
      expect(before.myAnswer, isNull);
      expect(before.partnerAnswer, isNull);
      expect(before.answered, isFalse);

      _ok(
        await api.answerQuestion(
          coupleId: coupleId,
          questionId: before.id,
          answer: 'Le café du matin.',
        ),
      );
      final after = _ok(await api.getQuestion(coupleId))!;
      expect(after.myAnswer, 'Le café du matin.');
      expect(after.partnerAnswer, isNotNull);

      final history = _ok(await api.getQuestionHistory(coupleId));
      expect(history, isNotEmpty);
      expect(history.first.partnerAnswer, isNotNull);
    });
  });

  test(
    'the check-in: no summary before I answer, one answer a month',
    () async {
      await _demo(() async {
        await _enterCouple();
        final before = _ok(await api.getCheckin())!;
        expect(before.answered, isFalse);
        expect(before.partnerDone, isTrue);
        expect(before.summary, isNull);

        final after = _ok(
          await api.submitCheckin(
            const CheckinScores(talk: 4, time: 2, close: 5),
          ),
        );
        expect(after.mine?.time, 2);
        expect(after.summary?.aligned, inInclusiveRange(0, 3));
        expect(after.summary?.lowest, CheckinTheme.time);

        final again = await api.submitCheckin(
          const CheckinScores(talk: 1, time: 1, close: 1),
        );
        expect(again.failureOrNull?.kind, CoupleFailureKind.alreadyDone);
      });
    },
  );

  test('the concierge: list, conversation, choice, message, cancel', () async {
    await _demo(() async {
      await _enterCouple();
      final list = _ok(await api.getConcierge());
      expect(list, hasLength(1));
      expect(list.single.status, ConciergeStatus.proposed);
      expect(list.single.step, 1);

      var thread = _ok(await api.getConciergeThread(list.single.id));
      expect(thread.request.options, hasLength(3));
      expect(thread.request.canChoose, isTrue);
      expect(thread.messages.map((m) => m.role), [
        ConciergeRole.member,
        ConciergeRole.assistant,
      ]);

      thread = _ok(await api.chooseConciergeOption(thread.request.id, 1));
      expect(thread.request.status, ConciergeStatus.chosen);
      expect(thread.request.chosenIndex, 1);
      expect(thread.messages.last.role, ConciergeRole.staff);
      expect(_ok(await api.getConcierge()).single.step, 2);

      thread = _ok(
        await api.sendConciergeMessage(thread.request.id, 'Sans musique.'),
      );
      expect(thread.messages.where((m) => m.mine), isNotEmpty);

      final created = _ok(
        await api.createConcierge(
          text: 'Un cadeau pour sa mère',
          kind: ConciergeKind.gift,
        ),
      );
      expect(created.request.title, 'Un cadeau pour sa mère');
      expect(_ok(await api.getConcierge()), hasLength(2));

      final cancelled = _ok(await api.cancelConcierge(created.request.id));
      expect(cancelled.request.status, ConciergeStatus.cancelled);
    });
  });

  test('without MAZL Couple the concierge answers 402', () async {
    await _demo(() async {
      await _enterCouple();
      DemoStore.couple.daily.premiumActive = false;
      final list = await api.getConcierge();
      expect(list.failureOrNull?.kind, CoupleFailureKind.subscriptionRequired);
      expect(
        (await api.createConcierge(text: 'Une table')).failureOrNull?.kind,
        CoupleFailureKind.subscriptionRequired,
      );
      final couple = await ApiService().getCoupleData();
      expect(
        (couple.data!['premium'] as Map<String, dynamic>)['active'],
        isFalse,
      );
    });
  });

  test('the premium of the couple rides along GET /api/couple', () async {
    await _demo(() async {
      await _enterCouple();
      final couple = await ApiService().getCoupleData();
      final premium = CouplePremium.fromJson(couple.data!['premium']);
      expect(premium.active, isTrue);
      expect(premium.paidBy, CouplePayer.partner);
      expect(premium.renewsAt, isNotNull);
    });
  });
}
