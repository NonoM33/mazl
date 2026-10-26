import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/layout/fold_state.dart';
import 'package:mazl/core/layout/orientation_policy.dart';

// An iPhone stays upright; the foldable iPhone also turns sideways, so that
// it can stand on a table like a tent (Apple asks for landscape there).

void main() {
  test('an iPhone without a hinge stays upright', () {
    expect(orientationsFor(FoldState.unknown), [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });

  test('the foldable iPhone turns sideways too, never upside down', () {
    final orientations = orientationsFor(
      const FoldState(hinge: HingeStatus.closed),
    );
    expect(orientations, contains(DeviceOrientation.landscapeLeft));
    expect(orientations, contains(DeviceOrientation.landscapeRight));
    expect(orientations, contains(DeviceOrientation.portraitUp));
    expect(orientations, isNot(contains(DeviceOrientation.portraitDown)));
  });

  testWidgets(
    'the policy is applied once the hinge is known, and again only if it changes',
    (tester) async {
      final applied = <List<DeviceOrientation>>[];
      Future<void> record(List<DeviceOrientation> value) async =>
          applied.add(value);
      Widget app(FoldState state) => FoldScope(
        state: state,
        child: OrientationPolicy(apply: record, child: const SizedBox()),
      );
      await tester.pumpWidget(app(FoldState.unknown));
      await tester.pumpWidget(app(const FoldState(hinge: HingeStatus.closed)));
      await tester.pumpWidget(
        app(const FoldState(hinge: HingeStatus.partiallyOpen)),
      );
      expect(applied, [
        orientationsFor(FoldState.unknown),
        orientationsFor(const FoldState(hinge: HingeStatus.closed)),
      ]);
    },
  );
}
