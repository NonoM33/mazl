import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activities_feed_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activity_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/saved_activities_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import '../../../mocks/couple_backend_shapes.dart';
import '../../../mocks/fake_couple_transport.dart';
import 'feed_l10n_support.dart';

void main() {
  setUpCoupleFeedTests();

  group('activities feed', () {
    Future<void> pumpFeed(
      WidgetTester tester,
      FakeCoupleTransport transport,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        CoupleActivitiesFeedScreen(
          apiService: CoupleApiService(transport: transport),
        ),
        locale: locale,
        brightness: brightness,
      );
      await settle(tester);
    }

    FakeCoupleTransport withCards() => FakeCoupleTransport()
      ..reply(
        kFeedRoute,
        ok({
          'activities': [partnerActivity()],
        }),
      );

    testWidgets('speaks English: title, filters, card pills', (tester) async {
      await pumpFeed(tester, withCards(), kEn);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Wellness'), findsWidgets);
      expect(find.text('15% off · MAZL partner'), findsOneWidget);
      expect(find.text('Kosher'), findsOneWidget);
      expect(find.text('Activités'), findsNothing);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'renders with a card in ${locale.languageCode} (${brightness.name}) '
          'without overflow',
          (tester) async {
            await pumpFeed(tester, withCards(), locale, brightness: brightness);
            expect(tester.takeException(), isNull);
            expect(find.text('Atelier poterie'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('is right-to-left in Hebrew', (tester) async {
      await pumpFeed(tester, withCards(), kHe);
      expect(find.text('פעילויות'), findsOneWidget);
      expect(textDirectionAt(tester, find.text('פעילויות')), TextDirection.rtl);
    });

    testWidgets(
      'the rating pill sits on the start side, whatever the language',
      (tester) async {
        await pumpFeed(tester, withCards(), kEn);
        expect(tester.getCenter(find.text('4.8 (124)')).dx, lessThan(180));
        await pumpFeed(tester, withCards(), kHe);
        expect(tester.getCenter(find.text('4.8 (124)')).dx, greaterThan(180));
      },
    );

    testWidgets('the empty state is translated', (tester) async {
      final t = FakeCoupleTransport()
        ..reply(kFeedRoute, ok({'activities': []}));
      await pumpFeed(tester, t, kEn);
      expect(find.text('No activities right now'), findsOneWidget);
      expect(find.text('New ideas are coming soon.'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('a failing load says why, in the member\'s language', (
      tester,
    ) async {
      final t = FakeCoupleTransport()
        ..fail(kFeedRoute, const SocketException('down'));
      await pumpFeed(tester, t, kEn);
      expect(find.text('Couldn\'t load'), findsOneWidget);
      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Serveur injoignable. Réessayez.'), findsNothing);
    });
  });

  group('saved activities', () {
    Future<void> pumpSaved(
      WidgetTester tester,
      FakeCoupleTransport transport,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        SavedActivitiesScreen(
          apiService: CoupleApiService(transport: transport),
        ),
        locale: locale,
        brightness: brightness,
      );
      await settle(tester);
    }

    FakeCoupleTransport withOne() => FakeCoupleTransport()
      ..reply(
        kSavedRoute,
        ok({
          'activities': [savedActivityRow(id: 1, title: 'Spa en duo')],
        }),
      );

    testWidgets('speaks English, price formatted for the language', (
      tester,
    ) async {
      await pumpSaved(tester, withOne(), kEn);
      expect(find.text('Saved activities'), findsOneWidget);
      // The category is a section label, which the design writes in capitals.
      expect(find.text('WELLNESS'), findsOneWidget);
      expect(find.text('€120'), findsOneWidget);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets('renders in ${locale.languageCode} (${brightness.name}) '
            'without overflow', (tester) async {
          await pumpSaved(tester, withOne(), locale, brightness: brightness);
          expect(tester.takeException(), isNull);
          expect(find.text('Spa en duo'), findsOneWidget);
        });
      }
    }

    testWidgets('empty state and removal dialog are translated', (
      tester,
    ) async {
      final empty = FakeCoupleTransport()
        ..reply(kSavedRoute, ok({'activities': []}));
      await pumpSaved(tester, empty, kEn);
      expect(find.text('No saved activities'), findsOneWidget);
      expect(find.text('Swipe a card up to keep it.'), findsOneWidget);
      expect(find.text('Discover activities'), findsOneWidget);
    });

    testWidgets('the removal dialog is translated', (tester) async {
      await pumpSaved(tester, withOne(), kEn);
      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from the list?'), findsOneWidget);
      expect(
        find.text(
          'Do you want to remove "Spa en duo" from your saved activities?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('is right-to-left in Hebrew', (tester) async {
      await pumpSaved(tester, withOne(), kHe);
      expect(find.text('פעילויות שמורות'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('פעילויות שמורות')),
        TextDirection.rtl,
      );
    });
  });

  group('activity detail', () {
    Future<void> pumpDetail(
      WidgetTester tester,
      FakeCoupleTransport transport,
      Locale locale, {
      Brightness brightness = Brightness.light,
      String id = '4',
    }) async {
      await pumpLocalized(
        tester,
        CoupleActivityDetailScreen(
          activityId: id,
          apiService: CoupleApiService(transport: transport),
        ),
        locale: locale,
        brightness: brightness,
      );
      await settle(tester);
    }

    FakeCoupleTransport withPartner() => FakeCoupleTransport()
      ..reply(
        'GET /api/couple/activities/4',
        ok({'activity': partnerActivity()}),
      )
      ..reply(kSavedRoute, ok({'activities': []}));

    testWidgets('speaks English: pills, promo code, sections, price bar', (
      tester,
    ) async {
      await pumpDetail(tester, withPartner(), kEn);
      expect(find.text('Wellness'), findsOneWidget);
      expect(find.text('4.8 (124 reviews)'), findsOneWidget);
      expect(find.text('2 h'), findsOneWidget);
      expect(find.text('15% off · Partner'), findsOneWidget);
      expect(find.text('Kosher'), findsOneWidget);
      expect(find.text('MAZL PROMO CODE'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('€120'), findsWidgets);
      expect(find.text('Réserver'), findsNothing);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets('renders in ${locale.languageCode} (${brightness.name}) '
            'without overflow, down to the contact buttons', (tester) async {
          await pumpDetail(
            tester,
            withPartner(),
            locale,
            brightness: brightness,
          );
          await scrollThrough(tester, find.byType(CustomScrollView));
          expect(tester.takeException(), isNull);
          expect(find.text('Atelier poterie'), findsOneWidget);
        });
      }
    }

    testWidgets('French is unchanged', (tester) async {
      await pumpDetail(tester, withPartner(), const Locale('fr'));
      expect(find.text('Réserver'), findsOneWidget);
      expect(find.text('À partir de'), findsOneWidget);
      expect(find.text('-15 % Partenaire'), findsOneWidget);
      expect(find.text('Casher'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('a missing activity is translated', (tester) async {
      final t = FakeCoupleTransport()
        ..reply('GET /api/couple/activities/4', error('Activity not found'))
        ..reply(kSavedRoute, ok({'activities': []}));
      await pumpDetail(tester, t, kEn);
      expect(find.text('Activity not found'), findsOneWidget);
      expect(find.text('It\'s no longer offered.'), findsOneWidget);
    });

    testWidgets('a bad id is the same "not found" screen', (tester) async {
      await pumpDetail(tester, FakeCoupleTransport(), kEn, id: 'abc');
      expect(find.text('Activity not found'), findsOneWidget);
    });
  });
}
