import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/motion/mazl_motion.dart';
import 'package:mazl/core/motion/reduce_motion_scope.dart';
import 'package:mazl/core/theme/app_colors.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/presentation/widgets/loading_thread.dart';
import 'package:mazl/presentation/widgets/skeletons.dart';

// docs/design/MOUVEMENT.md: the skeletons are flat neutral blocks, and one
// accent thread runs over them in reading direction. Written from that
// description, not from the painter: positions are read from the render object
// for direction and bounds, and colours from real rendered pixels.

const _width = 400.0;
const _height = 100.0;
const _blockWidth = 150.0;
const _blockHeight = 60.0;

/// A skeleton made of a single block in the top-left corner; the rest of the
/// box is empty, so the thread must not show there.
Widget _skeleton() => const LoadingThread(
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: SkeletonBox(width: _blockWidth, height: _blockHeight),
  ),
);

Widget _app({
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  GlobalKey? boundary,
}) => MaterialApp(
  theme: theme ?? AppTheme.lightTheme,
  builder: (context, child) => ReduceMotionScope(child: child!),
  home: Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: boundary,
        child: const SizedBox(
          width: _width,
          height: _height,
          child: ColoredBox(color: Colors.transparent, child: _Skeleton()),
        ),
      ),
    ),
  ),
);

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => _skeleton();
}

RenderLoadingThread _thread(WidgetTester tester) =>
    tester.renderObject<RenderLoadingThread>(find.byType(LoadingThread).first);

Future<void> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(_width, _height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<ui.Image> _snapshot(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() => boundary.toImage()))!;
}

