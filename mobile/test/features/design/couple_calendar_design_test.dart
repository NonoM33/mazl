import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_event_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_events_screen.dart';
import 'package:mazl/presentation/features/couple/screens/jewish_calendar_screen.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';
import '../../helpers/l10n_helpers.dart';

// Passe DA « Encre & Tekhelet » des onglets Calendrier et Événements et du
// détail d'un événement : plus de rose, de dégradé ni d'émoji, et une grille
// du mois où le jour courant (encre) se distingue du jour choisi (accent).

const _upcoming = 'GET /api/couple/events?limit=50&offset=0';
const _registered = 'GET /api/couple/events/registered';

/// Pictogrammes et symboles dessinés en émoji couleur (pas l'hébreu).
final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}]',
  unicode: true,
);

const _sizes = <String, Size>{
  '390x844': Size(390, 844),
  '360x740': Size(360, 740),
};

final _themes = <String, ThemeData>{
  'clair': AppTheme.lightTheme,
  'sombre': AppTheme.darkTheme,
};

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required ThemeData theme,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, locale: kTestLocale, theme: theme, home: screen));
  await tester.pump();
  await tester.pump();
}

/// Fait défiler jusqu'en bas pour construire (donc mesurer) toute la liste.
Future<void> _scrollThrough(WidgetTester tester) async {
  final scrollable = find
      .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
      .first;
  for (var i = 0; i < 6; i++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pump();
  }
}

void _expectNoGradient(WidgetTester tester) {
  final gradients = <Widget>[];
  for (final element in find.byType(Container).evaluate()) {
    final decoration = (element.widget as Container).decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      gradients.add(element.widget);
    }
  }
  for (final element in find.byType(DecoratedBox).evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      gradients.add(element.widget);
    }
  }
  expect(
    gradients,
    isEmpty,
    reason: 'le design Encre & Tekhelet interdit les dégradés',
  );
}

void _expectNoEmoji(WidgetTester tester) {
  final texts = <String>[
    for (final element in find.byType(Text).evaluate())
      (element.widget as Text).data ??
          (element.widget as Text).textSpan?.toPlainText() ??
          '',
  ];
  for (final text in texts) {
    expect(_emoji.hasMatch(text), isFalse, reason: 'émoji dans « $text »');
  }
}

Color? _fillOf(WidgetTester tester, Key key) {
  final decoration = tester.widget<Container>(find.byKey(key)).decoration;
  return (decoration! as BoxDecoration).color;
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _row({
  required int id,
  required String title,
  String category = 'dinner',
  int? priceCents = 4500,
  bool featured = false,
  bool kosher = true,
  String? city = 'Paris',
  int? maxCouples = 20,
  int currentCouples = 3,
}) => {
  ...eventRow(
    id: id,
    title: title,
    currentCouples: currentCouples,
    maxCouples: maxCouples,
  ),
  'category': category,
  'price_cents': priceCents,
  'is_featured': featured,
  'is_kosher': kosher,
  'city': city,
};

void _events(FakeCoupleTransport t) {
  t.reply(
    _upcoming,
    ok({
      'events': [
        _row(id: 1, title: 'Dîner de Shabbat chez les Cohen', featured: true),
        _row(
          id: 2,
          title: 'Brunch de Hanouka',
          category: 'brunch',
          priceCents: 0,
          kosher: false,
          city: null,
          maxCouples: null,
        ),
        _row(
          id: 3,
          title: 'Atelier poterie à deux',
          category: 'workshop',
          maxCouples: 10,
          currentCouples: 10,
        ),
      ],
    }),
  );
  t.reply(
    _registered,
    ok({
      'events': [registeredEventRow(id: 1)],
    }),
  );
}

Future<FakeCoupleTransport> _pumpEvents(
  WidgetTester tester, {
  required Size size,
  required ThemeData theme,
}) async {
  final transport = FakeCoupleTransport();
  _events(transport);
  await _pump(
    tester,
    CoupleEventsScreen(apiService: CoupleApiService(transport: transport)),
    size: size,
    theme: theme,
  );
  return transport;
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Size size,
  required ThemeData theme,
  required bool registered,
  int current = 3,
}) async {
  final transport = FakeCoupleTransport()
    ..reply(
      'GET /api/couple/events/3',
      ok({
        'event': _row(
          id: 3,
          title: 'Dîner de Shabbat chez les Cohen',
          currentCouples: current,
        ),
      }),
    )
    ..reply(
      _registered,
      ok({
        'events': registered ? [registeredEventRow(id: 3)] : [],
      }),
    );
  await _pump(
    tester,
    CoupleEventDetailScreen(
      eventId: '3',
      apiService: CoupleApiService(transport: transport),
    ),
    size: size,
    theme: theme,
  );
}

