import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/events/screens/event_detail_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';
import 'package:mazl/presentation/features/events/widgets/event_member_price.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The mazl+ rate on the list and on the page of a paying event
// (docs/premium/MONETISATION.md §10), in every pose of the foldable iPhone,
// light and dark, for a member with and without mazl+.

Map<String, Object?> _event(
  int id, {
  num price = 25,
  Object? memberPriceCents,
  String title = 'Dîner de Shabbat',
}) => {
  'id': id,
  'title': title,
  'description': 'Un grand repas chez Jeanne.',
  'event_type': 'shabbat_dinner',
  'location': 'Synagogue de la Victoire',
  'address': '44 rue de la Victoire, Paris',
  'date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
  'time': '20:00:00',
  'end_time': '22:30:00',
  'price': price,
  'currency': 'EUR',
  'max_attendees': 40,
  'attendee_count': 12,
  'member_price_cents': ?memberPriceCents,
};

List<Map<String, Object?>> _served = [];

MockClient _server() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/events') {
    return http.Response(jsonEncode({'success': true, 'events': _served}), 200);
  }
  final id = int.parse(path.split('/').last);
  final event = _served.firstWhere((e) => e['id'] == id);
  return http.Response(jsonEncode({'success': true, 'event': event}), 200);
});

Future<void> _inServer(Future<void> Function() body) =>
    http.runWithClient(body, _server);

String? _pushed;

Widget _app(
  DuoPoseController pose,
  Widget home, {
  Locale locale = kTestLocale,
  bool dark = false,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(
        path: '/premium',
        builder: (context, state) {
          _pushed = state.uri.path;
          return const Scaffold(body: Text('offre mazl+'));
        },
      ),
    ],
  );
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    builder: duoAppBuilder(pose),
    routerConfig: router,
  );
}

