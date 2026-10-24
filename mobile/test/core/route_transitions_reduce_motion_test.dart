import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/router/route_transitions.dart';

import '../support/reduce_motion_support.dart';

// A page that arrives by sliding or scaling is the motion « Réduire les
// animations » exists to remove: under the setting the new page only fades in.

typedef _Builder =
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget);

const _incoming = Key('incoming-page');
const _outgoing = Key('outgoing-page');

final _moving = <String, _Builder>{
  'slideUpTransition': slideUpTransition,
  'slideLeftTransition': slideLeftTransition,
  'scaleTransition': scaleTransition,
  'heroTransition': heroTransition,
  'sharedAxisTransition': sharedAxisTransition,
};

/// Opens the incoming page with [builder] and stops halfway through.
Future<void> _openHalfway(WidgetTester tester, _Builder builder) async {
  await tester.pumpWidget(
    reduceMotionApp(home: const SizedBox(key: _outgoing)),
  );
  final context = tester.element(find.byKey(_outgoing));
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => const SizedBox(key: _incoming),
      transitionsBuilder: builder,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  for (final entry in _moving.entries) {
    group(entry.key, () {
      testWidgets('with Reduce Motion on, the page only fades in', (
        tester,
      ) async {
        setReduceMotion(tester, on: true);
        await _openHalfway(tester, entry.value);

        expect(displacementsOf(find.byKey(_incoming)), isEmpty);
        expect(
          fadeOf(find.byKey(_incoming)),
          allOf(greaterThan(0), lessThan(1)),
        );
      });

      testWidgets('without it, the page still moves or scales', (tester) async {
        await _openHalfway(tester, entry.value);

        expect(displacementsOf(find.byKey(_incoming)), isNotEmpty);
      });
    });
  }

  testWidgets('fadeTransition is untouched by the setting', (tester) async {
    setReduceMotion(tester, on: true);
    await _openHalfway(tester, fadeTransition);

    expect(displacementsOf(find.byKey(_incoming)), isEmpty);
    expect(fadeOf(find.byKey(_incoming)), allOf(greaterThan(0), lessThan(1)));
  });
}
