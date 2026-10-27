import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/screens/discover_screen.dart';
import 'package:mazl/presentation/features/matching/widgets/discover_card.dart';
import 'package:mazl/presentation/features/matching/widgets/super_like_note_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../mocks/fake_discover_api.dart';
import '../../support/credits_fakes.dart';
import '../../support/duo_harness.dart';
import '../../support/premium_fakes.dart';
import '../duo/duo_geometry.dart';

// What the revenue features add to Discover, in the seven postures of the
// foldable iPhone, light and dark: the marks on the card (« De passage à X »,
// Super Like and its word), the new buttons, and the word sheet with the
// keyboard open.

const _word =
    'Votre playlist de Shabbat m’a donné envie de vous écrire, vraiment.';

List<Profile> _profiles() => [
  Profile(
    id: 1,
    userId: 101,
    displayName: 'Profil1',
    age: 26,
    location: 'Paris',
    distance: 12,
    denomination: 'modern_orthodox',
    kashrut: 'strict',
    isVerified: true,
    bio: 'Pianiste, aime les longues marches.',
    superLikedYou: true,
    superLikeNote: _word,
    travelingCity: 'Tel Aviv',
  ),
  Profile(
    id: 2,
    userId: 102,
    displayName: 'Profil2',
    age: 28,
    location: 'Lyon',
  ),
];

Future<void> _pumpDiscover(
  WidgetTester tester,
  DuoPose pose,
  Brightness brightness,
) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
      darkTheme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.iOS),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) =>
          ReduceMotionScope(child: duoAppBuilder(controller)(context, child)),
      home: DiscoverScreen(
        apiService: FakeDiscoverApi(_profiles()),
        likeAllowanceApi: FakeLikeAllowanceApi.free(remaining: 50),
        swipeUndoApi: FakeSwipeUndoApi(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await settleFold(tester);
}

Finder _inCard(Finder matching) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is DiscoverCard && w.profile.userId == 101,
  ),
  matching: matching,
);

