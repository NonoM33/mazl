import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_spread.dart';
import 'package:mazl/core/layout/full_bleed.dart';

Widget _strip() => FullBleed(
  builder: (context, gutter) => SizedBox(
    height: 60,
    child: ListView(
      key: const Key('strip'),
      scrollDirection: Axis.horizontal,
      padding: gutter,
      children: [
        for (var i = 0; i < 10; i++)
          SizedBox(key: Key('tile$i'), width: 80, height: 60),
      ],
    ),
  ),
);

void main() {
  testWidgets('a FoldSpread row marked FullBleed runs to the edges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoldSpread(
            padding: const EdgeInsets.all(24),
            start: [const Text('Souvenirs', key: Key('title')), _strip()],
            end: const [],
          ),
        ),
      ),
    );

    final strip = tester.getRect(find.byKey(const Key('strip')));
    expect(strip.left, 0);
    expect(strip.right, 400);
    // The other rows keep the margin, and the strip lines up with them.
    expect(tester.getRect(find.byKey(const Key('title'))).left, 24);
    expect(tester.getRect(find.byKey(const Key('tile0'))).left, 24);
  });
}
