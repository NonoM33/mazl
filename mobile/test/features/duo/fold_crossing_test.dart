import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/duo_poses.dart';
import 'duo_geometry.dart';

// The fold of the book pose runs down x = 455.5 .. 495.5 (duo_poses.dart).

Future<List<String>> _problems(WidgetTester tester, Widget page) async {
  setDuoPose(tester, DuoPose.halfOpenBook);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  return foldCrossingProblems(tester, DuoPose.halfOpenBook);
}

void main() {
  testWidgets('a title centered across the window crosses the fold', (
    tester,
  ) async {
    final problems = await _problems(
      tester,
      const Center(child: Text('Découvrir les profils du jour')),
    );
    expect(problems, hasLength(1));
    expect(problems.single, contains('crosses the fold'));
  });

  testWidgets('a text on one page of the book does not', (tester) async {
    final problems = await _problems(
      tester,
      const Align(alignment: Alignment.centerLeft, child: Text('Gauche')),
    );
    expect(problems, isEmpty);
  });

  testWidgets('a short word at the start of a full-width line does not', (
    tester,
  ) async {
    final problems = await _problems(
      tester,
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text('Kashrout')],
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets('a list scrolling down the fold does not excuse its rows', (
    tester,
  ) async {
    final problems = await _problems(
      tester,
      ListView(
        children: [
          for (var i = 0; i < 3; i++)
            ListTile(title: Text('Rangée $i'), onTap: () {}),
        ],
      ),
    );
    expect(problems, isNotEmpty);
  });

  testWidgets('a carousel scrolling across the fold excuses its cards', (
    tester,
  ) async {
    final problems = await _problems(
      tester,
      SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < 6; i++)
              const SizedBox(width: 180, child: Text('Carte du carrousel')),
          ],
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets('nothing is checked without a fold', (tester) async {
    setDuoPose(tester, DuoPose.openLandscape);
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: Text('Plein écran ouvert'))),
    );
    expect(foldCrossingProblems(tester, DuoPose.openLandscape), isEmpty);
  });
}
