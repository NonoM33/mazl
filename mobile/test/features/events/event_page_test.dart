import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/router/route_transitions.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/share/share_sheet.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/events/l10n/event_texts.dart';
import 'package:mazl/presentation/features/events/screens/event_detail_screen.dart';
import 'package:mazl/presentation/features/events/screens/events_list_screen.dart';
import 'package:mazl/presentation/features/events/widgets/event_photo.dart';
import 'package:mazl/presentation/features/events/widgets/event_place_map.dart';

import 'package:mazl/presentation/common/widgets/directional_icon.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../duo/duo_geometry.dart';

// The page of an event: photos that fly from the card to the header, the
// place on a map, a share button that really opens the share sheet, and times
// written « 20 h 00 – 22 h 30 », never « 20:00:00 ».

Map<String, Object?> _event(
  int id, {
  String title = 'Dîner de Shabbat',
  String? image,
  double? latitude = 48.857,
  double? longitude = 2.35,
  String? availability,
  String? address = '44 rue de la Victoire, Paris',
}) => {
  'id': id,
  'title': title,
  'description': 'Un grand repas chez Jeanne, avec beaucoup de chants.',
  'event_type': 'shabbat_dinner',
  'location': 'Synagogue de la Victoire',
  'address': address,
  'latitude': latitude,
  'longitude': longitude,
  'date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
  'time': '20:00:00',
  'end_time': '22:30:00',
  'price': 12,
  'currency': 'EUR',
  'max_attendees': 40,
  'attendee_count': 12,
  'image_url': image,
  'availability': ?availability,
};

List<Map<String, Object?>> _served = [_event(1)];

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

Widget _app(DuoPoseController pose, Widget home, {Locale? locale}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('fr'),
      builder: duoAppBuilder(pose),
      home: home,
    );

