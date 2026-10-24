import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_event_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_events_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../../mocks/couple_backend_shapes.dart';
import '../../../mocks/fake_couple_transport.dart';
import 'feed_l10n_support.dart';

void main() {
  setUpCoupleFeedTests();

  group('events list', () {
    Future<void> pumpEvents(
      WidgetTester tester,
      FakeCoupleTransport transport,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        CoupleEventsScreen(apiService: CoupleApiService(transport: transport)),
        locale: locale,
        brightness: brightness,
      );
      await settle(tester);
    }

    FakeCoupleTransport withEvent({bool featured = false}) =>
        FakeCoupleTransport()
          ..reply(
            kEventsRoute,
            ok({
              'events': [
                {
                  ...eventRow(id: 3, title: 'Dîner de Shabbat'),
                  'is_featured': featured,
                },
              ],
            }),
          )
          ..reply(kRegisteredRoute, ok({'events': []}));

    testWidgets('speaks English: tabs, filters, card facts', (tester) async {
      await pumpEvents(tester, withEvent(featured: true), kEn);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Registered (0)'), findsOneWidget);
      expect(find.text('Dinner'), findsWidgets);
      expect(
        find.text('Thu, Nov 12 · 7:30\u202FPM'.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('€45 per couple'), findsOneWidget);
      expect(find.text('17 spots'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('Kosher'), findsOneWidget);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets('renders in ${locale.languageCode} (${brightness.name}) '
            'without overflow', (tester) async {
          await pumpEvents(
            tester,
            withEvent(featured: true),
            locale,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Dîner de Shabbat'), findsOneWidget);
        });
      }
    }

    testWidgets('is right-to-left in Hebrew', (tester) async {
      await pumpEvents(tester, withEvent(), kHe);
      expect(find.text('אירועים'), findsOneWidget);
      expect(textDirectionAt(tester, find.text('אירועים')), TextDirection.rtl);
    });

    testWidgets('a full event says so, and the empty tab is translated', (
      tester,
    ) async {
      final t = FakeCoupleTransport()
        ..reply(
          kEventsRoute,
          ok({
            'events': [eventRow(id: 3, currentCouples: 20, maxCouples: 20)],
          }),
        )
        ..reply(kRegisteredRoute, ok({'events': []}));
      await pumpEvents(tester, t, kEn);
      expect(find.text('Full'), findsOneWidget);
      await tester.tap(find.text('Registered (0)'));
      await tester.pumpAndSettle();
      expect(
        find.text('You\'re not registered for any events'),
        findsOneWidget,
      );
      expect(find.text('Discover events'), findsOneWidget);
    });

    testWidgets('the cancel dialog is translated', (tester) async {
      final t = FakeCoupleTransport()
        ..reply(
          kEventsRoute,
          ok({
            'events': [eventRow(id: 3, title: 'Brunch')],
          }),
        )
        ..reply(
          kRegisteredRoute,
          ok({
            'events': [registeredEventRow(id: 3)],
          }),
        );
      await pumpEvents(tester, t, kEn);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel your registration?'), findsOneWidget);
      expect(find.text('Yes, cancel'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('a full-event refusal shows a translated sentence', (
      tester,
    ) async {
      final t = withEvent()
        ..reply('POST /api/couple/events/3/register', error('Event is full'));
      await pumpEvents(tester, t, kEn);
      await tester.tap(find.text('Register'));
      await tester.pump();
      await tester.pump();
      expect(find.text('This event is full.'), findsOneWidget);
    });
  });

  group('event detail', () {
    Future<void> pumpEvent(
      WidgetTester tester,
      FakeCoupleTransport transport,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        CoupleEventDetailScreen(
          eventId: '3',
          apiService: CoupleApiService(transport: transport),
        ),
        locale: locale,
        brightness: brightness,
      );
      await settle(tester);
    }

    FakeCoupleTransport open({bool registered = false}) => FakeCoupleTransport()
      ..reply('GET /api/couple/events/3', ok({'event': eventRow(id: 3)}))
      ..reply(
        kRegisteredRoute,
        ok({
          'events': registered ? [registeredEventRow(id: 3)] : [],
        }),
      );

    testWidgets('speaks English: facts, price card, registration bar', (
      tester,
    ) async {
      await pumpEvent(tester, open(), kEn);
      expect(find.text('€45 per couple'), findsOneWidget);
      expect(find.text('17 spots left'), findsOneWidget);
      expect(find.text('Venue'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Dress code'), findsOneWidget);
      expect(find.text('Organized by'), findsOneWidget);
      expect(find.text('WHAT\'S INCLUDED'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets('renders in ${locale.languageCode} (${brightness.name}) '
            'without overflow', (tester) async {
          await pumpEvent(tester, open(), locale, brightness: brightness);
          await scrollThrough(tester, find.byType(SingleChildScrollView));
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets(
      'the back button sits on the start side, whatever the language',
      (tester) async {
        await pumpEvent(tester, open(), kEn);
        expect(
          tester.getCenter(backArrow(LucideIcons.arrowLeft)).dx,
          lessThan(180),
        );
        await pumpEvent(tester, open(), kHe);
        expect(
          tester.getCenter(backArrow(LucideIcons.arrowRight)).dx,
          greaterThan(180),
        );
      },
    );

    testWidgets('registered members can cancel', (tester) async {
      await pumpEvent(tester, open(registered: true), kEn);
      expect(backArrow(LucideIcons.arrowLeft), findsOneWidget);
      expect(find.text('Cancel my registration'), findsOneWidget);
    });

    testWidgets('the back arrow points the other way in Hebrew', (
      tester,
    ) async {
      await pumpEvent(tester, open(), kHe);
      // Lucide arrows do not mirror themselves: « back » points right.
      expect(backArrow(LucideIcons.arrowRight), findsOneWidget);
      expect(backArrow(LucideIcons.arrowLeft), findsNothing);
      expect(find.text('להירשם'), findsOneWidget);
      expect(textDirectionAt(tester, find.text('להירשם')), TextDirection.rtl);
    });

    testWidgets('a missing event is translated', (tester) async {
      final t = FakeCoupleTransport()
        ..reply('GET /api/couple/events/3', error('Event not found'))
        ..reply(kRegisteredRoute, ok({'events': []}));
      await pumpEvent(tester, t, kEn);
      expect(find.text('Event not found'), findsOneWidget);
    });
  });
}
