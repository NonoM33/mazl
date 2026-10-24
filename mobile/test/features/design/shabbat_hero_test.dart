import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/settings/widgets/shabbat_hero.dart';
import '../../helpers/l10n_helpers.dart';

Widget _host({VoidCallback? onBack}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShabbatHero(
            candleLighting: '17:42',
            havdala: '18:51',
            city: 'Basé sur Paris, France',
            onBack: onBack,
          ),
        ),
      ),
    );

void main() {
  testWidgets('affiche le titre, les deux étiquettes et les deux heures', (tester) async {
    await tester.pumpWidget(_host(onBack: () {}));

    expect(find.text('Shabbat\nshalom.'), findsOneWidget);
    expect(find.text('ALLUMAGE'), findsOneWidget);
    expect(find.text('HAVDALA'), findsOneWidget);
    expect(find.text('17:42'), findsOneWidget);
    expect(find.text('18:51'), findsOneWidget);
    expect(find.text('Basé sur Paris, France'), findsOneWidget);
    expect(find.textContaining('Mazl se repose avec vous'), findsOneWidget);
  });

  testWidgets('le fond est shabbatBackground', (tester) async {
    await tester.pumpWidget(_host(onBack: () {}));

    final background = tester
        .widgetList<ColoredBox>(find.descendant(
          of: find.byType(ShabbatHero),
          matching: find.byType(ColoredBox),
        ))
        .first;
    expect(background.color, AppColors.shabbatBackground);
  });

  testWidgets('le bouton retour est annoncé « Retour » et réagit', (tester) async {
    var pops = 0;
    await tester.pumpWidget(_host(onBack: () => pops++));

    expect(find.bySemanticsLabel('Retour'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Retour'));
    expect(pops, 1);
    expect(tester.getSize(find.bySemanticsLabel('Retour')).shortestSide, greaterThanOrEqualTo(44));
  });

  testWidgets('sans onBack, aucun bouton retour', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.bySemanticsLabel('Retour'), findsNothing);
  });

  testWidgets("ni dégradé ni ombre dans l'arbre", (tester) async {
    await tester.pumpWidget(_host(onBack: () {}));

    final decorations = tester
        .widgetList<DecoratedBox>(find.descendant(
          of: find.byType(ShabbatHero),
          matching: find.byType(DecoratedBox),
        ))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>();
    for (final d in decorations) {
      expect(d.gradient, isNull);
      expect(d.boxShadow, anyOf(isNull, isEmpty));
    }
    expect(
      find.descendant(of: find.byType(ShabbatHero), matching: find.byType(PhysicalModel)),
      findsNothing,
    );
  });
}
