import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/duo_tutorial/duo_tutorial_step.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/duo_tutorial/duo_tutorial_providers.dart';
import 'package:mazl/presentation/features/duo_tutorial/screens/duo_tutorial_screen.dart';

import '../../core/duo_tutorial/fake_duo_scene_renderer.dart';
import '../../helpers/duo_poses.dart';

/// L'écran du tutoriel dans chacune des 7 poses mesurées du Duo, à chaque
/// étape, dans les cinq langues, avec un faux rendu à la place de la 3D.
void main() {
  late FakeDuoSceneRenderer renderer;
  late DuoPoseController pose;
  var finished = 0;

  Future<void> pumpTutorial(
    WidgetTester tester,
    DuoPose start, {
    Locale locale = const Locale('fr'),
    bool accessibleNavigation = false,
  }) async {
    renderer = FakeDuoSceneRenderer();
    finished = 0;
    setDuoPose(tester, start);
    pose = DuoPoseController(start);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          duoSceneRendererFactoryProvider.overrideWithValue(() => renderer),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(accessibleNavigation: accessibleNavigation),
            child: duoAppBuilder(pose)(context, child),
          ),
          home: DuoTutorialScreen(onFinished: () => finished++),
        ),
      ),
    );
    await settleFold(tester);
    // Le temps que l'origine de la page soit mesurée (deux images).
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder text(String Function(AppLocalizations) pick, {Locale? locale}) {
    final l10n = lookupAppLocalizations(locale ?? const Locale('fr'));
    return find.text(pick(l10n));
  }

  group('tient dans les 7 poses, à chaque étape', () {
    for (final start in DuoPose.values) {
      testWidgets(start.name, (tester) async {
        await pumpTutorial(tester, start);
        for (final step in DuoTutorialStep.values) {
          expectFitsDuoPose(tester, start, 'tutoriel, étape ${step.name}');
          expect(find.byKey(const ValueKey('fake-duo-scene')), findsOneWidget);
          if (!step.isLast) {
            await tester.tap(text((l) => l.duoTutorialNext));
            await tester.pump(const Duration(milliseconds: 500));
          }
        }
      });
    }
  });

  group('la scène et le texte restent de part et d\'autre du pli', () {
    testWidgets('livre', (tester) async {
      await pumpTutorial(tester, DuoPose.halfOpenBook);
      final scene = tester.getRect(
        find.byKey(const ValueKey('fake-duo-scene')),
      );
      final button = tester.getRect(
        find.widgetWithText(FilledButton, 'Suivant'),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        scene.overlaps(fold),
        isFalse,
        reason: 'la scène ne couvre pas le pli',
      );
      expect(scene.right, lessThanOrEqualTo(fold.left));
      expect(button.left, greaterThanOrEqualTo(fold.right));
    });

    testWidgets('portable', (tester) async {
      await pumpTutorial(tester, DuoPose.halfOpenLaptop);
      final scene = tester.getRect(
        find.byKey(const ValueKey('fake-duo-scene')),
      );
      final button = tester.getRect(
        find.widgetWithText(FilledButton, 'Suivant'),
      );
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(scene.bottom, lessThanOrEqualTo(fold.top));
      expect(button.top, greaterThanOrEqualTo(fold.bottom));
    });

    testWidgets('hébreu, livre : le texte à gauche, la scène à droite', (
      tester,
    ) async {
      await pumpTutorial(
        tester,
        DuoPose.halfOpenBook,
        locale: const Locale('he'),
      );
      final scene = tester.getRect(
        find.byKey(const ValueKey('fake-duo-scene')),
      );
      final fold = DuoPose.halfOpenBook.fold!;
      expect(scene.left, greaterThanOrEqualTo(fold.right));
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'tutoriel hébreu');
    });
  });

  group('« Passer » et « Suivant » sont toujours là', () {
    testWidgets('à chaque étape sauf la dernière', (tester) async {
      await pumpTutorial(tester, DuoPose.closed);
      for (final step in DuoTutorialStep.values) {
        expect(
          text((l) => l.duoTutorialNext).evaluate().isNotEmpty || step.isLast,
          isTrue,
        );
        if (step.isLast) {
          expect(text((l) => l.duoTutorialSkip), findsNothing);
          expect(text((l) => l.duoTutorialStart), findsOneWidget);
        } else {
          expect(
            text((l) => l.duoTutorialSkip),
            findsOneWidget,
            reason: step.name,
          );
          await tester.tap(text((l) => l.duoTutorialNext));
          await tester.pump(const Duration(milliseconds: 500));
        }
      }
    });

    testWidgets('« Passer » termine tout de suite, une seule fois', (
      tester,
    ) async {
      await pumpTutorial(tester, DuoPose.closed);
      await tester.tap(text((l) => l.duoTutorialSkip));
      await tester.pump();
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('« Commencer » termine à la dernière étape', (tester) async {
      await pumpTutorial(tester, DuoPose.closed);
      for (var i = 0; i < DuoTutorialStep.values.length - 1; i++) {
        await tester.tap(text((l) => l.duoTutorialNext));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.tap(text((l) => l.duoTutorialStart));
      await tester.pump();
      await tester.pump();
      expect(finished, 1);
    });

    testWidgets('« Suivant » change le titre', (tester) async {
      await pumpTutorial(tester, DuoPose.closed);
      expect(text((l) => l.duoTutorialWelcomeTitle), findsOneWidget);
      await tester.tap(text((l) => l.duoTutorialNext));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(text((l) => l.duoTutorialOpenTitle), findsOneWidget);
      expect(text((l) => l.duoTutorialWelcomeTitle), findsNothing);
    });
  });

  group('la vraie pose fait avancer le parcours', () {
    testWidgets(
      'ouvrir le téléphone valide « Ouvrez-le », puis l\'étape suivante arrive',
      (tester) async {
        await pumpTutorial(tester, DuoPose.closed);
        await tester.tap(text((l) => l.duoTutorialNext));
        await tester.pump(const Duration(milliseconds: 600));
        expect(text((l) => l.duoTutorialDone), findsNothing);

        await pose.moveTo(tester, DuoPose.openPortrait);
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          text((l) => l.duoTutorialDone),
          findsNothing,
          reason: 'pas encore tenu',
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(text((l) => l.duoTutorialDone), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1700));
        await tester.pump(const Duration(milliseconds: 600));
        expect(text((l) => l.duoTutorialBookTitle), findsOneWidget);
      },
    );

    testWidgets('traverser une pose sans la tenir ne valide rien', (
      tester,
    ) async {
      await pumpTutorial(tester, DuoPose.closed);
      await tester.tap(text((l) => l.duoTutorialNext));
      await tester.pump(const Duration(milliseconds: 600));
      await pose.moveTo(tester, DuoPose.openPortrait);
      await tester.pump(const Duration(milliseconds: 200));
      await pose.moveTo(tester, DuoPose.halfOpenBook);
      await tester.pump(const Duration(seconds: 3));
      expect(text((l) => l.duoTutorialDone), findsNothing);
      expect(text((l) => l.duoTutorialOpenTitle), findsOneWidget);
    });

    testWidgets('avec VoiceOver, l\'étape ne change jamais toute seule', (
      tester,
    ) async {
      await pumpTutorial(tester, DuoPose.closed, accessibleNavigation: true);
      await tester.tap(text((l) => l.duoTutorialNext));
      await tester.pump(const Duration(milliseconds: 600));
      await pose.moveTo(tester, DuoPose.openPortrait);
      await tester.pump(const Duration(seconds: 10));
      expect(text((l) => l.duoTutorialDone), findsOneWidget);
      expect(text((l) => l.duoTutorialOpenTitle), findsOneWidget);
    });
  });

  group('la scène reçoit la pose réelle', () {
    testWidgets('dès l\'ouverture, puis à chaque pliage', (tester) async {
      await pumpTutorial(tester, DuoPose.closed);
      expect(renderer.poses, isNotEmpty);
      expect(renderer.poses.first.step, DuoTutorialStep.welcome);
      final before = renderer.poses.length;
      await pose.moveTo(tester, DuoPose.halfOpenBook);
      expect(renderer.poses.length, greaterThan(before));
      expect(renderer.poses.last.angle, 1.9);
      expect(renderer.poses.last.axis.name, 'vertical');
    });

    testWidgets('le renderer est libéré avec l\'écran', (tester) async {
      await pumpTutorial(tester, DuoPose.closed);
      await tester.pumpWidget(const SizedBox());
      expect(renderer.disposed, isTrue);
    });
  });

  group('accessibilité', () {
    testWidgets(
      'le titre est un titre, l\'avancement se lit « Étape 1 sur 6 »',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpTutorial(tester, DuoPose.closed);
        expect(
          tester.getSemantics(text((l) => l.duoTutorialWelcomeTitle)),
          matchesSemantics(label: 'MAZL, pensé pour le Duo', isHeader: true),
        );
        expect(find.bySemanticsLabel('Étape 1 sur 6'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('les deux boutons ont une cible d\'au moins 44 points', (
      tester,
    ) async {
      await pumpTutorial(tester, DuoPose.closed);
      for (final finder in [
        find.widgetWithText(FilledButton, 'Suivant'),
        find.widgetWithText(TextButton, 'Passer'),
      ]) {
        final size = tester.getSize(finder);
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      }
    });
  });

  group('les textes existent dans les cinq langues', () {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets(locale.languageCode, (tester) async {
        await pumpTutorial(tester, DuoPose.openPortrait, locale: locale);
        final l10n = lookupAppLocalizations(locale);
        final titles = <String>{};
        for (final step in DuoTutorialStep.values) {
          final title = switch (step) {
            DuoTutorialStep.welcome => l10n.duoTutorialWelcomeTitle,
            DuoTutorialStep.open => l10n.duoTutorialOpenTitle,
            DuoTutorialStep.book => l10n.duoTutorialBookTitle,
            DuoTutorialStep.table => l10n.duoTutorialTableTitle,
            DuoTutorialStep.tent => l10n.duoTutorialTentTitle,
            DuoTutorialStep.ready => l10n.duoTutorialReadyTitle,
          };
          expect(title.trim(), isNotEmpty);
          titles.add(title);
          expect(
            find.text(title),
            findsOneWidget,
            reason: '${locale.languageCode} ${step.name}',
          );
          expectFitsDuoPose(
            tester,
            DuoPose.openPortrait,
            '${locale.languageCode} ${step.name}',
          );
          if (!step.isLast) {
            await tester.tap(find.text(l10n.duoTutorialNext));
            await tester.pump(const Duration(milliseconds: 500));
          }
        }
        expect(titles, hasLength(6), reason: 'six titres différents');
        expect(l10n.duoTutorialProgress(2, 6), contains('2'));
        expect(l10n.duoTutorialProgress(2, 6), contains('6'));
      });
    }
  });
}
