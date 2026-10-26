import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/presentation/common/widgets/mazl_components.dart';

void main() {
  testWidgets(
    'a round button drawn at 40 pt still answers a tap on 44 x 44 pt',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoundIconButton(
                key: const Key('back'),
                icon: LucideIcons.arrowLeft,
                tooltip: 'Retour',
                size: 40,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      final target = tester.getRect(find.byKey(const Key('back')));
      expect(target.size, const Size.square(44));
      // Near each corner of the 44 pt square, outside the 40 pt circle.
      for (final point in [
        target.topLeft + const Offset(1, 1),
        target.bottomRight - const Offset(1, 1),
      ]) {
        await tester.tapAt(point);
      }
      expect(taps, 2);
    },
  );
}