Future<DuoPoseController> _pump(
  WidgetTester tester,
  Widget screen, {
  DuoPose pose = DuoPose.openPortrait,
  bool dark = false,
  Locale locale = kTestLocale,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(_app(controller, screen, locale: locale, dark: dark));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await settleFold(tester);
  return controller;
}

/// Scrolls the lists of the screen until the member rate is built, then into
/// view (the page and the cards are lazy lists, and short poses cut them).
Future<void> _reveal(WidgetTester tester) async {
  final rate = find.byType(EventMemberPrice);
  for (var i = 0; i < 30 && rate.evaluate().isEmpty; i++) {
    for (final scrollable in find.byType(Scrollable).evaluate().toList()) {
      await tester.drag(
        find.byWidget(scrollable.widget),
        const Offset(0, -200),
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(rate, findsOneWidget);
  await tester.ensureVisible(rate);
  await tester.pump(const Duration(milliseconds: 100));
}

/// The member rate, once in view, respects the pose: inside the safe area (or
/// the app's part of the vertical bar), clear of the system's occlusions and,
/// for a tap target, 44 pt wide and tall and out of the fold.
void _expectRateUsable(WidgetTester tester, DuoPose pose, String reason) {
  final rect = tester.getRect(find.byType(EventMemberPrice));
  final bar = pose.verticalBar?.controls;
  bool inside(Rect area) =>
      area.inflate(0.5).contains(rect.topLeft) &&
      area.inflate(0.5).contains(rect.bottomRight);
  expect(
    inside(pose.safeRect) || (bar != null && inside(bar)),
    isTrue,
    reason: '$reason in ${pose.name}: $rect is outside ${pose.safeRect}',
  );
  for (final occluded in pose.foldState.occlusions) {
    expect(
      rect.overlaps(occluded),
      isFalse,
      reason: '$reason: under $occluded',
    );
  }
  final tappable = find.descendant(
    of: find.byType(EventMemberPrice),
    matching: find.byType(InkWell),
  );
  if (tappable.evaluate().isNotEmpty) {
    final target = tester.getRect(tappable);
    expect(target.height, greaterThanOrEqualTo(44), reason: reason);
    expect(target.width, greaterThanOrEqualTo(44), reason: reason);
  }
}

Finder _text(String pattern) => find.byWidgetPredicate(
  (w) => w is Text && RegExp(pattern).hasMatch(w.data ?? ''),
);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

  setUp(() {
    PremiumGate.resetForTest();
    _pushed = null;
  });
  tearDown(PremiumGate.resetForTest);

  group('the page of a paying event', () {
    testWidgets('a member without mazl+: « mazl+ : 8 € » opens the offer', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = false;
      _served = [_event(1, memberPriceCents: 800)];
      await _inServer(() async {
        await _pump(tester, const EventDetailScreen(eventId: '1'));
        expect(_text(r'^mazl\+ : 8\s€$'), findsOneWidget);
        expect(_text(r'^Tarif membre'), findsNothing);
        await tester.ensureVisible(_text(r'^mazl\+ : 8'));
        await tester.pump();
        await tester.tap(_text(r'^mazl\+ : 8'));
        await tester.pumpAndSettle();
        expect(find.text('offre mazl+'), findsOneWidget);
        expect(_pushed, '/premium');
      });
    });

    testWidgets(
      'a subscriber: member rate first, regular price struck, and the '
      'button states the member rate',
      (tester) async {
        PremiumGate.debugPremiumOverride = true;
        _served = [_event(1, memberPriceCents: 800)];
        await _inServer(() async {
          await _pump(tester, const EventDetailScreen(eventId: '1'));
          expect(_text(r'^Tarif membre : 8\s€$'), findsOneWidget);
          final regular = tester.widget<Text>(
            find.descendant(
              of: find.byType(EventMemberPrice),
              matching: _text(r'^25\s€$'),
            ),
          );
          expect(regular.style?.decoration, TextDecoration.lineThrough);
          expect(_text(r"^S'inscrire - 8\s€$"), findsOneWidget);
          expect(_text(r"^S'inscrire - 25\s€$"), findsNothing);
        });
      },
    );

    testWidgets('a member without mazl+ registers at the regular price', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = false;
      _served = [_event(1, memberPriceCents: 800)];
      await _inServer(() async {
        await _pump(tester, const EventDetailScreen(eventId: '1'));
        expect(_text(r"^S'inscrire - 25\s€$"), findsOneWidget);
      });
    });

    testWidgets('no member rate: the page is the one it always was', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = true;
      _served = [_event(1)];
      await _inServer(() async {
        await _pump(tester, const EventDetailScreen(eventId: '1'));
        expect(find.byType(EventMemberPrice), findsNothing);
        expect(_text(r'mazl\+ :'), findsNothing);
        expect(_text(r'Tarif membre'), findsNothing);
        expect(_text(r"^S'inscrire - 25\s€$"), findsOneWidget);
      });
    });

    testWidgets('free for members: the button says « gratuitement »', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = true;
      _served = [_event(1, memberPriceCents: 0)];
      await _inServer(() async {
        await _pump(tester, const EventDetailScreen(eventId: '1'));
        expect(find.text('Tarif membre : Gratuit'), findsOneWidget);
        expect(find.text("S'inscrire gratuitement"), findsOneWidget);
      });
    });
  });

  group('the list of events', () {
    testWidgets('each paying card with a member rate shows it, others do not', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = false;
      _served = [
        _event(1, memberPriceCents: 800, title: 'Avec tarif membre'),
        _event(2, title: 'Sans tarif membre'),
        _event(3, price: 0, memberPriceCents: 0, title: 'Gratuit'),
      ];
      await _inServer(() async {
        await _pump(tester, const EventsListScreen());
        expect(_text(r'^mazl\+ : 8\s€$'), findsOneWidget);
      });
    });

    testWidgets('a subscriber sees the member rate on the card', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = true;
      _served = [_event(1, memberPriceCents: 800)];
      await _inServer(() async {
        await _pump(tester, const EventsListScreen());
        expect(_text(r'^Tarif membre : 8\s€$'), findsOneWidget);
      });
    });

    testWidgets('a tap on « mazl+ : 8 € » opens the offer, not the event', (
      tester,
    ) async {
      PremiumGate.debugPremiumOverride = false;
      _served = [_event(1, memberPriceCents: 800)];
      await _inServer(() async {
        await _pump(tester, const EventsListScreen());
        await tester.tap(_text(r'^mazl\+ : 8'));
        await tester.pumpAndSettle();
        expect(_pushed, '/premium');
      });
    });
  });

  group('every pose, light and dark', () {
    for (final pose in DuoPose.values) {
      for (final dark in [false, true]) {
        for (final subscriber in [false, true]) {
          final name =
              '${pose.name} ${dark ? 'dark' : 'light'} '
              '${subscriber ? 'mazl+' : 'free'}';
          testWidgets('page: $name', (tester) async {
            PremiumGate.debugPremiumOverride = subscriber;
            _served = [_event(1, memberPriceCents: 800)];
            await _inServer(() async {
              await _pump(
                tester,
                const EventDetailScreen(eventId: '1'),
                pose: pose,
                dark: dark,
              );
              await _reveal(tester);
              expect(foldCrossingProblems(tester, pose), isEmpty);
              expect(tester.takeException(), isNull);
              _expectRateUsable(tester, pose, 'event page with member rate');
            });
          });
          testWidgets('list: $name', (tester) async {
            PremiumGate.debugPremiumOverride = subscriber;
            _served = [_event(1, memberPriceCents: 800)];
            await _inServer(() async {
              await _pump(
                tester,
                const EventsListScreen(),
                pose: pose,
                dark: dark,
              );
              await _reveal(tester);
              expect(foldCrossingProblems(tester, pose), isEmpty);
              expect(tester.takeException(), isNull);
              _expectRateUsable(tester, pose, 'events list with member rate');
            });
          });
        }
      }
    }
  });
}
