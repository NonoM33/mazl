import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/layout/vertical_bar.dart';
import 'package:mazl/presentation/features/navigation/widgets/adaptive_shell.dart';
import 'package:mazl/presentation/features/navigation/widgets/mazl_nav_bar.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';

// Where the tabs go on the foldable iPhone, as Apple's own tab bar does
// (Tech Talk « Design for iPhone Duo »): in the vertical bar, bottom aligned
// below the status bar, when the device is closed, held sideways or half open
// like a book; at the bottom on the inner display held upright.

const _strip = Key('mazl-nav-strip');
const _bottom = Key('mazl-nav-bar');
const _rail = Key('mazl-nav-rail');
const _items = [
  MazlNavItem(icon: Icons.layers, label: 'Découvrir'),
  MazlNavItem(icon: Icons.favorite, label: 'Matchs'),
  MazlNavItem(icon: Icons.chat_bubble, label: 'Messages'),
  MazlNavItem(icon: Icons.event, label: 'Événements'),
  MazlNavItem(icon: Icons.person, label: 'Profil'),
];

class _Shell extends StatefulWidget {
  const _Shell({this.twoPane = false});

  final bool twoPane;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int index = 0;

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    items: _items,
    currentIndex: index,
    onSelect: (i) => setState(() => index = i),
    paneFor: widget.twoPane
        ? (context, _) => const SizedBox.expand(key: Key('detail'))
        : null,
    body: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: ListView(
            children: [
              Text('tab $index'),
              const TextField(key: Key('draft')),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(content: Text('Hello')),
                ),
                child: const Text('dialog'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: Center(child: Text('page'))),
                      ),
                    ),
                child: const Text('page'),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(_SeeThroughRoute()),
                child: const Text('open detail'),
              ),
              const SizedBox(
                height: 200,
                child: SizedBox.expand(key: Key('list')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Like the chat opened from the list on a regular window: a route that
/// draws nothing and lets the shell show the detail in its pane.
class _SeeThroughRoute extends PageRoute<void> {
  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) => Builder(
    builder: (context) => Column(
      children: [
        const VerticalBarPassThrough(),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(content: Text('Over detail')),
          ),
          child: const Text('dialog over detail'),
        ),
      ],
    ),
  );
}

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose pose, {
  bool twoPane = false,
}) async {
  setDuoPose(tester, pose);
  final controller = DuoPoseController(pose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: kTestLocale,
      builder: duoAppBuilder(controller),
      home: _Shell(twoPane: twoPane),
    ),
  );
  await tester.pumpAndSettle();
  await settleFold(tester);
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  // Closed and lying the other way, the island sits at the BOTTOM of the
  // column: the tabs vanished (no room "below the lowest system element").
  test('the controls take the free part of the column, above a low island', () {
    final bar = DuoPose.closedSideways.verticalBar!;
    expect(bar.side, VerticalBarSide.right);
    expect(bar.controls.top, VerticalBarGeometry.bottomMargin);
    expect(bar.controls.bottom, 384 - VerticalBarGeometry.gap);
    expect(bar.controls.height, greaterThan(5 * 48));
  });

  test(
    'the native report decides the bar, the measured occlusions bound it',
    () {
      final bar = VerticalBarGeometry.resolve(
        fold: DuoPose.closed.foldState,
        size: DuoPose.closed.size,
        viewPadding: DuoPose.closed.padding,
        platform: TargetPlatform.iOS,
      )!;
      expect(bar.side, VerticalBarSide.right);
      expect(bar.strip, const Rect.fromLTWH(382, 0, 84, 678));
      expect(bar.controls.top, 174 + VerticalBarGeometry.gap);
      expect(bar.controls.bottom, 678 - VerticalBarGeometry.bottomMargin);
      // Horizontal bars: no vertical bar.
      expect(
        VerticalBarGeometry.resolve(
          fold: DuoPose.openPortrait.foldState,
          size: DuoPose.openPortrait.size,
          viewPadding: DuoPose.openPortrait.padding,
          platform: TargetPlatform.iOS,
        ),
        isNull,
      );
      // Off iOS, a one-sided inset alone is not a vertical bar.
      expect(
        VerticalBarGeometry.resolve(
          fold: FoldState.unknown,
          size: DuoPose.closed.size,
          viewPadding: DuoPose.closed.padding,
          platform: TargetPlatform.android,
        ),
        isNull,
      );
      // iOS without a report (before 27.1): the one-sided column is guessed.
      expect(
        VerticalBarGeometry.resolve(
          fold: FoldState.unknown,
          size: DuoPose.closed.size,
          viewPadding: DuoPose.closed.padding,
          platform: TargetPlatform.iOS,
        )?.side,
        VerticalBarSide.right,
      );
    },
  );

  // Every pose with a column, each rotation included: in one of them the tabs
  // fell off the screen while the column was empty (2026-10-27).
  for (final pose in DuoPose.values.where((p) => p.verticalBar != null)) {
    testWidgets(
      '${pose.name}: the tabs are in the vertical bar, bottom aligned',
      (tester) async {
        await _pump(tester, pose);
        final bar = pose.verticalBar!;
        expect(find.byKey(_bottom), findsNothing);
        expect(find.byKey(_rail), findsNothing);
        final capsule = tester.getRect(find.byKey(_strip));
        expect(capsule.left, greaterThanOrEqualTo(bar.strip.left));
        expect(capsule.right, lessThanOrEqualTo(bar.strip.right));
        expect(capsule.center.dx, closeTo(bar.strip.center.dx, 0.5));
        expect(capsule.bottom, closeTo(bar.controls.bottom, 0.5));
        expect(capsule.top, greaterThanOrEqualTo(bar.controls.top));
        // Judged on the screen itself, not on the computed column.
        expect(capsule.top, greaterThanOrEqualTo(0));
        expect(capsule.bottom, lessThanOrEqualTo(pose.size.height));
        expect(capsule.height, greaterThanOrEqualTo(3 * 44));
        for (final system in pose.foldState.occlusions) {
          expect(capsule.overlaps(system), isFalse, reason: '$system');
        }
        expectFitsDuoPose(tester, pose, 'shell');
        await tester.tap(find.bySemanticsLabel('Messages'));
        await tester.pumpAndSettle();
        expect(find.text('tab 2'), findsOneWidget);
      },
    );
  }

  for (final pose in [
    DuoPose.openPortrait,
    DuoPose.halfOpenLaptop,
    DuoPose.splitView,
  ]) {
    testWidgets('${pose.name}: horizontal bars, the capsule at the bottom', (
      tester,
    ) async {
      await _pump(tester, pose);
      expect(find.byKey(_strip), findsNothing);
      expect(find.byKey(_rail), findsNothing);
      final capsule = tester.getRect(find.byKey(_bottom));
      expect(capsule.width, lessThanOrEqualTo(kBottomBarMaxWidth));
      expect(capsule.center.dx, closeTo(pose.size.width / 2, 0.5));
      expect(
        capsule.bottom,
        lessThanOrEqualTo(pose.size.height - pose.padding.bottom),
      );
      if (pose.fold != null) {
        expect(capsule.top, greaterThanOrEqualTo(pose.fold!.bottom));
      }
      expectFitsDuoPose(tester, pose, 'shell');
    });
  }

  testWidgets(
    'half open like a book: the fold is the line between list and detail',
    (tester) async {
      await _pump(tester, DuoPose.halfOpenBook, twoPane: true);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.byKey(const Key('list'))).right,
        closeTo(fold.left, 0.5),
      );
      expect(
        tester.getRect(find.byKey(const Key('detail'))).left,
        closeTo(fold.right, 0.5),
      );
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'two panes');
    },
  );

  testWidgets('a dialog or a page over the tabs takes the vertical bar back', (
    tester,
  ) async {
    await _pump(tester, DuoPose.closed);
    expect(find.byKey(_strip), findsOneWidget);
    await tester.tap(find.text('dialog'));
    await tester.pumpAndSettle();
    expect(find.byKey(_strip), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(_strip), findsOneWidget);
    await tester.tap(find.text('page'));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsWidgets);
    expect(find.byKey(_strip), findsNothing);
    Navigator.of(tester.element(find.text('page').last)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_strip), findsOneWidget);
  });

  // Vécu au simulateur le 2026-10-26 : une conversation ouverte dans le
  // panneau de droite faisait disparaître la barre d'onglets.
  testWidgets(
    'a detail opened in the pane keeps the tabs; a dialog over it takes them back',
    (tester) async {
      await _pump(tester, DuoPose.openLandscape, twoPane: true);
      expect(find.byKey(_strip), findsOneWidget);
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();
      expect(find.byKey(_strip), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Matchs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('dialog over detail'));
      await tester.pumpAndSettle();
      expect(find.byKey(_strip), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byKey(_strip), findsOneWidget);
      Navigator.of(tester.element(find.text('dialog over detail'))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_strip), findsOneWidget);
    },
  );

  testWidgets(
    'folding and unfolding moves the tabs, keeps the tab and the draft',
    (tester) async {
      final pose = await _pump(tester, DuoPose.closed);
      await tester.tap(find.bySemanticsLabel('Matchs'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('draft')), 'Shalom');
      for (final next in [
        DuoPose.openPortrait,
        DuoPose.halfOpenBook,
        DuoPose.openLandscape,
        DuoPose.halfOpenLaptop,
        DuoPose.closed,
      ]) {
        await pose.moveTo(tester, next);
        await tester.pumpAndSettle();
        expect(find.text('tab 1'), findsOneWidget, reason: next.name);
        expect(find.text('Shalom'), findsOneWidget, reason: next.name);
        expect(
          find.byKey(next.verticalBar == null ? _bottom : _strip),
          findsOneWidget,
          reason: next.name,
        );
      }
    },
  );

  testWidgets('off iOS a regular window keeps the leading rail', (
    tester,
  ) async {
    setDuoPose(tester, DuoPose.openPortrait);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: kTestLocale,
        builder: duoAppBuilder(DuoPoseController(DuoPose.openPortrait)),
        home: const _Shell(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_rail), findsOneWidget);
    expect(find.byKey(_bottom), findsNothing);
  });

  testWidgets(
    'every tab of the vertical bar is tappable across the whole capsule',
    (tester) async {
      await _pump(tester, DuoPose.closed);
      final capsule = tester.getRect(find.byKey(_strip));
      final buttons = find.descendant(
        of: find.byKey(_strip),
        matching: find.byType(InkResponse),
      );
      expect(buttons, findsNWidgets(_items.length));
      for (final button
          in tester.widgetList(buttons).map((w) => find.byWidget(w))) {
        final rect = tester.getRect(button);
        // Apple: 44 x 44 pt at least; here the whole width of the capsule.
        expect(rect.width, closeTo(capsule.width, 0.5));
        expect(rect.height, greaterThanOrEqualTo(44));
      }
      // A tap near the edge of the capsule, not on the icon, still changes tab.
      final messages = tester.getRect(
        find
            .descendant(
              of: find.byKey(_strip),
              matching: find.byType(InkResponse),
            )
            .at(2),
      );
      await tester.tapAt(Offset(capsule.left + 6, messages.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('tab 2'), findsOneWidget);
    },
  );
}