Future<DuoPoseController> _pumpDetail(
  WidgetTester tester,
  DuoPose pose, {
  String eventId = '1',
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    _app(controller, EventDetailScreen(eventId: eventId)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
  return controller;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting();
  });

  group('times', () {
    test('French writes « 20 h 00 », never seconds', () {
      expect(eventClockText('20:00:00', 'fr'), '20 h 00');
      expect(eventClockText('19:30', 'fr'), '19 h 30');
      expect(eventClockText('01:05:00', 'fr'), '01 h 05');
    });

    test('other languages use their own clock', () {
      expect(
        eventClockText('20:00:00', 'en').replaceAll(RegExp(r'\s'), ' '),
        '8:00 PM',
      );
      expect(eventClockText('20:00:00', 'es'), contains('20:00'));
      expect(eventClockText('20:00:00', 'he'), contains('20:00'));
      expect(eventClockText('20:00:00', 'ru'), contains('20:00'));
      expect(eventClockText('20:00:00', 'es'), isNot(contains(':00:00')));
    });

    test('an unreadable time is returned as is', () {
      expect(eventClockText('en soirée', 'fr'), 'en soirée');
      expect(eventClockText('25:00', 'fr'), '25:00');
    });

    testWidgets('the page says « 20 h 00 – 22 h 30 »', (tester) async {
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.openPortrait);
        expect(find.text('20 h 00 – 22 h 30'), findsOneWidget);
        expect(find.textContaining(':00:00'), findsNothing);
      });
    });

    testWidgets('the card says « à 20 h 00 »', (tester) async {
      await _inServer(() async {
        setDuoPose(tester, DuoPose.openPortrait);
        final controller = DuoPoseController(DuoPose.openPortrait);
        await tester.pumpWidget(_app(controller, const EventsListScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.textContaining('à 20 h 00'), findsOneWidget);
        expect(find.textContaining(':00:00'), findsNothing);
      });
    });
  });

  group('share', () {
    late List<MethodCall> calls;
    late bool iosRefusesWithoutOrigin;

    setUp(() {
      calls = [];
      iosRefusesWithoutOrigin = true;
      // The iOS side of share_plus: on a large screen the sheet is a popover
      // and the plugin answers with an error when no origin is given.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (call) async {
              calls.add(call);
              final args = call.arguments as Map<Object?, Object?>;
              final width = args['originWidth'] as double?;
              if (iosRefusesWithoutOrigin && (width == null || width <= 0)) {
                throw PlatformException(
                  code: 'error',
                  message: 'sharePositionOrigin: argument must be set',
                );
              }
              return 'dev.fluttercommunity.plus/share/unavailable';
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            null,
          );
    });

    for (final pose in [
      DuoPose.halfOpenBook,
      DuoPose.closed,
      DuoPose.openPortrait,
      DuoPose.openLandscape,
    ]) {
      testWidgets('${pose.name}: the share button opens the sheet with a text, '
          'a link and an origin', (tester) async {
        await _inServer(() async {
          await _pumpDetail(tester, pose);
          await tester.tap(find.byTooltip('Partager'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(calls, hasLength(1), reason: 'the sheet was asked for');
          final args = calls.single.arguments as Map<Object?, Object?>;
          final text = args['text']! as String;
          expect(text, contains('Dîner de Shabbat'));
          expect(text, contains(kMazlSiteUrl));
          final origin = Rect.fromLTWH(
            args['originX']! as double,
            args['originY']! as double,
            args['originWidth']! as double,
            args['originHeight']! as double,
          );
          expect(origin.isEmpty, isFalse, reason: 'a non-empty origin');
          expect(
            (Offset.zero & pose.size).contains(origin.center),
            isTrue,
            reason: 'inside the window: $origin',
          );
          expect(
            find.text('Impossible de partager pour le moment.'),
            findsNothing,
          );
        });
      });
    }

    testWidgets('the origin is the button itself, in the column too', (
      tester,
    ) async {
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.halfOpenBook);
        final button = tester.getRect(find.byTooltip('Partager'));
        await tester.tap(find.byTooltip('Partager'));
        await tester.pump();
        final args = calls.single.arguments as Map<Object?, Object?>;
        final origin = Rect.fromLTWH(
          args['originX']! as double,
          args['originY']! as double,
          args['originWidth']! as double,
          args['originHeight']! as double,
        );
        expect(origin, button);
      });
    });

    testWidgets('a sheet that cannot open says so', (tester) async {
      iosRefusesWithoutOrigin = true;
      final previous = ShareSheet.sender;
      addTearDown(() => ShareSheet.sender = previous);
      ShareSheet.sender = ({required text, subject, required origin}) async {
        throw PlatformException(code: 'error');
      };
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.openPortrait);
        await tester.tap(find.byTooltip('Partager'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text('Impossible de partager pour le moment.'),
          findsOneWidget,
        );
      });
    });
  });

  group('map', () {
    late List<Uri> opened;
    setUp(() {
      opened = [];
      EventPlaceMap.launcher = (uri) async {
        opened.add(uri);
        return true;
      };
    });

    testWidgets('an open event with an address: the map and the exact pin', (
      tester,
    ) async {
      _served = [_event(1)];
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.openPortrait);
        expect(find.byType(EventPlaceMap), findsOneWidget);
        expect(find.text('Zone approximative'), findsNothing);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pump();
        await tester.tap(find.text('Ouvrir dans Plans'));
        await tester.pump();
        expect(opened, hasLength(1));
        expect(opened.single.host, 'maps.apple.com');
        expect(opened.single.queryParameters['ll'], '48.857,2.35');
        expect(opened.single.queryParameters['q'], 'Synagogue de la Victoire');
      });
    });

    testWidgets(
      'a coming soon event: the neighbourhood, never the exact place',
      (tester) async {
        _served = [_event(1, availability: 'coming_soon')];
        await _inServer(() async {
          await _pumpDetail(tester, DuoPose.openPortrait);
          expect(find.text('Zone approximative'), findsOneWidget);
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -300),
          );
          await tester.pump();
          await tester.tap(find.text('Ouvrir dans Plans'));
          await tester.pump();
          expect(opened.single.queryParameters.containsKey('q'), isFalse);
        });
      },
    );

    testWidgets('no coordinates: no map', (tester) async {
      _served = [_event(1, latitude: null, longitude: null)];
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.openPortrait);
        expect(find.byType(EventPlaceMap), findsNothing);
        expect(find.text('Ouvrir dans Plans'), findsNothing);
      });
    });

    testWidgets('book: the map is whole, left of the fold, under the photo', (
      tester,
    ) async {
      _served = [_event(1)];
      await _inServer(() async {
        await _pumpDetail(tester, DuoPose.halfOpenBook);
        final fold = DuoPose.halfOpenBook.fold!;
        final map = tester.getRect(find.byType(EventPlaceMap));
        expect(map.right, lessThanOrEqualTo(fold.left));
        expect(find.text('Ouvrir dans Plans'), findsOneWidget);
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
        expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'event with map');
      });
    });
  });

  group('every pose', () {
    for (final pose in DuoPose.values) {
      for (final locale in const [Locale('fr'), Locale('he')]) {
        testWidgets('${pose.name} (${locale.languageCode}): photo, facts and '
            'buttons fit, nothing crosses the fold', (tester) async {
          _served = [_event(1)];
          await _inServer(() async {
            setDuoPose(tester, pose);
            final controller = DuoPoseController(pose);
            await tester.pumpWidget(
              _app(
                controller,
                const EventDetailScreen(eventId: '1'),
                locale: locale,
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            await settleFold(tester);
            expect(foldCrossingProblems(tester, pose), isEmpty);
            if (pose.verticalBar != null) {
              expectFitsDuoPose(tester, pose, 'event page');
            }
            final share = tester.getRect(
              find.byTooltip(
                locale.languageCode == 'fr' ? 'Partager' : 'שיתוף',
              ),
            );
            expect(share.width, greaterThanOrEqualTo(44));
            expect(share.height, greaterThanOrEqualTo(44));
          });
        });
      }
    }
  });

  group('photo', () {
    final pixel = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    );
    setUp(() {
      EventPhoto.debugProvider = (_) => MemoryImage(pixel);
      addTearDown(() => EventPhoto.debugProvider = null);
    });

    GoRouter router() => GoRouter(
      initialLocation: '/events',
      routes: [
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsListScreen(),
          routes: [
            GoRoute(
              path: ':eventId',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: EventDetailScreen(
                  eventId: state.pathParameters['eventId']!,
                ),
                transitionDuration: MazlMotion.eventOpen,
                reverseTransitionDuration: MazlMotion.eventClose,
                transitionsBuilder: eventDetailTransition,
              ),
            ),
          ],
        ),
      ],
    );

    Future<void> pumpRouter(WidgetTester tester, DuoPose pose) async {
      setDuoPose(tester, pose);
      final controller = DuoPoseController(pose);
      await tester.pumpWidget(
        MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: duoAppBuilder(controller),
          routerConfig: router(),
        ),
      );
      await tester.pumpAndSettle();
    }

    List<Rect> photoRects(WidgetTester tester) => [
      for (final element in find.byType(EventPhoto).evaluate())
        (element.renderObject! as RenderBox).localToGlobal(Offset.zero) &
            (element.renderObject! as RenderBox).size,
    ];

    setUp(() {
      _served = [
        _event(1, image: 'https://images.example.com/a.jpg'),
        _event(
          2,
          title: 'Conférence',
          image: 'https://images.example.com/b.jpg',
        ),
      ];
    });

    testWidgets(
      'the card shows the photo, with the plain color as a fallback',
      (tester) async {
        _served = [
          _event(1, image: 'https://images.example.com/a.jpg'),
          _event(2, title: 'Sans photo'),
        ];
        await _inServer(() async {
          await pumpRouter(tester, DuoPose.openPortrait);
          expect(
            find.byType(Image),
            findsOneWidget,
            reason: 'only the first has a photo',
          );
          expect(find.byType(EventPhoto), findsNWidgets(2));
        });
      },
    );

    testWidgets(
      'opening an event flies the photo from the card to the header',
      (tester) async {
        await _inServer(() async {
          await pumpRouter(tester, DuoPose.openPortrait);
          final card = photoRects(tester).first;
          await tester.tap(find.text('Dîner de Shabbat'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          final during = photoRects(tester);

          // The flying photo is in neither place: it is on its way up.
          final flying = during.where(
            (r) => r.top > 0 && r.top < card.top && r.width > 0,
          );
          expect(
            flying,
            isNotEmpty,
            reason: 'a photo between the card ($card) and the header: $during',
          );
          await tester.pumpAndSettle();
          final landed = photoRects(tester);
          expect(landed, hasLength(1), reason: 'the flying photo is gone');
          expect(landed.single.top, 0);
          expect(
            tester
                .widget<Opacity>(
                  find
                      .ancestor(
                        of: find.byType(EventPhoto),
                        matching: find.byType(Opacity),
                      )
                      .first,
                )
                .opacity,
            1,
            reason: 'the header photo shows once the flight has landed',
          );
          expect(find.text('20 h 00 – 22 h 30'), findsOneWidget);
        });
      },
    );

    testWidgets('going back flies it to the card again', (tester) async {
      await _inServer(() async {
        await pumpRouter(tester, DuoPose.openPortrait);
        final card = photoRects(tester).first;
        await tester.tap(find.text('Dîner de Shabbat'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DirectionalIcon));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final during = photoRects(tester);
        expect(
          during.where((r) => r.top > 0 && r.top < card.top),
          isNotEmpty,
          reason: 'a photo on its way back to the card ($card): $during',
        );
        await tester.pumpAndSettle();
        expect(find.byType(EventPhoto), findsNWidgets(2));
        expect(find.text('Conférence'), findsOneWidget);
      });
    });

    testWidgets('reduced motion: no flight, the page only fades', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _inServer(() async {
        await pumpRouter(tester, DuoPose.openPortrait);
        final cards = photoRects(tester);
        await tester.tap(find.text('Dîner de Shabbat'));
        await tester.pump();
        final opening = photoRects(tester);
        await tester.pumpAndSettle();
        final landed = photoRects(tester).single;
        for (final rect in opening) {
          expect(
            cards.contains(rect) || rect == landed,
            isTrue,
            reason: 'a photo in the air at $rect, not on a card or the header',
          );
        }
        expect(find.text('Dîner de Shabbat'), findsWidgets);
      });
    });

    testWidgets('book: the photo lands on the left page', (tester) async {
      await _inServer(() async {
        await pumpRouter(tester, DuoPose.halfOpenBook);
        await tester.tap(find.text('Dîner de Shabbat').first);
        await tester.pumpAndSettle();
        final landed = photoRects(tester);
        expect(landed, hasLength(1));
        expect(
          landed.single.right,
          lessThanOrEqualTo(DuoPose.halfOpenBook.fold!.left),
        );
        expect(foldCrossingProblems(tester, DuoPose.halfOpenBook), isEmpty);
      });
    });
  });
}
