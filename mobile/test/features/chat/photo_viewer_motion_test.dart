import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/presentation/features/chat/widgets/photo_grid.dart';
import 'package:mazl/presentation/features/chat/widgets/photo_viewer.dart';

import 'chat_test_support.dart';
import '../../helpers/l10n_helpers.dart';

// docs/design/CHAT.md §7 and balayages-proposition.html (Geste 3): the photo
// follows the finger in both axes, shrinks, the background fades, a haptic
// marks the dismiss distance, the release springs back or flies home.

const _photo = Key('viewer-photo');
const _thumb = Key('thumb');

List<String> _haptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// [iPhoneScope]: the app's root, where the iPhone setting becomes
/// `disableAnimations`, instead of setting it by hand.
Future<void> _open(
  WidgetTester tester, {
  bool reduced = false,
  bool iPhoneScope = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final photos = [for (var i = 0; i < 3; i++) PhotoSource(url: tinyPngUri)];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      builder: (context, child) => iPhoneScope
          ? ReduceMotionScope(child: child!)
          : MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => openPhotoViewer(
                context,
                photos: photos,
                initialIndex: 0,
                heroPrefix: 'p',
              ),
              child: Hero(
                tag: 'p-0',
                child: Container(
                  key: _thumb,
                  width: 60,
                  height: 60,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_thumb));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Matrix4 _matrix(WidgetTester tester) =>
    tester.widget<Transform>(find.byKey(_photo)).transform;

Offset _offset(WidgetTester tester) {
  final t = _matrix(tester).getTranslation();
  return Offset(t.x, t.y);
}

double _scale(WidgetTester tester) => _matrix(tester).entry(0, 0);

double _background(WidgetTester tester) => tester
    .widget<Scaffold>(
      find.descendant(
        of: find.byType(PhotoViewer),
        matching: find.byType(Scaffold),
      ),
    )
    .backgroundColor!
    .a;

Future<TestGesture> _hold(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(200, 400));
  // Crosses the touch slop: from here on the vertical drag is accepted.
  await gesture.moveBy(
    const Offset(0, 24),
    timeStamp: const Duration(milliseconds: 16),
  );
  await tester.pump();
  return gesture;
}

void main() {
  group('photo viewer drag to close', () {
    testWidgets('release at 80 px: animates back, not an instant jump', (
      tester,
    ) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 56),
        timeStamp: const Duration(milliseconds: 600),
      );
      await tester.pump();
      expect(_offset(tester).dy, closeTo(80, 0.5));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      final dy = _offset(tester).dy;
      expect(dy, inExclusiveRange(0, 80), reason: 'mid-spring, not at 0');
      await tester.pumpAndSettle();
      expect(_offset(tester).distance, 0);
      expect(_scale(tester), 1.0);
      expect(find.byType(PhotoViewer), findsOneWidget);
    });

    testWidgets('shrinks to 0.85 and fades the background with the distance', (
      tester,
    ) async {
      await _open(tester);
      expect(_scale(tester), 1.0);
      expect(_background(tester), 1.0);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 126),
        timeStamp: const Duration(milliseconds: 600),
      );
      await tester.pump();
      expect(_offset(tester).dy, closeTo(150, 0.5));
      expect(
        _scale(tester),
        closeTo(1 - (1 - MazlMotion.viewerMinScale) * 0.5, 0.005),
      );
      expect(
        _background(tester),
        closeTo(1 - MazlMotion.viewerMaxFade * 0.5, 0.01),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('selectionClick once at 120, again only after re-crossing', (
      tester,
    ) async {
      final haptics = _haptics(tester);
      await _open(tester);
      final gesture = await _hold(tester); // 24
      await gesture.moveBy(
        const Offset(0, 80),
        timeStamp: const Duration(milliseconds: 400),
      ); // 104
      await tester.pump();
      expect(haptics, isEmpty);
      await gesture.moveBy(
        const Offset(0, 30),
        timeStamp: const Duration(milliseconds: 500),
      ); // 134
      await tester.pump();
      await gesture.moveBy(
        const Offset(0, 20),
        timeStamp: const Duration(milliseconds: 600),
      ); // 154
      await tester.pump();
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await gesture.moveBy(
        const Offset(0, -60),
        timeStamp: const Duration(milliseconds: 700),
      ); // 94
      await tester.pump();
      await gesture.moveBy(
        const Offset(0, 40),
        timeStamp: const Duration(milliseconds: 800),
      ); // 134
      await tester.pump();
      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('release at 130 px closes the viewer', (tester) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 106),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(MazlMotion.viewerReturnToThumbnail * 1.5);
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('a fast short fling closes it', (tester) async {
      await _open(tester);
      final gesture = await tester.startGesture(const Offset(200, 400));
      var ms = 0;
      for (var i = 0; i < 5; i++) {
        ms += 10;
        await gesture.moveBy(
          Offset(0, 10),
          timeStamp: Duration(milliseconds: ms),
        );
      }
      await tester.pump();
      expect(_offset(tester).dy, lessThan(MazlMotion.viewerDismissDistance));
      await gesture.up();
      await tester.pump();
      await tester.pump(MazlMotion.viewerReturnToThumbnail * 1.5);
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('past 120 px, a quick flick back up keeps it open', (
      tester,
    ) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 136),
        timeStamp: const Duration(milliseconds: 600),
      );
      await tester.pump();
      // 30 px up in 20 ms: 1500 px/s, well past the dismiss velocity.
      var ms = 600;
      for (var i = 0; i < 5; i++) {
        ms += 4;
        await gesture.moveBy(
          const Offset(0, -6),
          timeStamp: Duration(milliseconds: ms),
        );
      }
      await tester.pump();
      expect(
        _offset(tester).dy,
        greaterThanOrEqualTo(MazlMotion.viewerDismissDistance),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsOneWidget);
      expect(_offset(tester), Offset.zero);
    });

    testWidgets('the iPhone Reduce Motion setting reaches the viewer: no '
        'scale while dragged', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _open(tester, iPhoneScope: true);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 100),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      expect(_scale(tester), 1.0);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a slow short drag does not close it', (tester) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 40),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsOneWidget);
    });

    testWidgets('the photo follows the finger sideways too', (tester) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(50, 20),
        timeStamp: const Duration(milliseconds: 300),
      );
      await tester.pump();
      await gesture.moveBy(
        const Offset(30, 0),
        timeStamp: const Duration(milliseconds: 600),
      );
      await tester.pump();
      final o = _offset(tester);
      expect(o.dx, closeTo(80, 1));
      expect(o.dy, closeTo(44, 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(_offset(tester).distance, 0);
    });

    testWidgets('closing: the Hero flies from where the photo was dragged', (
      tester,
    ) async {
      await _open(tester);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(-60, 126),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      final dragged = const Offset(200, 400) + _offset(tester);
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      // The thumbnail is a placeholder during the flight: the only widget with
      // its key is the shuttle.
      final flying = tester.getCenter(find.byKey(_thumb));
      expect(flying.dx, closeTo(dragged.dx, 60), reason: 'not from the centre');
      expect(flying.dy, closeTo(dragged.dy, 90));
      expect(flying.dy, greaterThan(400 + 40), reason: 'still low on screen');
      expect(flying.dx, lessThan(200 - 20), reason: 'still on the left');
      await tester.pump(MazlMotion.viewerReturnToThumbnail * 1.5);
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('reduce motion: no scale, closing is a plain fade', (
      tester,
    ) async {
      await _open(tester, reduced: true);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 126),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      expect(_scale(tester), 1.0);
      await gesture.up();
      await tester.pump();
      await tester.pump(
        MazlMotion.reducedFade + const Duration(milliseconds: 16),
      );
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('reduce motion: a short drag is back in 120 ms', (
      tester,
    ) async {
      await _open(tester, reduced: true);
      final gesture = await _hold(tester);
      await gesture.moveBy(
        const Offset(0, 36),
        timeStamp: const Duration(milliseconds: 900),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(
        MazlMotion.reducedReturn + const Duration(milliseconds: 16),
      );
      expect(_offset(tester).distance, 0);
      expect(find.byType(PhotoViewer), findsOneWidget);
    });
  });
}
