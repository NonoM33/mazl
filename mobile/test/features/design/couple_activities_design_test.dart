import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activities_feed_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_activity_detail_screen.dart';
import 'package:mazl/presentation/features/couple/screens/saved_activities_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/activity_visual.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

// Paid on 2026-10-23: the activities tab showed a pink badge, emoji chips, a
// pink-to-burgundy gradient card with a big emoji drawn through its title, and
// the text of the stacked cards showing through underneath. These tests look
// at what is actually on screen.

const _feed = 'GET /api/couple/activities?limit=50&offset=0';

const _first = 'Dîner aux chandelles';
const _second = 'Journée au spa';
const _third = 'Hammam à deux';

final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}]',
  unicode: true,
);

const _sizes = [Size(390, 844), Size(360, 740)];

Map<String, dynamic> _rich(int id, String title, String category) => {
  ...activityRow(id: id, title: title, category: category),
  'is_partner': true,
  'discount_percent': 15,
  'discount_code': 'MAZL15',
  'phone': '+33100000000',
  'website': 'https://example.com',
  'booking_url': 'https://example.com/reserver',
};

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required ThemeData theme,
  required Widget Function(CoupleApiService) screen,
  required void Function(FakeCoupleTransport) setUp,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final transport = FakeCoupleTransport();
  setUp(transport);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: screen(CoupleApiService(transport: transport)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _feedRoutes(FakeCoupleTransport t) => t.reply(
  _feed,
  ok({
    'activities': [
      _rich(1, _first, 'gastronomy'),
      _rich(2, _second, 'wellness'),
      _rich(3, _third, 'wellness'),
    ],
  }),
);

void _detailRoutes(FakeCoupleTransport t) {
  t.reply(
    'GET /api/couple/activities/4',
    ok({'activity': _rich(4, _first, 'gastronomy')}),
  );
  t.reply('GET /api/couple/saved', ok({'activities': []}));
}

void _savedRoutes(FakeCoupleTransport t) => t.reply(
  'GET /api/couple/saved',
  ok({
    'activities': [
      for (final (i, title) in [_first, _second, _third].indexed)
        {
          ..._rich(i + 1, title, i == 0 ? 'gastronomy' : 'wellness'),
          'saved_at': '2026-10-20T18:30:00.000Z',
          'user_notes': null,
        },
    ],
  }),
);

Widget _feedScreen(CoupleApiService api) =>
    CoupleActivitiesFeedScreen(apiService: api);
Widget _detailScreen(CoupleApiService api) =>
    CoupleActivityDetailScreen(activityId: '4', apiService: api);
Widget _savedScreen(CoupleApiService api) =>
    SavedActivitiesScreen(apiService: api);

List<String> _allTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

void _expectNoEmoji(WidgetTester tester) {
  final withEmoji = _allTexts(tester).where(_emoji.hasMatch).toList();
  expect(withEmoji, isEmpty, reason: 'émoji à l’écran : $withEmoji');
}

/// Nothing drawn with a gradient or a drop shadow (a halo around a button).
void _expectFlat(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration) {
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    }
  }
}

