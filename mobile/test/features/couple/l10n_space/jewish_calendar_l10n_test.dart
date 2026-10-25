import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/presentation/features/couple/screens/jewish_calendar_screen.dart';
import 'package:mazl/presentation/features/navigation/screens/couple_navigation_screen.dart';

import '../../../helpers/l10n_helpers.dart';
import 'text_fit.dart';

const _languages = [
  Locale('fr'),
  Locale('en'),
  Locale('he'),
  Locale('es'),
  Locale('ru'),
];

/// Le plus petit téléphone, mais assez haut pour construire toute la liste.
const _tallPhone = Size(360, 4200);

const _englishMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

const _englishNames = {
  JewishHolidayId.roshHashana: 'Rosh Hashanah',
  JewishHolidayId.yomKippur: 'Yom Kippur',
  JewishHolidayId.sukkot: 'Sukkot',
  JewishHolidayId.sheminiAtzeret: 'Shemini Atzeret',
  JewishHolidayId.simchatTorah: 'Simchat Torah',
  JewishHolidayId.hanukkah: 'Hanukkah',
  JewishHolidayId.tuBishvat: 'Tu BiShvat',
  JewishHolidayId.purim: 'Purim',
  JewishHolidayId.pesach: 'Passover',
  JewishHolidayId.yomHashoah: 'Yom HaShoah',
  JewishHolidayId.yomHazikaron: 'Yom HaZikaron',
  JewishHolidayId.yomHaatzmaut: 'Yom HaAtzmaut',
  JewishHolidayId.yomYerushalayim: 'Yom Yerushalayim',
  JewishHolidayId.lagBaomer: 'Lag BaOmer',
  JewishHolidayId.shavuot: 'Shavuot',
};

Future<void> _pumpCalendar(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) => pumpLocalized(
  tester,
  const JewishCalendarScreen(),
  locale: locale,
  brightness: brightness,
  size: _tallPhone,
);

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUpAll(loadAppFont);

  group('calendrier juif', () {
    testWidgets('en anglais : titres, Shabbat et fêtes dans la langue', (
      tester,
    ) async {
      await _pumpCalendar(tester);

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('THIS SHABBAT'), findsOneWidget);
      expect(find.text('Candle lighting'), findsOneWidget);
      expect(find.text('Havdalah'), findsOneWidget);
      expect(find.text('Ideas for this Shabbat'), findsOneWidget);
      expect(find.text('Upcoming holidays'), findsOneWidget);
      expect(find.text('Prepare dinner together'), findsOneWidget);

      final now = DateTime.now();
      expect(
        find.text('${_englishMonths[now.month - 1]} ${now.year}'),
        findsOneWidget,
      );
      for (final holiday in JewishCalendarService().getUpcomingHolidays()) {
        expect(
          find.text(_englishNames[holiday.id]!),
          findsOneWidget,
          reason: holiday.id.name,
        );
        expect(find.text(holiday.hebrewName), findsOneWidget);
      }
    });

    testWidgets('les heures de Shabbat sont des heures lisibles', (
      tester,
    ) async {
      await _pumpCalendar(tester);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d{1,2}:\d{2}$').hasMatch(w.data ?? ''),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets(
      'en hébreu : de droite à gauche, nom de la fête écrit une seule fois',
      (tester) async {
        await _pumpCalendar(tester, locale: const Locale('he'));

        expect(find.text('לוח שנה'), findsOneWidget);
        expect(
          textDirectionAt(tester, find.text('לוח שנה')),
          TextDirection.rtl,
        );
        for (final holiday in JewishCalendarService().getUpcomingHolidays()) {
          expect(
            find.text(holiday.hebrewName),
            findsOneWidget,
            reason: holiday.id.name,
          );
        }
      },
    );

    testWidgets('les flèches de mois se retournent en hébreu', (tester) async {
      await _pumpCalendar(tester, locale: const Locale('he'));
      // Le mois précédent est à droite du titre : sa flèche pointe vers la droite.
      final previous = tester.getCenter(find.byIcon(LucideIcons.chevronRight));
      final next = tester.getCenter(find.byIcon(LucideIcons.chevronLeft));
      expect(previous.dx, greaterThan(next.dx));

      await _pumpCalendar(tester);
      final previousEn = tester.getCenter(find.byIcon(LucideIcons.chevronLeft));
      final nextEn = tester.getCenter(find.byIcon(LucideIcons.chevronRight));
      expect(previousEn.dx, lessThan(nextEn.dx));
    });

    // La semaine commence le lundi en français, le dimanche en anglais et en
    // hébreu : chaque jour doit tomber dans la colonne de son nom.
    for (final (locale, firstWeekdayIndex, rtl) in const [
      (Locale('fr'), 1, false),
      (Locale('en'), 0, false),
      (Locale('he'), 0, true),
      (Locale('ru'), 1, false),
    ]) {
      testWidgets(
        '${locale.languageCode} : chaque jour est dans la colonne de son jour',
        (tester) async {
          await _pumpCalendar(tester, locale: locale);
          final now = DateTime.now();
          const gridWidth = 360.0 - 48;
          const column = gridWidth / 7;
          for (final day in [1, 8, 15, 22, 28]) {
            final date = DateTime(now.year, now.month, day);
            final slot = ((date.weekday % 7) - firstWeekdayIndex + 7) % 7;
            final expectedX = rtl
                ? 360 - 24 - (slot + 0.5) * column
                : 24 + (slot + 0.5) * column;
            final cell = tester.getCenter(
              find.byKey(Key('calendar-day-${_dayKey(date)}')),
            );
            expect(
              cell.dx,
              closeTo(expectedX, 1),
              reason: '${locale.languageCode} le $day',
            );
          }
        },
      );
    }

    for (final locale in _languages) {
      for (final brightness in Brightness.values) {
        testWidgets(
          '${locale.languageCode} ${brightness.name} : aucun débordement à 360 px',
          (tester) async {
            await _pumpCalendar(tester, locale: locale, brightness: brightness);
            expect(tester.takeException(), isNull);
            expect(wordsTooWide(tester), isEmpty);
          },
        );
      }
    }
  });

  group('barre du bas du mode couple', () {
    Future<void> pumpShell(WidgetTester tester, Locale locale) async {
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) =>
                CoupleNavigationScreen(navigationShell: shell),
            branches: [
              for (final path in ['/a', '/b', '/c', '/d'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(path: path, builder: (_, __) => const SizedBox()),
                  ],
                ),
            ],
          ),
        ],
      );
      await pumpLocalized(
        tester,
        Router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          backButtonDispatcher: RootBackButtonDispatcher(),
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();
    }

    // La barre n'écrit pas ses libellés : elle les donne à la lecture d'écran.
    testWidgets('quatre onglets nommés en anglais pour la lecture d\'écran', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShell(tester, const Locale('en'));
      for (final label in ['Activities', 'Calendar', 'Events', 'Our space']) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      semantics.dispose();
    });

    testWidgets('quatre onglets nommés en français, comme avant', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShell(tester, const Locale('fr'));
      for (final label in [
        'Activités',
        'Calendrier',
        'Événements',
        'Notre espace',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      semantics.dispose();
    });

    for (final locale in _languages) {
      testWidgets('${locale.languageCode} : onglets sans débordement', (
        tester,
      ) async {
        await pumpShell(tester, locale);
        expect(tester.takeException(), isNull);
        expect(wordsTooWide(tester), isEmpty);
      });
    }
  });
}