void main() {
  for (final sizeEntry in _sizes.entries) {
    for (final themeEntry in _themes.entries) {
      final label = '${sizeEntry.key}, ${themeEntry.key}';

      group('rendu $label', () {
        testWidgets('calendrier : aucun débordement, ni dégradé ni émoji', (
          tester,
        ) async {
          await _pump(
            tester,
            const JewishCalendarScreen(),
            size: sizeEntry.value,
            theme: themeEntry.value,
          );
          expect(find.text('Calendrier'), findsOneWidget);
          await _scrollThrough(tester);

          expect(tester.takeException(), isNull);
          _expectNoGradient(tester);
          _expectNoEmoji(tester);
        });

        testWidgets('événements : aucun débordement, ni dégradé ni émoji', (
          tester,
        ) async {
          await _pumpEvents(
            tester,
            size: sizeEntry.value,
            theme: themeEntry.value,
          );
          expect(find.text('Événements'), findsOneWidget);
          await _scrollThrough(tester);

          expect(tester.takeException(), isNull);
          _expectNoGradient(tester);
          _expectNoEmoji(tester);
        });

        testWidgets('détail inscrit : aucun débordement, ni dégradé ni émoji', (
          tester,
        ) async {
          await _pumpDetail(
            tester,
            size: sizeEntry.value,
            theme: themeEntry.value,
            registered: true,
          );
          await _scrollThrough(tester);

          expect(tester.takeException(), isNull);
          expect(
            find.widgetWithText(OutlinedButton, 'Annuler mon inscription'),
            findsOneWidget,
          );
          _expectNoGradient(tester);
          _expectNoEmoji(tester);
        });

        testWidgets('détail complet : aucun débordement', (tester) async {
          await _pumpDetail(
            tester,
            size: sizeEntry.value,
            theme: themeEntry.value,
            registered: false,
            current: 20,
          );
          await _scrollThrough(tester);

          expect(tester.takeException(), isNull);
          expect(find.widgetWithText(ElevatedButton, 'Complet'), findsOneWidget);
        });
      });
    }
  }

  group('calendrier : jour courant et jour choisi', () {
    final today = DateTime.now();
    final other = DateTime(today.year, today.month, today.day == 1 ? 2 : 1);
    final todayKey = Key('calendar-day-${_dayKey(today)}');
    final otherKey = Key('calendar-day-${_dayKey(other)}');

    testWidgets(
      'clair : pastille d\'encre pour aujourd\'hui, d\'accent pour le jour choisi',
      (tester) async {
        final theme = AppTheme.lightTheme;
        await _pump(
          tester,
          const JewishCalendarScreen(),
          size: _sizes['390x844']!,
          theme: theme,
        );

        expect(_fillOf(tester, todayKey), AppColors.ink);
        expect(_fillOf(tester, otherKey), isNull);

        await tester.tap(find.byKey(Key('calendar-cell-${_dayKey(other)}')));
        await tester.pump();

        expect(_fillOf(tester, otherKey), theme.colorScheme.primary);
        expect(_fillOf(tester, todayKey), AppColors.ink);
        expect(_fillOf(tester, otherKey), isNot(_fillOf(tester, todayKey)));
      },
    );

    testWidgets(
      'sombre : aujourd\'hui prend la couleur du texte, le jour choisi l\'accent',
      (tester) async {
        final theme = AppTheme.darkTheme;
        await _pump(
          tester,
          const JewishCalendarScreen(),
          size: _sizes['390x844']!,
          theme: theme,
        );

        expect(_fillOf(tester, todayKey), theme.colorScheme.onSurface);

        await tester.tap(find.byKey(Key('calendar-cell-${_dayKey(other)}')));
        await tester.pump();

        expect(_fillOf(tester, otherKey), theme.colorScheme.primary);
        expect(_fillOf(tester, otherKey), isNot(_fillOf(tester, todayKey)));
      },
    );

    testWidgets('toucher deux fois le jour choisi le désélectionne', (
      tester,
    ) async {
      await _pump(
        tester,
        const JewishCalendarScreen(),
        size: _sizes['390x844']!,
        theme: AppTheme.lightTheme,
      );
      final cell = find.byKey(Key('calendar-cell-${_dayKey(other)}'));

      await tester.tap(cell);
      await tester.pump();
      await tester.tap(cell);
      await tester.pump();

      expect(_fillOf(tester, otherKey), isNull);
    });

    testWidgets(
      'chaque jour de fête à venir du mois affiché porte un point d\'accent',
      (tester) async {
        final holidays = JewishCalendarService().getUpcomingHolidays();
        final first = holidays.first.date;
        await _pump(
          tester,
          const JewishCalendarScreen(),
          size: _sizes['390x844']!,
          theme: AppTheme.lightTheme,
        );
        // Avance jusqu'au mois de la première fête.
        final months =
            (first.year - today.year) * 12 + first.month - today.month;
        for (var i = 0; i < months; i++) {
          await tester.tap(find.byIcon(LucideIcons.chevronRight));
          await tester.pump();
        }

        final dot = find.byKey(Key('calendar-dot-${_dayKey(first)}'));
        expect(dot, findsOneWidget);
        final decoration =
            tester.widget<Container>(dot).decoration! as BoxDecoration;
        expect(decoration.color, AppTheme.lightTheme.colorScheme.primary);
        // Un jour sans fête n'a pas de point.
        final quiet = DateTime(first.year, first.month, first.day == 1 ? 2 : 1);
        if (!holidays.any(
          (h) => !quiet.isBefore(h.date) && !quiet.isAfter(h.endDate ?? h.date),
        )) {
          expect(
            find.byKey(Key('calendar-dot-${_dayKey(quiet)}')),
            findsNothing,
          );
        }
      },
    );
  });

  group('événements : filtres et boutons', () {
    testWidgets('la puce choisie est pleine d\'encre, les autres en brume', (
      tester,
    ) async {
      final theme = AppTheme.lightTheme;
      await _pumpEvents(tester, size: _sizes['390x844']!, theme: theme);

      Color fill(String key) => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byKey(Key('events-filter-$key')),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;

      expect(fill('all'), theme.colorScheme.onSurface);
      expect(fill('dinner'), theme.colorScheme.surfaceContainer);
    });

    testWidgets(
      'l\'inscription est un ElevatedButton (encre), l\'annulation un OutlinedButton',
      (tester) async {
        await _pumpEvents(
          tester,
          size: const Size(390, 2400),
          theme: AppTheme.lightTheme,
        );

        expect(
          find.widgetWithText(ElevatedButton, 'S\'inscrire'),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Annuler'), findsOneWidget);
        expect(find.text('Gratuit'), findsOneWidget);
        expect(find.text('Complet'), findsOneWidget);
        expect(find.text('45\u00A0€/couple'), findsWidgets);
      },
    );

    testWidgets('la fin de la liste dégage la capsule de navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final transport = FakeCoupleTransport();
      _events(transport);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 96),
            ),
            child: CoupleEventsScreen(
              apiService: CoupleApiService(transport: transport),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await _scrollThrough(tester);

      final last = tester.getBottomLeft(find.text('Atelier poterie à deux'));
      expect(
        last.dy,
        lessThan(844 - 96),
        reason: 'rien ne doit finir sous la capsule',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('détail : bouton principal', () {
    testWidgets('le bouton est pleine largeur et décollé du bas de l\'écran', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        size: _sizes['390x844']!,
        theme: AppTheme.lightTheme,
        registered: false,
      );

      final button = find.widgetWithText(ElevatedButton, 'S\'inscrire');
      expect(button, findsOneWidget);
      final rect = tester.getRect(button);
      expect(rect.width, 390 - 48);
      expect(844 - rect.bottom, greaterThanOrEqualTo(12));
    });

    testWidgets('au-dessus de la capsule : au moins 12 pt d\'écart', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final transport = FakeCoupleTransport()
        ..reply(
          'GET /api/couple/events/3',
          ok({'event': _row(id: 3, title: 'Dîner')}),
        )
        ..reply(_registered, ok({'events': []}));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 96),
            ),
            child: CoupleEventDetailScreen(
              eventId: '3',
              apiService: CoupleApiService(transport: transport),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final rect = tester.getRect(
        find.widgetWithText(ElevatedButton, 'S\'inscrire'),
      );
      expect(844 - 96 - rect.bottom, greaterThanOrEqualTo(12));
    });
  });
}
