import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/success_story.dart';
import 'package:mazl/presentation/features/couple/screens/couple_dashboard_screen.dart';
import 'package:mazl/presentation/features/couple/screens/success_stories_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'feed_l10n_support.dart';

void main() {
  setUpCoupleFeedTests();

  group('couple dashboard', () {
    Future<void> pumpDashboard(
      WidgetTester tester,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) async {
      await pumpLocalized(
        tester,
        const CoupleDashboardScreen(),
        locale: locale,
        brightness: brightness,
      );
      await tester.pump();
    }

    testWidgets('speaks English, content of the service included', (
      tester,
    ) async {
      await pumpDashboard(tester, kEn);
      expect(find.text('0 days together'), findsOneWidget);
      expect(find.text('Question of the day'.toUpperCase()), findsOneWidget);
      expect(find.text('Connection'), findsOneWidget);
      expect(
        find.text('What is your favorite moment of the week together?'),
        findsOneWidget,
      );
      expect(find.text('Shabbat cooking'), findsOneWidget);
      final seen = await textsWhileScrolling(
        tester,
        find.byType(ListView).first,
      );
      expect(
        seen,
        containsAll([
          'OUR MILESTONES',
          'First week',
          '7 days together',
          'JEWISH CALENDAR',
          'Shabbat Beshalach',
          'Share your story',
          'Share',
        ]),
      );
      expect(seen, isNot(contains('Partager')));
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets('renders in ${locale.languageCode} (${brightness.name}) '
            'without overflow, top to bottom', (tester) async {
          await pumpDashboard(tester, locale, brightness: brightness);
          await scrollThrough(tester, find.byType(ListView).first);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('is right-to-left in Hebrew', (tester) async {
      await pumpDashboard(tester, kHe);
      expect(find.text('0 ימים יחד'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('0 ימים יחד')),
        TextDirection.rtl,
      );
    });

    testWidgets('the answer sheet and its confirmation are translated', (
      tester,
    ) async {
      await pumpDashboard(tester, kEn);
      await tester.tap(find.text('Answer'));
      await tester.pumpAndSettle();
      expect(find.text('Your answer…'), findsOneWidget);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(
        find.text('Answer sent. Your partner will be notified.'),
        findsOneWidget,
      );
    });
  });

  group('success stories', () {
    final story = SuccessStory(
      id: 1,
      couple1Name: 'Jeanne',
      couple2Name: 'Marc',
      story: 'Nous nous sommes rencontrés à une soirée de Pessah.',
      status: 'married',
      matchDate: DateTime(2026, 3, 14),
      submittedAt: DateTime(2026, 9, 1),
      likesCount: 1234,
    );

    Future<void> pumpCard(
      WidgetTester tester,
      Locale locale, {
      Brightness brightness = Brightness.light,
    }) => pumpLocalized(
      tester,
      Scaffold(
        body: ListView(
          children: [
            SuccessStoryCard(story: story, onLike: () {}, onShare: () {}),
          ],
        ),
      ),
      locale: locale,
      brightness: brightness,
    );

    testWidgets('a card speaks English, with the date in the language', (
      tester,
    ) async {
      await pumpCard(tester, kEn);
      expect(find.text('Married · since March 2026'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Jeanne & Marc'), findsOneWidget);
    });

    testWidgets('French is unchanged, month in French', (tester) async {
      await pumpCard(tester, const Locale('fr'));
      expect(find.text('Mariés · depuis mars 2026'), findsOneWidget);
    });

    for (final locale in kLocales) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'a card renders in ${locale.languageCode} (${brightness.name}) '
          'without overflow',
          (tester) async {
            await pumpCard(tester, locale, brightness: brightness);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('a card is right-to-left in Hebrew', (tester) async {
      await pumpCard(tester, kHe);
      expect(find.text('Jeanne & Marc'), findsOneWidget);
      expect(
        textDirectionAt(tester, find.text('Jeanne & Marc')),
        TextDirection.rtl,
      );
    });

    for (final locale in [kEn, kHe, kRu]) {
      testWidgets('the screen shows a translated failure, never the raw one', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const SuccessStoriesScreen(),
          locale: locale,
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Failed'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
      });
    }

    testWidgets('the submit sheet speaks English', (tester) async {
      await pumpLocalized(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => SubmitSuccessStoryDialog.show(context),
            child: const Text('open'),
          ),
        ),
        locale: kEn,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Share your story'), findsOneWidget);
      expect(find.text('Engaged'), findsOneWidget);
      expect(find.text('Submit our story'), findsOneWidget);
      expect(find.text('Photos (optional)'.toUpperCase()), findsOneWidget);
    });

    for (final locale in kLocales) {
      testWidgets('the submit sheet fits in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => SubmitSuccessStoryDialog.show(context),
              child: const Text('open'),
            ),
          ),
          locale: locale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