void main() {
  final themes = {'clair': AppTheme.lightTheme, 'sombre': AppTheme.darkTheme};

  for (final size in _sizes) {
    for (final entry in themes.entries) {
      final label = '${size.width.toInt()}x${size.height.toInt()} ${entry.key}';

      group('flux des activités ($label)', () {
        testWidgets('aucun débordement, aucun émoji, aucun dégradé', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            theme: entry.value,
            screen: _feedScreen,
            setUp: _feedRoutes,
          );

          expect(tester.takeException(), isNull);
          _expectNoEmoji(tester);
          _expectFlat(tester);
          expect(find.text(_first), findsOneWidget);
        });
      });

      group('détail d’une activité ($label)', () {
        testWidgets('aucun débordement, aucun émoji, aucun dégradé', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            theme: entry.value,
            screen: _detailScreen,
            setUp: _detailRoutes,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_first), findsWidgets);
          _expectNoEmoji(tester);
          _expectFlat(tester);
        });
      });

      group('activités enregistrées ($label)', () {
        testWidgets('aucun débordement, aucun émoji, aucun dégradé', (
          tester,
        ) async {
          await _pump(
            tester,
            size: size,
            theme: entry.value,
            screen: _savedScreen,
            setUp: _savedRoutes,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_first), findsOneWidget);
          _expectNoEmoji(tester);
          _expectFlat(tester);
        });
      });
    }
  }

  group('flux des activités : le canon', () {
    Future<void> pumpFeed(WidgetTester tester) => _pump(
      tester,
      size: _sizes.first,
      theme: AppTheme.lightTheme,
      screen: _feedScreen,
      setUp: _feedRoutes,
    );

    testWidgets('seul le texte de la carte du dessus est à l’écran', (
      tester,
    ) async {
      await pumpFeed(tester);

      expect(find.text(_first), findsOneWidget);
      // The cards stacked behind are bare shells: their text is not even built.
      expect(find.text(_second), findsNothing);
      expect(find.text(_third), findsNothing);
      expect(find.textContaining('Journée'), findsNothing);
      expect(find.textContaining('Hammam'), findsNothing);
    });

    testWidgets('après un passage, la carte suivante apparaît seule', (
      tester,
    ) async {
      await _pump(
        tester,
        size: _sizes.first,
        theme: AppTheme.lightTheme,
        screen: _feedScreen,
        setUp: (t) {
          _feedRoutes(t);
          t.reply('POST /api/couple/activities/1/pass', ok({}));
        },
      );

      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is RoundIconButton && w.icon == LucideIcons.x && w.size >= 56,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(_second), findsOneWidget);
      expect(find.text(_first), findsNothing);
      expect(find.text(_third), findsNothing);
    });

    testWidgets('le titre est seul : en-tête sans badge « Couple »', (
      tester,
    ) async {
      await pumpFeed(tester);

      expect(find.text('Activités'), findsOneWidget);
      expect(find.text('Couple'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is RoundIconButton && w.icon == LucideIcons.bookmark,
        ),
        findsWidgets,
      );
    });

    testWidgets('la puce choisie est en encre pleine, texte blanc', (
      tester,
    ) async {
      await pumpFeed(tester);
      final scheme = AppTheme.lightTheme.colorScheme;

      Material chipOf(String label) => tester.widget<Material>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      );
      TextStyle styleOf(String label) =>
          tester.widget<Text>(find.text(label)).style!;

      expect(chipOf('Tout').color, scheme.onSurface);
      expect(styleOf('Tout').color, scheme.surface);
      expect(chipOf('Culture').color, scheme.surfaceContainer);
      expect(styleOf('Culture').color, scheme.onSurface);
    });

    testWidgets('le titre de la carte ne chevauche aucune icône ni image', (
      tester,
    ) async {
      await pumpFeed(tester);

      final title = tester.getRect(find.text(_first));
      final obstacles = <String, Rect>{
        for (final (i, e) in tester.widgetList<Icon>(find.byType(Icon)).indexed)
          'icône ${e.icon} #$i': tester.getRect(find.byType(Icon).at(i)),
        for (final (i, _)
            in tester
                .widgetList<ActivityVisual>(find.byType(ActivityVisual))
                .indexed)
          'visuel #$i': tester.getRect(find.byType(ActivityVisual).at(i)),
        for (final (i, _)
            in tester
                .widgetList<RoundIconButton>(find.byType(RoundIconButton))
                .indexed)
          'bouton #$i': tester.getRect(find.byType(RoundIconButton).at(i)),
      };

      expect(obstacles, isNotEmpty);
      obstacles.forEach((name, rect) {
        expect(
          title.overlaps(rect),
          isFalse,
          reason: '« $_first » ($title) chevauche $name ($rect)',
        );
      });
    });

    testWidgets('sans image : aplat plein de la teinte photo, icône Lucide', (
      tester,
    ) async {
      await pumpFeed(tester);

      final visual = find.byType(ActivityVisual);
      expect(visual, findsOneWidget);
      expect(
        find.descendant(of: visual, matching: find.byType(ColoredBox)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: visual,
          matching: find.byIcon(activityCategoryIcon('gastronomy')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('les actions sont des RoundIconButton sans halo', (
      tester,
    ) async {
      await pumpFeed(tester);

      for (final icon in [
        LucideIcons.x,
        LucideIcons.bookmark,
        LucideIcons.info,
      ]) {
        expect(
          find.byWidgetPredicate(
            (w) => w is RoundIconButton && w.icon == icon && w.size >= 56,
          ),
          findsOneWidget,
          reason: 'bouton d’action $icon',
        );
      }
      _expectFlat(tester);
    });

    testWidgets('la pilule partenaire et « Casher » sont là', (tester) async {
      await pumpFeed(tester);

      expect(find.text('-15 % Partenaire MAZL'), findsOneWidget);
      expect(find.text('Casher'), findsOneWidget);
    });

    // Vu au simulateur le 2026-10-23 : brume sur brume, « Casher » et la
    // catégorie flottaient sans contour, comme du texte nu.
    testWidgets('les puces de la carte se détachent de son fond brume', (tester) async {
      await pumpFeed(tester);
      final scheme = Theme.of(tester.element(find.text('Casher'))).colorScheme;
      final pill = tester.widget<Container>(
        find.ancestor(of: find.text('Casher'), matching: find.byType(Container)).first,
      );
      final color = (pill.decoration! as BoxDecoration).color;
      expect(color, isNot(scheme.surfaceContainer));
      expect(color, scheme.surface);
    });

    testWidgets('titre de page en grand, comme les autres onglets du couple', (tester) async {
      await pumpFeed(tester);
      final title = tester.widget<Text>(find.text('Activités'));
      expect(title.style?.fontSize, 40);
    });
  });
}
