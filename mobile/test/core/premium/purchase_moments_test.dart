import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/analytics/analytics.dart';
import 'package:mazl/core/analytics/analytics_event.dart';
import 'package:mazl/core/di/providers/analytics_providers.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/router/route_names.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/premium/widgets/plus_widgets.dart';
import 'package:mazl/presentation/features/premium/widgets/purchase_moment_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_fakes.dart';
import '../../helpers/l10n_helpers.dart';

// docs/premium/MONETISATION.md §9, written from the contract: the offer comes
// by itself at most once a day and per moment, always with a visible
// « Plus tard » of the same weight, never a countdown, never for a subscriber,
// and every step is a measurement event (consent first, in `Analytics`).

class _Recorder extends Analytics {
  _Recorder() : super(transport: FakeAnalyticsTransport());

  final events = <AnalyticsEvent>[];

  List<String> get names => [for (final e in events) e.name];

  @override
  void track(AnalyticsEvent? event) {
    if (event != null) events.add(event);
  }
}

late _Recorder _analytics;
late DateTime _today;
final _results = <bool>[];
final _screenShown = ValueNotifier<bool>(true);

Future<GoRouter> _pump(
  WidgetTester tester, {
  Locale locale = kTestLocale,
  Size size = kSmallPhone,
  PurchaseMoment moment = PurchaseMoment.thirdLikeReceived,
  Future<void> Function(BuildContext)? action,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: _screenShown,
            builder: (_, shown, _) => shown
                ? Builder(
                    builder: (context) => TextButton(
                      onPressed: () async {
                        if (action != null) return action(context);
                        _results.add(
                          await PurchaseMoments.offer(context, moment),
                        );
                      },
                      child: const Text('declencher'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.premium,
        builder: (_, _) => const Scaffold(body: Text('page mazl+')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(_analytics)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
      ),
    ),
  );
  return router;
}

Future<void> _trigger(WidgetTester tester) async {
  await tester.tap(find.text('declencher'));
  await tester.pumpAndSettle();
}

Finder get _later => find.widgetWithText(OutlinedButton, 'Plus tard');

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PurchaseMoments.resetForTest();
    PremiumGate.resetForTest();
    _analytics = _Recorder();
    _today = DateTime(2026, 10, 27, 21, 30);
    PurchaseMoments.clock = () => _today;
    _results.clear();
    _screenShown.value = true;
  });

  tearDown(() {
    PurchaseMoments.resetForTest();
    PremiumGate.resetForTest();
  });

  testWidgets('shows the offer of its moment, and says it was shown', (
    tester,
  ) async {
    await _pump(tester);
    await _trigger(tester);

    expect(find.text('Plusieurs personnes vous ont aimé.'), findsOneWidget);
    expect(find.byType(PlusCtaButton), findsOneWidget);
    expect(_later, findsOneWidget);
    await tester.tap(_later);
    await tester.pumpAndSettle();
    expect(_results, [true]);
  });

  testWidgets('« Plus tard » is as big as the main button and not greyed out', (
    tester,
  ) async {
    await _pump(tester);
    await _trigger(tester);

    final cta = tester.getSize(find.byType(PlusCtaButton));
    final later = tester.getSize(_later);
    expect(later, cta);
    expect(tester.widget<OutlinedButton>(_later).onPressed, isNotNull);
  });

  testWidgets('no countdown and no promise of a deadline', (tester) async {
    await _pump(tester);
    await _trigger(tester);

    expect(find.byType(DailyCountdown), findsNothing);
  });

  testWidgets('at most once a day for a moment, again the next day', (
    tester,
  ) async {
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(_later);
    await tester.pumpAndSettle();

    await _trigger(tester);
    expect(find.byType(PlusCtaButton), findsNothing);
    expect(_results, [true, false]);

    _today = DateTime(2026, 10, 28, 8);
    await _trigger(tester);
    expect(find.byType(PlusCtaButton), findsOneWidget);
    await tester.tap(_later);
    await tester.pumpAndSettle();
    expect(_results, [true, false, true]);
  });

  testWidgets('the calendar day is the local one, not 24 hours', (
    tester,
  ) async {
    _today = DateTime(2026, 10, 27, 23, 50);
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(_later);
    await tester.pumpAndSettle();

    _today = DateTime(2026, 10, 28, 0, 10);
    await _trigger(tester);
    expect(find.byType(PlusCtaButton), findsOneWidget);
    await tester.tap(_later);
    await tester.pumpAndSettle();

    expect(_results, [true, true]);
  });

  testWidgets('each moment has its own day', (tester) async {
    for (final moment in PurchaseMoment.values) {
      await _pump(tester, moment: moment);
      await _trigger(tester);
      expect(find.byType(PlusCtaButton), findsOneWidget, reason: '$moment');
      await tester.tap(_later);
      await tester.pumpAndSettle();
    }
    expect(_results, everyElement(isTrue));
  });

  testWidgets('remembered after a restart of the app', (tester) async {
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(_later);
    await tester.pumpAndSettle();

    PurchaseMoments.forgetMemoryForTest();
    await _trigger(tester);

    expect(find.byType(PlusCtaButton), findsNothing);
    expect(_results, [true, false]);
  });

  testWidgets('storage that fails: still once a day in this session', (
    tester,
  ) async {
    PurchaseMoments.preferences = () async => throw Exception('disk full');
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(_later);
    await tester.pumpAndSettle();
    await _trigger(tester);

    expect(_results, [true, false]);
  });

  testWidgets('nothing for a subscriber, and nothing measured', (tester) async {
    PremiumGate.debugPremiumOverride = true;
    await _pump(tester);
    await _trigger(tester);

    expect(find.byType(PlusCtaButton), findsNothing);
    expect(_results, [false]);
    expect(_analytics.events, isEmpty);
  });

  testWidgets('shown then dismissed: two events with the moment', (
    tester,
  ) async {
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(_later);
    await tester.pumpAndSettle();

    expect(_analytics.names, [
      'purchase_moment_shown',
      'purchase_moment_dismissed',
    ]);
    for (final event in _analytics.events) {
      expect(event.properties, {'moment': 'thirdLikeReceived'});
    }
  });

  testWidgets('closing by a tap outside counts as dismissed', (tester) async {
    await _pump(tester);
    await _trigger(tester);
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();

    expect(find.byType(PlusCtaButton), findsNothing);
    expect(_analytics.names.last, 'purchase_moment_dismissed');
  });

  testWidgets('accepting opens mazl+ and measures it', (tester) async {
    await _pump(tester);
    await _trigger(tester);
    await tester.tap(find.byType(PlusCtaButton));
    await tester.pumpAndSettle();

    expect(find.text('page mazl+'), findsOneWidget);
    expect(_analytics.names, [
      'purchase_moment_shown',
      'purchase_moment_accepted',
    ]);
    expect(_results, [true]);
  });

  testWidgets('does nothing when the screen is gone before it can show', (
    tester,
  ) async {
    await _pump(tester);
    PurchaseMoments.preferences = () async {
      _screenShown.value = false;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return SharedPreferences.getInstance();
    };
    await tester.tap(find.text('declencher'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(_results, [false]);
    expect(_analytics.events, isEmpty);
    expect(find.byType(PlusCtaButton), findsNothing);

    // The day was not consumed by an offer nobody saw.
    PurchaseMoments.preferences = SharedPreferences.getInstance;
    _screenShown.value = true;
    await tester.pumpAndSettle();
    await _trigger(tester);
    expect(find.byType(PlusCtaButton), findsOneWidget);
    await tester.tap(_later);
    await tester.pumpAndSettle();
    expect(_results, [false, true]);
  });

  group('the daily likes limit window is the offer of its moment', () {
    Future<void> openLimit(WidgetTester tester) async {
      await _pump(
        tester,
        action: (context) => PremiumGate.showDailyLimitSheet(
          context,
          freeLikesPerDay: 5,
          resetsAt: _today.add(const Duration(hours: 3)),
        ),
      );
      await _trigger(tester);
    }

    testWidgets('measured as shown then dismissed', (tester) async {
      await openLimit(tester);
      expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
      await tester.tap(find.text('Attendre minuit'));
      await tester.pumpAndSettle();

      expect(_analytics.names, [
        'purchase_moment_shown',
        'purchase_moment_dismissed',
      ]);
      expect(_analytics.events.first.properties, {'moment': 'dailyLikeLimit'});
    });

    testWidgets('measured as accepted when mazl+ is chosen', (tester) async {
      await openLimit(tester);
      await tester.tap(find.byType(PlusCtaButton));
      await tester.pumpAndSettle();

      expect(find.text('page mazl+'), findsOneWidget);
      expect(_analytics.names, [
        'purchase_moment_shown',
        'purchase_moment_accepted',
      ]);
    });

    testWidgets('the window itself stays the one that was there', (
      tester,
    ) async {
      await openLimit(tester);

      // Not doubled by the generic offer, and still its countdown.
      expect(find.byType(PurchaseMomentSheet), findsNothing);
      expect(find.byType(DailyCountdown), findsOneWidget);
    });

    testWidgets('counts as the day\'s offer: no second one the same day', (
      tester,
    ) async {
      await openLimit(tester);
      await tester.tap(find.text('Attendre minuit'));
      await tester.pumpAndSettle();

      final shown = await tester.runAsync(() async {
        final context = tester.element(find.text('declencher'));
        return PurchaseMoments.offer(context, PurchaseMoment.dailyLikeLimit);
      });
      await tester.pumpAndSettle();

      expect(shown, isFalse);
      expect(find.byType(PurchaseMomentSheet), findsNothing);
    });

    testWidgets('the window shows each time the limit is hit', (tester) async {
      await openLimit(tester);
      await tester.tap(find.text('Attendre minuit'));
      await tester.pumpAndSettle();

      await _trigger(tester);
      expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
    });
  });

  group('third like received', () {
    Future<void> pumpWith(WidgetTester tester, int likes) => _pump(
      tester,
      action: (context) async => _results.add(
        await PurchaseMoments.offerThirdLike(context, receivedLikes: likes),
      ),
    );

    testWidgets('under three likes: nothing', (tester) async {
      await pumpWith(tester, 2);
      await _trigger(tester);

      expect(_results, [false]);
      expect(find.byType(PlusCtaButton), findsNothing);
    });

    testWidgets('at three likes: the offer of its moment, once for good', (
      tester,
    ) async {
      await pumpWith(tester, 3);
      await _trigger(tester);
      expect(find.text('Plusieurs personnes vous ont aimé.'), findsOneWidget);
      await tester.tap(_later);
      await tester.pumpAndSettle();

      // Not the next day either, nor with more likes: « une fois ».
      _today = DateTime(2026, 10, 29, 9);
      await _trigger(tester);
      expect(_results, [true, false]);
      expect(_analytics.events.first.properties, {
        'moment': 'thirdLikeReceived',
      });
    });

    testWidgets('remembered after a restart too', (tester) async {
      await pumpWith(tester, 5);
      await _trigger(tester);
      await tester.tap(_later);
      await tester.pumpAndSettle();

      PurchaseMoments.forgetMemoryForTest();
      _today = DateTime(2026, 11, 3);
      await _trigger(tester);

      expect(_results, [true, false]);
    });

    testWidgets('a subscriber is never offered it', (tester) async {
      PremiumGate.debugPremiumOverride = true;
      await pumpWith(tester, 9);
      await _trigger(tester);

      expect(_results, [false]);
    });
  });

  group('first match', () {
    Future<void> pumpWith(WidgetTester tester, {required bool openedChat}) =>
        _pump(
          tester,
          action: (context) async => _results.add(
            await PurchaseMoments.afterMatchSheet(
              context,
              openedChat: openedChat,
            ),
          ),
        );

    testWidgets('the first match, back to Discover: the offer', (tester) async {
      await pumpWith(tester, openedChat: false);
      await _trigger(tester);
      expect(find.text('Votre premier match.'), findsOneWidget);
      await tester.tap(_later);
      await tester.pumpAndSettle();

      expect(_results, [true]);
      expect(_analytics.events.first.properties, {'moment': 'firstMatch'});
    });

    testWidgets('only the first match counts, later ones never', (
      tester,
    ) async {
      await pumpWith(tester, openedChat: false);
      await _trigger(tester);
      await tester.tap(_later);
      await tester.pumpAndSettle();

      _today = DateTime(2026, 10, 30);
      await _trigger(tester);

      expect(_results, [true, false]);
    });

    testWidgets('going to the chat: no offer on the way, and the first match '
        'is used up', (tester) async {
      await pumpWith(tester, openedChat: true);
      await _trigger(tester);
      expect(_results, [false]);
      expect(find.byType(PlusCtaButton), findsNothing);

      await pumpWith(tester, openedChat: false);
      await _trigger(tester);
      expect(_results, [false, false]);
    });

    testWidgets('a subscriber is never offered it', (tester) async {
      PremiumGate.debugPremiumOverride = true;
      await pumpWith(tester, openedChat: false);
      await _trigger(tester);

      expect(_results, [false]);
    });
  });

  for (final locale in AppLocalizations.supportedLocales) {
    for (final moment in PurchaseMoment.values) {
      testWidgets('${locale.languageCode} ${moment.name}: fits a small phone', (
        tester,
      ) async {
        await _pump(tester, locale: locale, moment: moment);
        await _trigger(tester);

        expect(find.byType(PlusCtaButton), findsOneWidget);
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale);
        expect(find.text(l10n.commonLater), findsOneWidget);
      });
    }
  }
}