void _expectInside(
  WidgetTester tester,
  Finder finder,
  DuoPose pose,
  String what,
) {
  expect(finder, findsOneWidget, reason: '$what in ${pose.name}');
  final rect = tester.getRect(finder);
  final safe = pose.safeRect.inflate(0.5);
  expect(
    safe.contains(rect.topLeft) && safe.contains(rect.bottomRight),
    isTrue,
    reason: '$what $rect is outside ${pose.safeRect} in ${pose.name}',
  );
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    PremiumGate.debugPremiumOverride = false;
    installTestCredits();
  });
  tearDown(PremiumGate.resetForTest);

  for (final pose in DuoPose.values) {
    for (final brightness in Brightness.values) {
      final where = '${pose.name}, ${brightness.name}';

      duoTestWidgets('the card with both marks and its new buttons, $where', (
        tester,
      ) async {
        await _pumpDiscover(tester, pose, brightness);

        expect(tester.takeException(), isNull);
        _expectInside(
          tester,
          find.byKey(const ValueKey('discover-traveling')),
          pose,
          'the traveling mark',
        );
        _expectInside(
          tester,
          find.byKey(const ValueKey('discover-super-liked')),
          pose,
          'the Super Like mark',
        );
        expect(find.textContaining('Votre playlist'), findsOneWidget);
        expect(tappableProblems(tester, pose), isEmpty);
        expect(foldCrossingProblems(tester, pose), isEmpty);
      });

      duoTestWidgets('the undo and passport buttons are touchable all over, '
          '$where', (tester) async {
        await _pumpDiscover(tester, pose, brightness);

        expectTouchTarget(
          tester,
          _inCard(
            find.ancestor(
              of: find.byIcon(LucideIcons.undo2),
              matching: find.byType(InkWell),
            ),
          ),
          'undo in $where',
        );
        expectTouchTarget(
          tester,
          find.ancestor(
            of: find.byIcon(LucideIcons.globe),
            matching: find.byType(InkWell),
          ),
          'passport in $where',
        );
      });
    }
  }

  group('the word sheet with the keyboard open', () {
    Future<void> openSheet(
      WidgetTester tester,
      DuoPose pose,
      Brightness brightness,
    ) async {
      setDuoPose(tester, pose);
      final controller = DuoPoseController(pose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          darkTheme: AppTheme.darkTheme.copyWith(platform: TargetPlatform.iOS),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: duoAppBuilder(controller),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showSuperLikeNoteSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settleFold(tester);
    }

    void openKeyboard(WidgetTester tester, DuoPose pose) {
      // The keyboard iOS raises at the bottom of the window: about 300 pt
      // upright, about 200 pt sideways.
      final height = pose.size.width > pose.size.height ? 200.0 : 300.0;
      tester.view.viewInsets = FakeViewPadding(bottom: height * 3);
      // iOS takes the home indicator out of the padding while the keyboard
      // covers it (`padding` is the part of `viewPadding` left uncovered).
      tester.view.padding = FakeViewPadding(
        left: pose.padding.left * 3,
        top: pose.padding.top * 3,
        right: pose.padding.right * 3,
      );
      addTearDown(tester.view.resetViewInsets);
    }

    for (final pose in DuoPose.values) {
      for (final brightness in Brightness.values) {
        duoTestWidgets(
          'fits, with and without the keyboard, ${pose.name}, ${brightness.name}',
          (tester) async {
            await openSheet(tester, pose, brightness);
            for (final keyboard in [false, true]) {
              if (keyboard) {
                openKeyboard(tester, pose);
                await tester.tap(
                  find.byKey(const ValueKey('super-like-note-field')),
                );
                for (var i = 0; i < 10; i++) {
                  await tester.pump(const Duration(milliseconds: 100));
                }
                await settleFold(tester);
              }
              final reason = '${pose.name}, keyboard $keyboard';
              expect(tester.takeException(), isNull, reason: reason);
              for (final key in [
                'super-like-note-field',
                'super-like-note-send',
                'super-like-note-without',
                'super-like-note-cancel',
              ]) {
                expect(
                  find.byKey(ValueKey(key)).hitTestable(),
                  findsOneWidget,
                  reason: '$key is not reachable, $reason',
                );
              }
              expect(tappableProblems(tester, pose), isEmpty, reason: reason);
              expect(
                foldCrossingProblems(tester, pose),
                isEmpty,
                reason: reason,
              );
              expectTouchTarget(
                tester,
                find.byKey(const ValueKey('super-like-note-without')),
                'send without a word, $reason',
              );
              expectTouchTarget(
                tester,
                find.byKey(const ValueKey('super-like-note-cancel')),
                'cancel, $reason',
              );
            }
          },
        );
      }
    }

    duoTestWidgets('laptop pose: with the keyboard up, the field and every '
        'button stay above the fold', (tester) async {
      const pose = DuoPose.halfOpenLaptop;
      await openSheet(tester, pose, Brightness.light);
      openKeyboard(tester, pose);
      await tester.tap(find.byKey(const ValueKey('super-like-note-field')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settleFold(tester);

      for (final key in [
        'super-like-note-field',
        'super-like-note-send',
        'super-like-note-without',
        'super-like-note-cancel',
      ]) {
        expect(
          tester.getRect(find.byKey(ValueKey(key))).bottom,
          lessThanOrEqualTo(pose.fold!.top),
          reason: '$key is below the fold: the keyboard would sit on it',
        );
      }
    });

    duoTestWidgets('book pose: the sheet is on one side of the fold', (
      tester,
    ) async {
      const pose = DuoPose.halfOpenBook;
      await openSheet(tester, pose, Brightness.light);
      final fold = pose.fold!;
      for (final key in [
        'super-like-note-field',
        'super-like-note-send',
        'super-like-note-without',
        'super-like-note-cancel',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(
          rect.right <= fold.left || rect.left >= fold.right,
          isTrue,
          reason: '$key $rect crosses the fold $fold',
        );
      }
    });
  });
}
