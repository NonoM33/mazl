import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/premium/boost_schedule_api.dart';
import 'package:mazl/presentation/features/boost/widgets/boost_best_time_card.dart';

import '../../helpers/l10n_helpers.dart';

/// Saturday 2026-10-31 at 21:00 local time, sent as the server does (UTC).
final _saturdayEvening = DateTime(2026, 10, 31, 21).toUtc();

/// Wednesday 2026-10-28 at 19:00 local time.
final _wednesdayEvening = DateTime(2026, 10, 28, 19).toUtc();

BoostScheduleInfo _info({
  DateTime? best,
  DateTime? scheduled,
  String? city = 'Paris',
}) => BoostScheduleInfo(
  city: city,
  bestTime: best == null
      ? null
      : BoostBestTime(startsAt: best, weekday: 6, hour: 21),
  scheduledAt: scheduled,
);

class _FakeApi implements BoostScheduleApi {
  _FakeApi(this.info);

  BoostScheduleInfo info;
  Object? loadError;
  final List<Object> scheduleErrors = [];
  Object? cancelError;
  final calls = <String>[];

  @override
  Future<BoostScheduleInfo> bestTime() async {
    calls.add('best');
    final error = loadError;
    if (error != null) throw error;
    return info;
  }

  @override
  Future<DateTime> schedule(DateTime at) async {
    calls.add('schedule:${at.toUtc().toIso8601String()}');
    if (scheduleErrors.isNotEmpty) throw scheduleErrors.removeAt(0);
    info = _info(best: info.bestTime?.startsAt, scheduled: at.toUtc());
    return at.toUtc();
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
    final error = cancelError;
    if (error != null) throw error;
    info = _info(best: info.bestTime?.startsAt);
  }
}

BoostScheduleException _error(BoostScheduleErrorKind kind) =>
    BoostScheduleException(kind);

