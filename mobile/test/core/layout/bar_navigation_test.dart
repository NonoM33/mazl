import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/bar_navigation.dart';

import '../../helpers/duo_poses.dart';

// Renaud on 2026-10-27, on the foldable iPhone closed: the back button sat in
// the top-left corner, out of reach. iOS puts a screen's navigation at the top
// of the vertical bar (regles/iphone-duo.md §2.6): back first, then actions.
Widget _page(DuoPoseController pose) => MaterialApp(
  builder: duoAppBuilder(pose),
  home: Scaffold(
    body: BarNavigation(
      buttons: [
        IconButton(
          key: const Key('back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        IconButton(
          key: const Key('more'),
          icon: const Icon(Icons.more_horiz),
          onPressed: () {},
        ),
      ],
      inline: Row(
        children: [
          IconButton(
            key: const Key('back'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            key: const Key('more'),
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
    ),
  ),
);

Future<DuoPoseController> _pump(WidgetTester tester, DuoPose pose) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(_page(controller));
  await tester.pump();
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  for (final pose in [
    DuoPose.closed,
    DuoPose.tent,
    DuoPose.openLandscape,
    DuoPose.halfOpenBook,
  ]) {
    testWidgets(
      '${pose.name}: back then more, at the top of the vertical bar',
      (tester) async {
        await _pump(tester, pose);
        final controls = pose.verticalBar!.controls;
        final back = tester.getRect(find.byKey(const Key('back')));
        final more = tester.getRect(find.byKey(const Key('more')));
        expect(
          find.byKey(const Key('back')),
          findsOneWidget,
          reason: 'drawn once, in the column',
        );
        expect(
          controls.inflate(0.5).contains(back.topLeft) &&
              controls.inflate(0.5).contains(back.bottomRight),
          isTrue,
          reason: 'back at $back, column $controls',
        );
        expect(
          back.top,
          lessThan(controls.top + 60),
          reason: 'at the top, under the status bar',
        );
        expect(
          more.top,
          greaterThan(back.bottom),
          reason: 'back first, then the actions',
        );
        for (final occluded in pose.foldState.occlusions) {
          expect(
            back.overlaps(occluded),
            isFalse,
            reason: 'not under the status bar',
          );
        }
      },
    );
  }

  for (final pose in [
    DuoPose.openPortrait,
    DuoPose.halfOpenLaptop,
    DuoPose.splitView,
  ]) {
    testWidgets(
      '${pose.name}: no vertical bar, the screen draws its own buttons',
      (tester) async {
        await _pump(tester, pose);
        final back = tester.getRect(find.byKey(const Key('back')));
        final more = tester.getRect(find.byKey(const Key('more')));
        expect(back.left, lessThan(more.left));
        expect(
          (back.top - more.top).abs(),
          lessThan(1),
          reason: 'one row, as before',
        );
      },
    );
  }

  testWidgets('a tab kept offstage does not publish over the tab on screen', (
    tester,
  ) async {
    const pose = DuoPose.closed;
    setDuoPose(tester, pose);
    Widget nav(String key) => BarNavigation(
      buttons: [
        IconButton(
          key: Key(key),
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      ],
      inline: const SizedBox(),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: duoAppBuilder(DuoPoseController(pose)),
        home: Scaffold(
          body: Stack(
            children: [
              nav('visible'),
              TickerMode(enabled: false, child: Offstage(child: nav('hidden'))),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('visible')), findsOneWidget);
    expect(find.byKey(const Key('hidden')), findsNothing);
  });
}
