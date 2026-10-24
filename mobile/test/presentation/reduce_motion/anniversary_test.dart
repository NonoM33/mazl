import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/couple_anniversary.dart';
import 'package:mazl/presentation/features/couple/widgets/anniversary_widget.dart';

import '../../support/reduce_motion_support.dart';

// Anniversary dialog: the elastic pop becomes, at most, a short fade.

void main() {
  group('anniversary dialog', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        reduceMotionApp(
          home: Scaffold(
            body: AnniversaryCelebrationDialog(
              anniversaryData: CoupleAnniversaryData(
                matchDate: DateTime(2026, 1, 1),
                daysTogether: 100,
                partnerName: 'Jeanne Exemple',
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Reduce Motion on: no pop, at most a short fade', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await openDialog(tester);
      final card = find.text('Joyeux anniversaire');

      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(displacementsOf(card), isEmpty, reason: 'frame $frame');
      }
      await tester.pump(const Duration(milliseconds: 50));
      expect(fadeOf(card), 1.0);
    });

    testWidgets('Reduce Motion off: the card pops in with a bounce', (
      tester,
    ) async {
      await openDialog(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(displacementsOf(find.text('Joyeux anniversaire')), isNotEmpty);
    });
  });
}