Future<void> _pump(
  WidgetTester tester,
  _FakeApi api, {
  Future<bool> Function()? onBoostsExhausted,
  Locale locale = kTestLocale,
  Brightness brightness = Brightness.light,
}) async {
  await pumpLocalized(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: BoostBestTimeCard(
          api: api,
          onBoostsExhausted: onBoostsExhausted ?? () async => false,
        ),
      ),
    ),
    locale: locale,
    brightness: brightness,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  group('the best time', () {
    testWidgets('Saturday evening reads « après Shabbat »', (tester) async {
      await _pump(tester, _FakeApi(_info(best: _saturdayEvening)));
      expect(
        find.text('Meilleur moment : samedi 21 h, après Shabbat'),
        findsOneWidget,
      );
      expect(find.text("D'après l'affluence mesurée à Paris."), findsOneWidget);
      expect(find.text('Programmer pour ce moment'), findsOneWidget);
    });

    testWidgets('a weekday evening does not mention Shabbat', (tester) async {
      await _pump(tester, _FakeApi(_info(best: _wednesdayEvening)));
      expect(find.text('Meilleur moment : mercredi 19 h'), findsOneWidget);
      expect(find.textContaining('Shabbat'), findsNothing);
    });

    testWidgets('without a city the basis line does not name one', (
      tester,
    ) async {
      await _pump(tester, _FakeApi(_info(best: _saturdayEvening, city: null)));
      expect(
        find.text("D'après l'affluence mesurée dans votre ville."),
        findsOneWidget,
      );
    });

    testWidgets('the cost of scheduling is said before the tap', (
      tester,
    ) async {
      await _pump(tester, _FakeApi(_info(best: _saturdayEvening)));
      expect(
        find.text(
          'Un de vos Boosts sera utilisé à ce moment-là, et vous serez prévenu quand il démarre.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('English reads in English', (tester) async {
      await _pump(
        tester,
        _FakeApi(_info(best: _saturdayEvening)),
        locale: const Locale('en'),
      );
      expect(
        find.text('Best time: Saturday at 9 PM, after Shabbat'),
        findsOneWidget,
      );
      expect(find.text('Schedule for this time'), findsOneWidget);
    });
  });

  group('no best time yet', () {
    testWidgets('says so, shows no time and no schedule button', (
      tester,
    ) async {
      await _pump(tester, _FakeApi(_info()));
      expect(
        find.text('Pas encore assez de données pour votre ville.'),
        findsOneWidget,
      );
      expect(find.textContaining('Meilleur moment'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Programmer pour ce moment'), findsNothing);
    });
  });

  group('scheduling', () {
    testWidgets('the button sends the instant of the best time', (
      tester,
    ) async {
      final api = _FakeApi(_info(best: _saturdayEvening));
      await _pump(tester, api);
      await tester.tap(find.text('Programmer pour ce moment'));
      await tester.pumpAndSettle();
      expect(api.calls, [
        'best',
        'schedule:${_saturdayEvening.toIso8601String()}',
      ]);
      expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
      expect(find.text('Annuler la programmation'), findsOneWidget);
      expect(find.text('Programmer pour ce moment'), findsNothing);
    });

    testWidgets('an already scheduled Boost opens in the scheduled state', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeApi(_info(best: _saturdayEvening, scheduled: _saturdayEvening)),
      );
      expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
      expect(find.text('Annuler la programmation'), findsOneWidget);
    });

    testWidgets('a scheduled Boost shows even without a best time any more', (
      tester,
    ) async {
      await _pump(tester, _FakeApi(_info(scheduled: _saturdayEvening)));
      expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
    });

    testWidgets('« Annuler » calls DELETE and offers the schedule again', (
      tester,
    ) async {
      final api = _FakeApi(
        _info(best: _saturdayEvening, scheduled: _saturdayEvening),
      );
      await _pump(tester, api);
      await tester.tap(find.text('Annuler la programmation'));
      await tester.pumpAndSettle();
      expect(api.calls, ['best', 'cancel']);
      expect(find.text('Programmer pour ce moment'), findsOneWidget);
      expect(find.text('Programmé pour samedi 21 h'), findsNothing);
    });

    testWidgets('a failed cancellation keeps the schedule and says so', (
      tester,
    ) async {
      final api = _FakeApi(
        _info(best: _saturdayEvening, scheduled: _saturdayEvening),
      )..cancelError = _error(BoostScheduleErrorKind.network);
      await _pump(tester, api);
      await tester.tap(find.text('Annuler la programmation'));
      await tester.pumpAndSettle();
      expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
      expect(
        find.text("Impossible d'annuler la programmation. Réessayez."),
        findsOneWidget,
      );
    });
  });

  group('refusals', () {
    testWidgets(
      'boosts_exhausted opens the packs; a purchase schedules again',
      (tester) async {
        final api = _FakeApi(_info(best: _saturdayEvening))
          ..scheduleErrors.add(_error(BoostScheduleErrorKind.boostsExhausted));
        var opened = 0;
        await _pump(
          tester,
          api,
          onBoostsExhausted: () async {
            opened++;
            return true;
          },
        );
        await tester.tap(find.text('Programmer pour ce moment'));
        await tester.pumpAndSettle();
        expect(opened, 1);
        expect(
          api.calls.where((c) => c.startsWith('schedule')),
          hasLength(2),
          reason: 'once refused, once after the purchase',
        );
        expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
      },
    );

    testWidgets('without a purchase nothing is scheduled and nothing is said', (
      tester,
    ) async {
      final api = _FakeApi(_info(best: _saturdayEvening))
        ..scheduleErrors.add(_error(BoostScheduleErrorKind.boostsExhausted));
      await _pump(tester, api, onBoostsExhausted: () async => false);
      await tester.tap(find.text('Programmer pour ce moment'));
      await tester.pumpAndSettle();
      expect(api.calls.where((c) => c.startsWith('schedule')), hasLength(1));
      expect(find.text('Programmer pour ce moment'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('already_scheduled says so and reads the server schedule', (
      tester,
    ) async {
      final api = _FakeApi(_info(best: _saturdayEvening));
      await _pump(tester, api);
      api
        ..scheduleErrors.add(_error(BoostScheduleErrorKind.alreadyScheduled))
        ..info = _info(best: _saturdayEvening, scheduled: _saturdayEvening);
      await tester.tap(find.text('Programmer pour ce moment'));
      await tester.pumpAndSettle();
      expect(find.text('Un Boost est déjà programmé.'), findsOneWidget);
      expect(find.text('Programmé pour samedi 21 h'), findsOneWidget);
    });

    testWidgets('invalid_time says so and reads the best time again', (
      tester,
    ) async {
      final api = _FakeApi(_info(best: _saturdayEvening));
      await _pump(tester, api);
      api.scheduleErrors.add(_error(BoostScheduleErrorKind.invalidTime));
      await tester.tap(find.text('Programmer pour ce moment'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Ce moment n'est plus possible : il doit être à venir, dans les 7 prochains jours.",
        ),
        findsOneWidget,
      );
      expect(api.calls.where((c) => c == 'best'), hasLength(2));
    });

    testWidgets('any other failure gives the generic message', (tester) async {
      final api = _FakeApi(_info(best: _saturdayEvening))
        ..scheduleErrors.add(_error(BoostScheduleErrorKind.server));
      await _pump(tester, api);
      await tester.tap(find.text('Programmer pour ce moment'));
      await tester.pumpAndSettle();
      expect(
        find.text('Impossible de programmer le Boost. Réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Programmer pour ce moment'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('a failed load offers « Réessayer », which loads again', (
      tester,
    ) async {
      final api = _FakeApi(_info(best: _saturdayEvening))
        ..loadError = _error(BoostScheduleErrorKind.network);
      await _pump(tester, api);
      expect(
        find.text('Impossible de charger le meilleur moment.'),
        findsOneWidget,
      );
      api.loadError = null;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Meilleur moment : samedi 21 h, après Shabbat'),
        findsOneWidget,
      );
    });
  });

  group('touch targets', () {
    testWidgets(
      'both buttons are at least 44 pt tall and as wide as the card',
      (tester) async {
        final api = _FakeApi(_info(best: _saturdayEvening));
        await _pump(tester, api);
        final schedule = tester.getRect(
          find.widgetWithText(FilledButton, 'Programmer pour ce moment'),
        );
        expect(schedule.height, greaterThanOrEqualTo(44));
        await tester.tap(find.text('Programmer pour ce moment'));
        await tester.pumpAndSettle();
        final cancel = tester.getRect(
          find.widgetWithText(TextButton, 'Annuler la programmation'),
        );
        expect(cancel.height, greaterThanOrEqualTo(44));
        expect(cancel.width, greaterThanOrEqualTo(44));
      },
    );
  });
}
