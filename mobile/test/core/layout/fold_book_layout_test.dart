import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_cut.dart';
import 'package:mazl/core/layout/fold_grid.dart';
import 'package:mazl/core/layout/fold_spread.dart';

import '../../helpers/duo_poses.dart';

// Book pose (duo_poses.dart): the fold runs down x = 455.5 .. 495.5 of a
// 951 x 669 window. The pages below fill the window, so window and page
// coordinates are the same.

Future<DuoPoseController> _pump(
  WidgetTester tester,
  DuoPose start,
  Widget page, {
  TextDirection direction = TextDirection.ltr,
}) async {
  setDuoPose(tester, start);
  final pose = DuoPoseController(start);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FoldScopeForTest(pose: pose, child: child!),
      home: Directionality(textDirection: direction, child: page),
    ),
  );
  await settleFold(tester);
  return pose;
}

/// [duoAppBuilder] without the side safe area: these pages fill the window.
class FoldScopeForTest extends StatelessWidget {
  const FoldScopeForTest({super.key, required this.pose, required this.child});

  final DuoPoseController pose;
  final Widget child;

  @override
  Widget build(BuildContext context) => duoAppBuilder(pose)(
    context,
    MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: child,
    ),
  );
}

Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  final fold = DuoPose.halfOpenBook.fold!;

  group('FoldSpread', () {
    Widget spread() => const Scaffold(
      body: FoldSpread(
        start: [
          Text('Profil'),
          TextField(key: Key('name')),
        ],
        end: [Text('Réglages')],
      ),
    );

    testWidgets('book pose: start before the fold, end after it', (
      tester,
    ) async {
      await _pump(tester, DuoPose.halfOpenBook, spread());
      expect(
        _rectOf(tester, find.text('Profil')).right,
        lessThanOrEqualTo(fold.left),
      );
      expect(
        _rectOf(tester, find.text('Réglages')).left,
        greaterThanOrEqualTo(fold.right),
      );
    });

    testWidgets('book pose in Hebrew: the start page is on the right', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        spread(),
        direction: TextDirection.rtl,
      );
      expect(
        _rectOf(tester, find.text('Profil')).left,
        greaterThanOrEqualTo(fold.right),
      );
      expect(
        _rectOf(tester, find.text('Réglages')).right,
        lessThanOrEqualTo(fold.left),
      );
    });

    testWidgets('opened flat sideways: two pages around the middle', (
      tester,
    ) async {
      await _pump(tester, DuoPose.openLandscape, spread());
      // The pages share the room the side column leaves: 951 - 84 points.
      const room = 951.0 - 84;
      const secondPage = (room + kSpreadGutter) / 2;
      final start = _rectOf(tester, find.text('Profil'));
      final end = _rectOf(tester, find.text('Réglages'));
      expect(start.right, lessThanOrEqualTo(secondPage - kSpreadGutter));
      expect(end.left, secondPage);
      expect(end.top, start.top, reason: 'side by side, not one below');
    });

    testWidgets('a page inside margins still reads as two pages opened flat '
        'sideways (the Discover card, about 835 pt wide)', (tester) async {
      await _pump(
        tester,
        DuoPose.openLandscape,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: FoldSpread(start: [Text('Photo')], end: [Text('Nom')]),
          ),
        ),
      );
      final start = _rectOf(tester, find.text('Photo'));
      final end = _rectOf(tester, find.text('Nom'));
      expect(end.top, start.top, reason: 'side by side');
      expect(end.left, greaterThan(start.right));
    });

    testWidgets('upright and laptop: one list, end below start', (
      tester,
    ) async {
      for (final pose in [DuoPose.openPortrait, DuoPose.halfOpenLaptop]) {
        await _pump(tester, pose, spread());
        final start = _rectOf(tester, find.text('Profil'));
        final end = _rectOf(tester, find.text('Réglages'));
        expect(end.top, greaterThan(start.bottom), reason: pose.name);
        expect(end.left, start.left, reason: pose.name);
      }
    });

    group('wideFrom', () {
      Widget wide() => const Scaffold(
        body: FoldSpread(
          wideFrom: 560,
          start: [Text('Profil')],
          end: [Text('Réglages')],
        ),
      );

      testWidgets('a window as wide as asked: two lists side by side', (
        tester,
      ) async {
        for (final pose in [DuoPose.openPortrait, DuoPose.halfOpenLaptop]) {
          await _pump(tester, pose, wide());
          final start = _rectOf(tester, find.text('Profil'));
          final end = _rectOf(tester, find.text('Réglages'));
          expect(end.top, start.top, reason: pose.name);
          expect(end.left, greaterThanOrEqualTo(start.right), reason: pose.name);
        }
      });

      testWidgets('a narrower window stays one list', (tester) async {
        await _pump(tester, DuoPose.closed, wide());
        final start = _rectOf(tester, find.text('Profil'));
        final end = _rectOf(tester, find.text('Réglages'));
        expect(end.top, greaterThanOrEqualTo(start.bottom));
        expect(end.left, start.left);
      });

      testWidgets('in Hebrew the start page is on the right', (tester) async {
        await _pump(
          tester,
          DuoPose.openPortrait,
          wide(),
          direction: TextDirection.rtl,
        );
        expect(
          _rectOf(tester, find.text('Profil')).left,
          greaterThanOrEqualTo(_rectOf(tester, find.text('Réglages')).right),
        );
      });

      testWidgets('the book keeps its fold whatever wideFrom says', (
        tester,
      ) async {
        await _pump(tester, DuoPose.halfOpenBook, wide());
        expect(
          _rectOf(tester, find.text('Profil')).right,
          lessThanOrEqualTo(fold.left),
        );
        expect(
          _rectOf(tester, find.text('Réglages')).left,
          greaterThanOrEqualTo(fold.right),
        );
      });
    });

    testWidgets('folding and unfolding keep what the member typed', (
      tester,
    ) async {
      final pose = await _pump(tester, DuoPose.openPortrait, spread());
      await tester.enterText(find.byKey(const Key('name')), 'Jeanne');
      await pose.moveTo(tester, DuoPose.halfOpenBook);
      expect(find.text('Jeanne'), findsOneWidget);
      await pose.moveTo(tester, DuoPose.openPortrait);
      expect(find.text('Jeanne'), findsOneWidget);
    });
  });

  group('FoldGridDelegate', () {
    Widget grid({double padding = 16}) => Scaffold(
      body: FoldCutBuilder(
        builder: (context, cut) => GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: FoldGridDelegate(
            cut: cut,
            crossAxisStart: padding,
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: 12,
          itemBuilder: (context, i) =>
              ColoredBox(key: Key('tile$i'), color: Colors.grey),
        ),
      ),
    );

    testWidgets('book pose: no tile crosses the fold, both pages are used', (
      tester,
    ) async {
      await _pump(tester, DuoPose.halfOpenBook, grid());
      var before = 0;
      var after = 0;
      for (var i = 0; i < 4; i++) {
        final tile = _rectOf(tester, find.byKey(Key('tile$i')));
        expect(tile.overlaps(fold), isFalse, reason: 'tile $i at $tile');
        if (tile.right <= fold.left) before++;
        if (tile.left >= fold.right) after++;
        expect(tile.left, greaterThanOrEqualTo(16), reason: 'tile $i');
        expect(tile.right, lessThanOrEqualTo(951 - 16), reason: 'tile $i');
      }
      expect(before, 2);
      expect(after, 2);
    });

    testWidgets('book pose right to left: still clear of the fold', (
      tester,
    ) async {
      await _pump(
        tester,
        DuoPose.halfOpenBook,
        grid(),
        direction: TextDirection.rtl,
      );
      for (var i = 0; i < 4; i++) {
        final tile = _rectOf(tester, find.byKey(Key('tile$i')));
        expect(tile.overlaps(fold), isFalse, reason: 'tile $i at $tile');
      }
      expect(
        _rectOf(tester, find.byKey(const Key('tile0'))).left,
        greaterThan(fold.right),
        reason: 'the first tile reads first, on the right',
      );
    });

    testWidgets('flat: the regular grid of tiles at most 220 wide', (
      tester,
    ) async {
      await _pump(tester, DuoPose.openLandscape, grid());
      final first = _rectOf(tester, find.byKey(const Key('tile0')));
      expect(first.left, 16);
      expect(first.width, lessThanOrEqualTo(220));
    });
  });
}
