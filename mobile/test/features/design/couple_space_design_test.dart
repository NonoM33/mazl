import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_anniversary.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/couple/screens/couple_dashboard_screen.dart';
import 'package:mazl/presentation/features/couple/screens/couple_space_screen.dart';
import 'package:mazl/presentation/features/couple/screens/success_stories_screen.dart';
import 'package:mazl/presentation/features/couple/widgets/anniversary_widget.dart';

import '../../mocks/couple_backend_shapes.dart';
import '../../mocks/fake_couple_transport.dart';

// Paid on 2026-10-23: « Notre espace » arrived with its own pink palette, an
// emoji in the title, gradient cards and coloured tiles. These tests read the
// RENDERED tree (not the sources, which couple_design_rules_test.dart covers).

const _phones = <String, Size>{
  '390x844': Size(390, 844),
  '360x740': Size(360, 740),
};
final _emoji = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2B55}]',
  unicode: true,
);

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.reset);
}

FakeCoupleTransport _transport({bool filled = true}) {
  final t = FakeCoupleTransport();
  t.reply(
    'GET /api/couple/stats',
    ok({
      'stats': statsRow(),
      'achievements': filled ? [achievementRow()] : [],
    }),
  );
  t.reply(
    'GET /api/couple/bucket-list',
    ok({
      'items': filled
          ? [
              bucketRow(id: 1, title: 'Voir les aurores boréales'),
              bucketRow(id: 2, title: 'Apprendre à danser le tango'),
            ]
          : [],
    }),
  );
  t.reply(
    'GET /api/couple/dates',
    ok({
      'dates': filled ? [dateRow(id: 1, title: 'Notre anniversaire')] : [],
    }),
  );
  t.reply(
    'GET /api/couple/memories',
    ok({
      'memories': filled
          ? [memoryRow(id: 1, title: 'Notre premier voyage')]
          : [],
    }),
  );
  return t;
}