Future<Color> _pixel(WidgetTester tester, ui.Image image, int x, int y) async {
  final data = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final i = (y * image.width + x) * 4;
  return Color.fromARGB(
    data.getUint8(i + 3),
    data.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

bool _close(Color a, Color b, {int tolerance = 2}) =>
    ((a.r - b.r) * 255).abs() <= tolerance &&
    ((a.g - b.g) * 255).abs() <= tolerance &&
    ((a.b - b.b) * 255).abs() <= tolerance;

void main() {
  group('movement', () {
    for (final direction in TextDirection.values) {
      testWidgets('the thread advances in reading direction ($direction)', (
        tester,
      ) async {
        await _setUp(tester);
        await tester.pumpWidget(_app(direction: direction));
        final render = _thread(tester);

        await tester.pump(const Duration(milliseconds: 300));
        final first = render.threadRect!.center.dx;
        await tester.pump(const Duration(milliseconds: 300));
        final second = render.threadRect!.center.dx;

        expect(second, isNot(first));
        if (direction == TextDirection.ltr) {
          expect(second, greaterThan(first), reason: 'left to right');
        } else {
          expect(second, lessThan(first), reason: 'right to left (Hebrew)');
        }
      });
    }

    testWidgets('the thread stays inside the skeleton over a whole loop', (
      tester,
    ) async {
      await _setUp(tester);
      await tester.pumpWidget(_app());
      final render = _thread(tester);

      final bounds = Offset.zero & render.size;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final rect = render.threadRect!;
        expect(rect.left, greaterThanOrEqualTo(bounds.left));
        expect(rect.right, lessThanOrEqualTo(bounds.right));
        expect(rect.top, greaterThanOrEqualTo(bounds.top));
        expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
        expect(rect.width, closeTo(MazlMotion.loadingThreadWidth, 1e-9));
      }
    });

    testWidgets('it loops: after a full period it is back near the start', (
      tester,
    ) async {
      await _setUp(tester);
      await tester.pumpWidget(_app());
      final render = _thread(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final start = render.threadRect!.left;
      await tester.pump(MazlMotion.loadingThreadPeriod);
      expect((render.threadRect!.left - start).abs(), lessThan(8));
    });
  });

  group('colour', () {
    for (final (name, theme) in [
      ('light', AppTheme.lightTheme),
      ('dark', AppTheme.darkTheme),
    ]) {
      testWidgets('the thread is the accent and the block is not ($name)', (
        tester,
      ) async {
        await _setUp(tester);
        final boundary = GlobalKey();
        await tester.pumpWidget(_app(theme: theme, boundary: boundary));
        final accent = theme.colorScheme.primary;
        expect(
          accent,
          name == 'light' ? AppColors.tekhelet : AppColors.tekheletLight,
        );
        final block = theme.colorScheme.surfaceContainer;
        expect(_close(block, accent, tolerance: 40), isFalse);

        // A quarter of the period: the thread crosses the block.
        await tester.pump();
        await tester.pump(MazlMotion.loadingThreadPeriod ~/ 4);
        final render = _thread(tester);
        final x = render.threadRect!.center.dx.floor();
        expect(x, lessThan(_blockWidth.toInt()), reason: 'over the block');
        final onThread = await _pixel(
          tester,
          await _snapshot(tester, boundary),
          x,
          (_blockHeight / 2).round(),
        );
        expect(_close(onThread, accent), isTrue, reason: '$onThread');
        expect(onThread.a, 1.0);

        // Beside the thread the block keeps its own flat colour.
        final beside = await _pixel(
          tester,
          await _snapshot(tester, boundary),
          x + 20,
          (_blockHeight / 2).round(),
        );
        expect(_close(beside, block), isTrue, reason: '$beside');
      });
    }

    testWidgets('the thread is only visible on blocks, not on empty space', (
      tester,
    ) async {
      await _setUp(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(_app(boundary: boundary));

      // Half a period: the thread is in the middle, beyond the block.
      await tester.pump();
      await tester.pump(MazlMotion.loadingThreadPeriod ~/ 2);
      final x = _thread(tester).threadRect!.center.dx.floor();
      expect(x, greaterThan(_blockWidth.toInt()), reason: 'past the block');
      final image = await _snapshot(tester, boundary);
      for (final y in [10, 50, 90]) {
        expect((await _pixel(tester, image, x, y)).a, 0.0, reason: 'y=$y');
      }
    });

    testWidgets('the thread fades out at its two ends', (tester) async {
      await _setUp(tester);
      final boundary = GlobalKey();
      await tester.pumpWidget(_app(boundary: boundary));
      await tester.pump();
      await tester.pump(MazlMotion.loadingThreadPeriod ~/ 4);
      final x = _thread(tester).threadRect!.center.dx.floor();
      final image = await _snapshot(tester, boundary);

      final top = await _pixel(tester, image, x, 1);
      final middle = await _pixel(tester, image, x, 30);
      expect(top.a, 1.0, reason: 'the block pixel itself stays opaque');
      expect(
        _close(top, middle, tolerance: 20),
        isFalse,
        reason: 'the thread is nearly gone at its top end',
      );
    });
  });

  group('reduced motion', () {
    testWidgets('no thread and no frame scheduled', (tester) async {
      await _setUp(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pumpWidget(_app());
      await tester.pump();

      final render = _thread(tester);
      expect(render.threadRect, isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pump(const Duration(seconds: 3));
      expect(render.threadRect, isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('the setting changed while it runs starts and stops it', (
      tester,
    ) async {
      await _setUp(tester);
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 200));
      expect(_thread(tester).threadRect, isNotNull);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      await tester.pump();
      await tester.pump();
      expect(_thread(tester).threadRect, isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_thread(tester).threadRect, isNotNull);
    });
  });

  group('lifecycle', () {
    testWidgets('the ticker stops when the skeleton disappears', (
      tester,
    ) async {
      await _setUp(tester);
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a list skeleton runs one thread, not one per row', (
      tester,
    ) async {
      await _setUp(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ChatListSkeleton()),
        ),
      );
      expect(find.byType(LoadingThread), findsOneWidget);
    });
  });

  test('no file in lib/ refers to the shimmer package any more', () {
    final offenders = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            entity.readAsStringSync().contains('package:shimmer'))
          entity.path,
    ];
    expect(offenders, isEmpty);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('shimmer:')),
    );
  });
}
