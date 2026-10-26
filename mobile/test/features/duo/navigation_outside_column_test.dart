import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/bar_navigation.dart';
import 'package:mazl/core/layout/column_app_bar.dart';

import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import 'duo_geometry.dart';

// Renaud on 2026-10-27: on the foldable iPhone closed, a screen's back button
// belongs at the top of the vertical bar. The crawl must fail for a screen
// that leaves it in the corner, and accept one that moved it.

final _back = lookupAppLocalizations(kTestLocale).commonBack;

Widget _app(DuoPose pose, Widget page) =>
    MaterialApp(builder: duoAppBuilder(DuoPoseController(pose)), home: page);

Widget _cornerBack() => Scaffold(
  appBar: AppBar(
    leading: IconButton(
      tooltip: _back,
      icon: const Icon(Icons.arrow_back),
      onPressed: () {},
    ),
  ),
);

Widget _columnBack() => Scaffold(
  appBar: ColumnAppBar(
    appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: _back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    ),
  ),
);

Widget _untitledArrow() => Scaffold(
  appBar: AppBar(
    leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
  ),
);

Widget _handMadeBack() => Scaffold(
  body: Stack(
    fit: StackFit.expand,
    children: [
      Positioned(
        top: 8,
        left: 8,
        child: Tooltip(
          message: _back,
          child: GestureDetector(onTap: () {}, child: const Icon(Icons.close)),
        ),
      ),
      BarNavigation(buttons: const [], inline: const SizedBox.shrink()),
    ],
  ),
);

Future<List<String>> _problems(
  WidgetTester tester,
  DuoPose pose,
  Widget page,
) async {
  setDuoPose(tester, pose);
  await tester.pumpWidget(_app(pose, page));
  await tester.pumpAndSettle();
  return navigationOutsideColumnProblems(tester, pose);
}

void main() {
  for (final pose in [
    DuoPose.closed,
    DuoPose.tent,
    DuoPose.openLandscape,
    DuoPose.halfOpenBook,
  ]) {
    testWidgets('${pose.name}: a back button left in the corner is reported', (
      tester,
    ) async {
      final problems = await _problems(tester, pose, _cornerBack());
      expect(problems, hasLength(1), reason: '$problems');
      expect(problems.single, contains('navigation outside the vertical bar'));
    });

    testWidgets('${pose.name}: a hand-made back button is reported too', (
      tester,
    ) async {
      final problems = await _problems(tester, pose, _handMadeBack());
      expect(problems, hasLength(1), reason: '$problems');
    });

    testWidgets('${pose.name}: an arrow button without a tooltip is reported', (
      tester,
    ) async {
      final problems = await _problems(tester, pose, _untitledArrow());
      expect(problems, hasLength(1), reason: '$problems');
    });

    testWidgets('${pose.name}: a back button in the column is not', (
      tester,
    ) async {
      final problems = await _problems(tester, pose, _columnBack());
      expect(find.byTooltip(_back), findsOneWidget);
      expect(problems, isEmpty, reason: '$problems');
    });
  }

  testWidgets('without a vertical bar, nothing is asked', (tester) async {
    final problems = await _problems(
      tester,
      DuoPose.openPortrait,
      _cornerBack(),
    );
    expect(problems, isEmpty);
  });
}
