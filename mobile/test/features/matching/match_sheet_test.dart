import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/profile.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/features/matching/widgets/match_sheet.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/l10n_helpers.dart';

// Expected numbers come from the design canon (80 px photos, touching = centres
// 80 px apart, 420 ms meet, one 600 ms ring), not from reading the widget.

const _screen = Size(390, 844);
const _avatar = 80.0;
const _handle = Size(36, 5);
const _meKey = Key('match-avatar-me');
const _themKey = Key('match-avatar-them');
const _ringKey = Key('match-ring');

final _matched = Profile(id: 7, userId: 42, displayName: 'Myriam', photos: const []);

class _Harness {
  MatchSheetChoice? choice;
  bool returned = false;
  final haptics = <String>[];
}

/// Pumps the app shell (nested tab navigator + floating bar) and opens the
/// sheet from inside a tab, like the Discover screen does.
Future<_Harness> _open(
  WidgetTester tester, {
  bool reduceMotion = false,
  Profile? matched,
  String? myPhotoUrl,
  String? myName = 'Renaud',
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: 34);
  addTearDown(tester.view.reset);

  final harness = _Harness();
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
    call,
  ) async {
    if (call.method == 'HapticFeedback.vibrate') harness.haptics.add(call.arguments as String);
    return null;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduceMotion,
        size: _screen,
        padding: const EdgeInsets.only(bottom: 34),
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          extendBody: true,
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      harness.choice = await showMatchSheet(
                        context,
                        matched: matched ?? _matched,
                        myPhotoUrl: myPhotoUrl,
                        myName: myName,
                      );
                      harness.returned = true;
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: MazlNavBar(
            items: const [
              MazlNavItem(icon: LucideIcons.layers, label: 'Découvrir'),
              MazlNavItem(icon: LucideIcons.user, label: 'Profil'),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  return harness;
}

double _distance(WidgetTester tester) =>
    (tester.getCenter(find.byKey(_themKey)) - tester.getCenter(find.byKey(_meKey))).dx;

int _handles(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderBox>()
    .where((b) => b.hasSize && b.size == _handle && b is RenderDecoratedBox)
    .length;

int _mediumImpacts(_Harness h) =>
    h.haptics.where((m) => m == 'HapticFeedbackType.mediumImpact').length;

void main() {
  group('frame', () {
    testWidgets('single-handle sheet above the tab bar, with title and line', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      expect(_handles(tester), 1);
      expect(find.text('C\'est un match'), findsOneWidget);
      expect(find.text('Myriam et vous vous êtes plu.'), findsOneWidget);
      expect(find.byKey(_meKey), findsOneWidget);
      expect(find.byKey(_themKey), findsOneWidget);
      final bar = tester.renderObject(find.byKey(const Key('mazl-nav-bar')));
      final result = HitTestResult();
      tester.binding.hitTestInView(
        result,
        tester.getCenter(find.text('Envoyer un message')),
        tester.view.viewId,
      );
      expect(
        result.path.any((e) => e.target == bar),
        isFalse,
        reason: 'the sheet covers the tab bar',
      );
    });

    testWidgets('each photo has a 3 px paper ring; the main button is the ink one', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byKey(_meKey));
      final paper = Theme.of(ctx).colorScheme.surface;
      for (final key in [_meKey, _themKey]) {
        final ring = tester.widget<Container>(
          find.descendant(of: find.byKey(key), matching: find.byType(Container)).first,
        );
        final box = ring.decoration! as BoxDecoration;
        expect(box.shape, BoxShape.circle);
        expect(box.color, paper);
        expect(ring.padding, const EdgeInsets.all(3));
        expect(tester.getSize(find.byKey(key)), const Size(_avatar, _avatar));
      }
      expect(find.widgetWithText(FilledButton, 'Envoyer un message'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Envoyer un message'), findsOneWidget);
    });

    testWidgets('both buttons are full width and aligned', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      final primary = tester.getRect(find.widgetWithText(ElevatedButton, 'Envoyer un message'));
      final secondary = tester.getRect(find.widgetWithText(TextButton, 'Continuer à découvrir'));
      expect(primary.left, secondary.left);
      expect(primary.right, secondary.right);
      expect(primary.width, closeTo(_screen.width - 48, 0.5));
    });

    testWidgets('no gradient, no shadow in the content', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsNothing);
      for (final box in tester.widgetList<DecoratedBox>(
        find.descendant(of: find.byType(MatchSheetContent), matching: find.byType(DecoratedBox)),
      )) {
        final d = box.decoration;
        if (d is BoxDecoration) {
          expect(d.gradient, isNull);
          expect(d.boxShadow, isNull);
        }
      }
    });
  });

  group('motion', () {
    testWidgets('photos start apart and end touching (centres one diameter apart)', (tester) async {
      await _open(tester);
      await tester.pump(); // route pushed
      await tester.pump(const Duration(milliseconds: 400)); // sheet slid in
      final start = _distance(tester);
      expect(
        start,
        greaterThan(_avatar + 2 * MazlMotion.matchApartOffset * 0.5),
        reason: 'apart at the start',
      );
      await tester.pump(MazlMotion.matchMeet);
      await tester.pump(MazlMotion.matchMeet);
      expect(_distance(tester), closeTo(_avatar, 1));
    });

    testWidgets('the ring pulses once after they touch, then is gone', (tester) async {
      await _open(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(_ringKey), findsNothing, reason: 'not before they touch');
      // Walk to the touch frame by frame until the ring shows up.
      var frames = 0;
      while (find.byKey(_ringKey).evaluate().isEmpty && frames++ < 20) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(_ringKey), findsOneWidget);
      expect(
        frames * 100,
        greaterThanOrEqualTo(MazlMotion.matchMeet.inMilliseconds - 100),
        reason: 'the ring waits for the photos to touch',
      );
      await tester.pump(const Duration(milliseconds: 100)); // first tick of the pulse
      await tester.pump(MazlMotion.matchPulse ~/ 2);
      final mid = tester.widget<Opacity>(find.byKey(_ringKey));
      expect(mid.opacity, inInclusiveRange(0.05, 0.95));
      await tester.pump(MazlMotion.matchPulse);
      await tester.pumpAndSettle();
      expect(find.byKey(_ringKey), findsNothing);
    });

    testWidgets('exactly one medium impact, when the photos touch', (tester) async {
      final h = await _open(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_mediumImpacts(h), 0, reason: 'nothing before they touch');
      await tester.pump(MazlMotion.matchMeet);
      await tester.pumpAndSettle();
      expect(_mediumImpacts(h), 1);
    });

    testWidgets('reduce motion: together on the first frame, no ring, haptic still once', (
      tester,
    ) async {
      final h = await _open(tester, reduceMotion: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // sheet slide only
      expect(_distance(tester), closeTo(_avatar, 1));
      expect(find.byKey(_ringKey), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(_ringKey), findsNothing);
      expect(_mediumImpacts(h), 1);
    });
  });

  group('choice', () {
    testWidgets('« Envoyer un message » returns message', (tester) async {
      final h = await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Envoyer un message'));
      await tester.pumpAndSettle();
      expect(h.choice, MatchSheetChoice.message);
      expect(find.byType(MatchSheetContent), findsNothing);
    });

    testWidgets('« Continuer à découvrir » returns keepDiscovering', (tester) async {
      final h = await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();
      expect(h.choice, MatchSheetChoice.keepDiscovering);
    });

    testWidgets('dismissed by tapping outside returns null', (tester) async {
      final h = await _open(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(h.returned, isTrue);
      expect(h.choice, isNull);
    });
  });

  group('avatars', () {
    testWidgets('without my photo or theirs: initials', (tester) async {
      await _open(tester, myName: 'Renaud');
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(_meKey), matching: find.text('R')), findsOneWidget);
      expect(find.descendant(of: find.byKey(_themKey), matching: find.text('M')), findsOneWidget);
    });

    testWidgets('no name at all: a neutral « ? », no crash', (tester) async {
      await _open(tester, myName: null, matched: Profile(id: 1, userId: 2));
      await tester.pumpAndSettle();
      expect(find.text('?'), findsNWidgets(2));
      expect(find.text('Vous vous êtes plu.'), findsOneWidget);
    });
  });

  group('the first match is a moment to offer mazl+', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PurchaseMoments.resetForTest();
      PremiumGate.resetForTest();
    });

    tearDown(() {
      PurchaseMoments.resetForTest();
      PremiumGate.resetForTest();
    });

    testWidgets('back to Discover after the first match: the offer, with a '
        '« Plus tard »', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Votre premier match.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Plus tard'), findsOneWidget);
    });

    testWidgets('the chat is the way on: no offer on the way', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Envoyer un message'));
      await tester.pumpAndSettle();

      expect(find.text('Votre premier match.'), findsNothing);
    });

    testWidgets('a second match offers nothing', (tester) async {
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Plus tard'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Votre premier match.'), findsNothing);
    });

    testWidgets('a subscriber is offered nothing', (tester) async {
      PremiumGate.debugPremiumOverride = true;
      await _open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer à découvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Votre premier match.'), findsNothing);
    });
  });
}