Future<void> _pumpSpace(
  WidgetTester tester, {
  required Size size,
  ThemeData? theme,
  bool filled = true,
}) async {
  _viewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: CoupleSpaceScreen(
        apiService: CoupleApiService(transport: _transport(filled: filled)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder get _gradients => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final decoration = w.decoration;
  return decoration is BoxDecoration && decoration.gradient != null;
}, skipOffstage: false);

Iterable<String> _allTexts(WidgetTester tester) sync* {
  for (final element in find.byType(Text, skipOffstage: false).evaluate()) {
    final text = element.widget as Text;
    yield text.data ?? text.textSpan?.toPlainText() ?? '';
  }
}

Color? _fill(WidgetTester tester, Key key) {
  final box = find
      .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
      .first;
  final decoration =
      tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
  return decoration.color;
}

int _handles(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderBox>()
    .where(
      (box) =>
          box.hasSize &&
          box.size == const Size(36, 5) &&
          box is RenderDecoratedBox,
    )
    .length;

/// The test engine draws every glyph as a wide square unless the fonts are
/// loaded: a label that fits in Geist would "overflow" for no real reason.
Future<void> _loadFonts() async {
  for (final family in {
    'Geist': ['400', '500', '600', '700'],
    'GeistMono': ['400', '500'],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final weight in family.value) {
      final bytes = File(
        'assets/fonts/${family.key}-$weight.ttf',
      ).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  group('Notre espace : rendu', () {
    for (final phone in _phones.entries) {
      for (final dark in [false, true]) {
        for (final filled in [true, false]) {
          final label =
              '${phone.key} ${dark ? 'sombre' : 'clair'} ${filled ? 'rempli' : 'vide'}';
          testWidgets('aucun débordement : $label', (tester) async {
            await _pumpSpace(
              tester,
              size: phone.value,
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              filled: filled,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Notre espace'), findsOneWidget);
            // Scroll to the very end: nothing may overflow down there either.
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -3000),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    testWidgets('aucun dégradé dans l\'arbre', (tester) async {
      await _pumpSpace(tester, size: _phones['390x844']!);
      expect(_gradients, findsNothing);
    });

    testWidgets('aucun dégradé non plus à vide ni en sombre', (tester) async {
      await _pumpSpace(
        tester,
        size: _phones['360x740']!,
        theme: AppTheme.darkTheme,
        filled: false,
      );
      expect(_gradients, findsNothing);
    });

    testWidgets(
      'les trois tuiles de chiffres ont la même couleur de fond (brume)',
      (tester) async {
        await _pumpSpace(tester, size: _phones['390x844']!);
        final scheme = Theme.of(
          tester.element(find.text('Notre espace')),
        ).colorScheme;
        final fills = [
          for (var i = 0; i < 3; i++) _fill(tester, Key('couple-stat-$i')),
        ];
        expect(fills.toSet(), hasLength(1));
        expect(fills.first, scheme.surfaceContainer);
      },
    );

    testWidgets('aucun émoji dans un texte, titre compris', (tester) async {
      await _pumpSpace(tester, size: _phones['390x844']!);
      final offenders = _allTexts(tester).where(_emoji.hasMatch).toList();
      expect(offenders, isEmpty);
      expect(find.text('Notre espace'), findsOneWidget);
    });

    testWidgets('la liste finit au-dessus de la barre d\'onglets', (
      tester,
    ) async {
      await _pumpSpace(tester, size: _phones['390x844']!);
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pump();
      final last = tester.getRect(find.text('Première activité'));
      expect(last.bottom, lessThanOrEqualTo(844 - 34 - 16 + 0.5));
    });

    testWidgets('« Ajouter un souvenir » ouvre UNE seule poignée', (
      tester,
    ) async {
      await _pumpSpace(tester, size: _phones['390x844']!);
      await tester.tap(find.text('Ajouter\nun souvenir'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter un souvenir'), findsOneWidget);
      expect(_handles(tester), 1);
      expect(_gradients, findsNothing);
    });
  });

  group('autres écrans du lot', () {
    for (final phone in _phones.entries) {
      for (final dark in [false, true]) {
        final label = '${phone.key} ${dark ? 'sombre' : 'clair'}';

        testWidgets('anniversaire et jalons : $label', (tester) async {
          _viewport(tester, phone.value);
          final milestones = [
            CoupleMilestone(days: 30, label: '30 jours', icon: 'seedling'),
            CoupleMilestone(
              days: 100,
              label: '100 jours',
              icon: 'heart',
              daysUntil: 12,
            ),
            CoupleMilestone(
              days: 365,
              label: 'Un an',
              icon: 'star',
              isSpecial: true,
              daysUntil: 280,
            ),
          ];
          final data = CoupleAnniversaryData(
            matchDate: DateTime(2026, 6, 1),
            daysTogether: 114,
            partnerName: 'Noémie',
            currentMilestone: milestones[1],
            nextMilestone: milestones[2],
            isAnniversaryToday: true,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      AnniversaryWidget(anniversaryData: data, onShare: () {}),
                      MilestonesTimeline(
                        milestones: milestones,
                        daysTogether: 114,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(_gradients, findsNothing);
          expect(_allTexts(tester).where(_emoji.hasMatch), isEmpty);
          expect(find.text('114'), findsOneWidget);
        });

        testWidgets('tableau de bord du couple : $label', (tester) async {
          _viewport(tester, phone.value);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: const CoupleDashboardScreen(),
            ),
          );
          await tester.pump();
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -4000),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(_gradients, findsNothing);
          expect(_allTexts(tester).where(_emoji.hasMatch), isEmpty);
        });

        testWidgets('histoires de couples : $label', (tester) async {
          _viewport(tester, phone.value);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: const SuccessStoriesScreen(),
            ),
          );
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(_gradients, findsNothing);
          expect(_allTexts(tester).where(_emoji.hasMatch), isEmpty);
        });
      }
    }

    testWidgets(
      '« Partagez votre histoire » : une seule poignée, pas d\'émoji',
      (tester) async {
        _viewport(tester, _phones['390x844']!);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => SubmitSuccessStoryDialog.show(context),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text('Partagez votre histoire'), findsOneWidget);
        expect(_handles(tester), 1);
        expect(_allTexts(tester).where(_emoji.hasMatch), isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
