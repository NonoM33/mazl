import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/content_max_width.dart';
import 'package:mazl/core/layout/fold_aware_split.dart';
import 'package:mazl/core/layout/fold_channel.dart';
import 'package:mazl/core/layout/fold_safe_actions.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/layout/side_safe_area.dart';

import '../../helpers/duo_poses.dart';

// The fold of the foldable iPhone reaches the layout through the `mazl/fold`
// channel (ios/Runner/FoldPosturePlugin.swift). The message shape below is
// the one that file sends: {hinge: <UIHinge.Status name>, divisions: [rect]}.

const _lead = Key('lead');
const _field = Key('field');

/// A page split around the fold: a title as lead, a text field and a
/// "Next" button as action.
Widget _page(
  DuoPoseController pose, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  builder: duoAppBuilder(pose),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: SafeArea(
        child: FoldAwareSplit(
          lead: const Center(key: _lead, child: Text('Title')),
          action: Builder(
            builder: (context) => Column(
              children: [
                Text('axis ${FoldAwareSplit.axisOf(context)?.name}'),
                const Expanded(child: TextField(key: _field)),
                ElevatedButton(onPressed: () {}, child: const Text('Next')),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose start, {
  TextDirection direction = TextDirection.ltr,
}) async {
  setDuoPose(tester, start);
  final pose = DuoPoseController(start);
  await tester.pumpWidget(_page(pose, direction: direction));
  await settleFold(tester);
  return pose;
}

void main() {
  group('FoldState.fromMessage', () {
    test('reads the hinge and the division regions', () {
      final state = FoldState.fromMessage({
        'hinge': 'partiallyOpen',
        'divisions': [
          {'x': 451.0, 'y': 0, 'width': 49, 'height': 669.0},
        ],
      });
      expect(state.hinge, HingeStatus.partiallyOpen);
      expect(state.activeDivision, const Rect.fromLTWH(451, 0, 49, 669));
    });

    test('each status name of the native side is known', () {
      for (final name in ['unknown', 'closed', 'partiallyOpen', 'fullyOpen']) {
        expect(
          FoldState.fromMessage({
            'hinge': name,
            'divisions': <Object>[],
          }).hinge.name,
          name,
        );
      }
    });

    test('a malformed message never moves the layout', () {
      expect(FoldState.fromMessage(null), FoldState.unknown);
      expect(FoldState.fromMessage('open'), FoldState.unknown);
      expect(FoldState.fromMessage({'hinge': 'ajar'}), FoldState.unknown);
      final badRect = FoldState.fromMessage({
        'hinge': 'partiallyOpen',
        'divisions': [
          {'x': 1, 'y': 2, 'width': -3, 'height': 4},
        ],
      });
      expect(badRect.activeDivision, isNull);
      final notNumbers = FoldState.fromMessage({
        'hinge': 'partiallyOpen',
        'divisions': [
          {'x': '1', 'y': 2, 'width': 3, 'height': 4},
        ],
      });
      expect(notNumbers.activeDivision, isNull);
    });
  });

  group('platformFoldStates', () {
    test('off iOS the fold stays unknown', () async {
      expect(
        await platformFoldStates(platform: TargetPlatform.android).first,
        FoldState.unknown,
      );
    });

    test('on iOS each channel message becomes a fold state', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      const channel = EventChannel('mazl/fold-test');
      binding.defaultBinaryMessenger.setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            events.success({'hinge': 'closed', 'divisions': <Object>[]});
            events.success({
              'hinge': 'partiallyOpen',
              'divisions': [
                {'x': 0, 'y': 451, 'width': 669, 'height': 49},
              ],
            });
          },
        ),
      );
      final states = await platformFoldStates(
        channel: channel,
        platform: TargetPlatform.iOS,
      ).take(2).toList();
      expect(states.map((s) => s.hinge), [
        HingeStatus.closed,
        HingeStatus.partiallyOpen,
      ]);
      expect(states.last.activeDivision, const Rect.fromLTWH(0, 451, 669, 49));
    });
  });

  group('FoldAwareSplit', () {
    testWidgets('flat when nothing folds: the action fills the page, no lead', (
      tester,
    ) async {
      for (final pose in [
        DuoPose.closed,
        DuoPose.openPortrait,
        DuoPose.openLandscape,
        DuoPose.splitView,
      ]) {
        await _pump(tester, pose);
        expect(find.byKey(_lead), findsNothing, reason: pose.name);
        expect(find.text('axis null'), findsOneWidget, reason: pose.name);
        expectFitsDuoPose(tester, pose, 'flat page');
      }
    });

    testWidgets('laptop pose: lead above the fold, fields and button below', (
      tester,
    ) async {
      await _pump(tester, DuoPose.halfOpenLaptop);
      final fold = DuoPose.halfOpenLaptop.fold!;
      expect(find.text('axis horizontal'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_lead)).bottom,
        lessThanOrEqualTo(fold.top),
      );
      expect(
        tester.getRect(find.byKey(_field)).top,
        greaterThanOrEqualTo(fold.bottom),
      );
      expect(
        tester.getRect(find.text('Next')).top,
        greaterThanOrEqualTo(fold.bottom),
      );
      expectFitsDuoPose(tester, DuoPose.halfOpenLaptop, 'split page');
    });

    testWidgets('book pose: lead on the start side, action beyond the fold', (
      tester,
    ) async {
      await _pump(tester, DuoPose.halfOpenBook);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(find.text('axis vertical'), findsOneWidget);
      expect(
        tester.getRect(find.byKey(_lead)).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        tester.getRect(find.byKey(_field)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'split page');
    });

    testWidgets('book pose in Hebrew: the lead is on the right', (
      tester,
    ) async {
      await _pump(tester, DuoPose.halfOpenBook, direction: TextDirection.rtl);
      final fold = DuoPose.halfOpenBook.fold!;
      expect(
        tester.getRect(find.byKey(_lead)).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        tester.getRect(find.byKey(_field)).right,
        lessThanOrEqualTo(fold.left),
      );
    });

    testWidgets('folding and unfolding keep what the member typed', (
      tester,
    ) async {
      final pose = await _pump(tester, DuoPose.openPortrait);
      await tester.enterText(find.byKey(_field), 'Jeanne');
      for (final next in [
        DuoPose.halfOpenLaptop,
        DuoPose.openPortrait,
        DuoPose.halfOpenBook,
        DuoPose.closed,
      ]) {
        await pose.moveTo(tester, next);
        expect(find.text('Jeanne'), findsOneWidget, reason: next.name);
      }
    });

    testWidgets('a fold too close to an edge leaves the page flat', (
      tester,
    ) async {
      setDuoPose(tester, DuoPose.openPortrait);
      await tester.pumpWidget(
        MaterialApp(
          home: FoldScope(
            state: const FoldState(
              hinge: HingeStatus.partiallyOpen,
              divisions: [Rect.fromLTWH(0, 100, 669, 40)],
            ),
            child: Scaffold(
              body: FoldAwareSplit(
                lead: const SizedBox(key: _lead),
                action: Builder(
                  builder: (context) =>
                      Text('axis ${FoldAwareSplit.axisOf(context)?.name}'),
                ),
              ),
            ),
          ),
        ),
      );
      await settleFold(tester);
      expect(find.text('axis null'), findsOneWidget);
    });
  });

  testWidgets(
    'SideSafeArea keeps a full-width button beside the status column',
    (tester) async {
      setDuoPose(tester, DuoPose.closed);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => SideSafeArea(child: child!),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Une femme'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getRect(find.byType(ElevatedButton)).right,
        lessThanOrEqualTo(466 - 84),
      );
      expectFitsDuoPose(tester, DuoPose.closed, 'full-width button');
    },
  );

  testWidgets('the reading column spans the window when a book fold cuts it', (
    tester,
  ) async {
    for (final (pose, width) in [
      (DuoPose.openLandscape, kContentMaxWidth),
      (DuoPose.halfOpenBook, 951.0 - 84),
    ]) {
      setDuoPose(tester, pose);
      await tester.pumpWidget(
        MaterialApp(
          builder: duoAppBuilder(DuoPoseController(pose)),
          home: const ContentMaxWidth(child: SizedBox.expand(key: _lead)),
        ),
      );
      expect(tester.getSize(find.byKey(_lead)).width, width, reason: pose.name);
    }
  });

  for (final pose in [DuoPose.halfOpenBook, DuoPose.halfOpenLaptop]) {
    testWidgets('${pose.name}: a dialog keeps out of the fold by itself', (
      tester,
    ) async {
      setDuoPose(tester, pose);
      await tester.pumpWidget(
        MaterialApp(
          builder: duoAppBuilder(DuoPoseController(pose)),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: const Text('Hello'),
                      actions: [
                        TextButton(onPressed: () {}, child: const Text('OK')),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(AlertDialog)).overlaps(pose.fold!),
        isFalse,
      );
      expect(tester.getRect(find.text('OK')).overlaps(pose.fold!), isFalse);
    });
  }

  group('FoldSafeActions', () {
    Widget page(DuoPose pose) => MaterialApp(
      builder: duoAppBuilder(DuoPoseController(pose)),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FoldSafeActions(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Continuer'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets(
      'book pose: the button takes the side of the vertical bar, out of the fold',
      (tester) async {
        setDuoPose(tester, DuoPose.halfOpenBook);
        await tester.pumpWidget(page(DuoPose.halfOpenBook));
        await settleFold(tester);
        final rect = tester.getRect(find.byType(ElevatedButton));
        expect(
          rect.left,
          greaterThanOrEqualTo(DuoPose.halfOpenBook.fold!.right),
        );
        expect(rect.width, greaterThan(200));
        expectFitsDuoPose(tester, DuoPose.halfOpenBook, 'actions');
      },
    );

    for (final pose in [
      DuoPose.closed,
      DuoPose.openLandscape,
      DuoPose.halfOpenLaptop,
    ]) {
      testWidgets('${pose.name}: the button keeps its full width', (
        tester,
      ) async {
        setDuoPose(tester, pose);
        await tester.pumpWidget(page(pose));
        await settleFold(tester);
        final safe = pose.safeRect;
        expect(
          tester.getRect(find.byType(ElevatedButton)).width,
          closeTo(safe.width - 32, 0.5),
        );
      });
    }
  });
}
