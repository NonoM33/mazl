import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/column_app_bar.dart';

import '../../helpers/duo_poses.dart';

// Renaud on 2026-10-27: on the foldable iPhone, the back button of every
// screen sat in the top-left corner, out of reach of the thumb. With a vertical
// bar it goes to the top of the column, then the icon actions.
Widget _app(DuoPoseController pose) => MaterialApp(
  builder: duoAppBuilder(pose),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: ColumnAppBar(
                  appBar: AppBar(
                    title: const Text('Réglages'),
                    actions: [
                      IconButton(
                        key: const Key('more'),
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {},
                      ),
                      TextButton(
                        key: const Key('save'),
                        onPressed: () {},
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
                body: const SizedBox.expand(),
              ),
            ),
          ),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, DuoPose pose) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(_app(DuoPoseController(pose)));
  await tester.pump();
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  for (final pose in [
    DuoPose.closed,
    DuoPose.tent,
    DuoPose.openLandscape,
    DuoPose.halfOpenBook,
  ]) {
    testWidgets(
      '${pose.name}: back and the icon action in the column, the text action stays',
      (tester) async {
        await _open(tester, pose);
        final controls = pose.verticalBar!.controls.inflate(0.5);
        final back = tester.getRect(find.byType(BackButton));
        final more = tester.getRect(find.byKey(const Key('more')));
        expect(find.byType(BackButton), findsOneWidget);
        expect(
          controls.contains(back.topLeft) &&
              controls.contains(back.bottomRight),
          isTrue,
          reason: 'back at $back, column $controls',
        );
        expect(more.top, greaterThan(back.bottom), reason: 'back first');
        expect(controls.contains(more.center), isTrue);
        expect(
          controls.contains(tester.getCenter(find.byKey(const Key('save')))),
          isFalse,
          reason: 'a text button stays in the bar',
        );
        expect(find.text('Réglages'), findsOneWidget);

        await tester.longPress(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          find.text('Back'),
          findsOneWidget,
          reason: 'its tooltip shows over the column',
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          find.text('ouvrir'),
          findsOneWidget,
          reason: 'the back button in the column pops the page',
        );
        expect(
          find.byType(BackButton),
          findsNothing,
          reason: 'it leaves the column with its page',
        );
      },
    );
  }

  for (final pose in [DuoPose.openPortrait, DuoPose.halfOpenLaptop]) {
    testWidgets('${pose.name}: no column, the bar as before', (tester) async {
      await _open(tester, pose);
      final back = tester.getRect(find.byType(BackButton));
      final title = tester.getRect(find.text('Réglages'));
      expect(back.right, lessThanOrEqualTo(title.left + 1));
      expect((back.center.dy - title.center.dy).abs(), lessThan(4));
    });
  }
}
