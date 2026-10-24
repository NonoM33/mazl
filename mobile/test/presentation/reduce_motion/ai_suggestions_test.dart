import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/ai_shadchan/screens/ai_suggestions_screen.dart';

import '../../support/reduce_motion_support.dart';

// AI suggestions header: the robot no longer bounces in under
// « Réduire les animations ».

void main() {
  group('AI suggestions header', () {
    Future<void> openScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        reduceMotionApp(home: const AISuggestionsScreen()),
      );
    }

    testWidgets('Reduce Motion on: the robot does not bounce in', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await openScreen(tester);

      expect(await displacementsWhilePlaying(tester, find.text('🤖')), isEmpty);
    });

    testWidgets('Reduce Motion off: the robot bounces in', (tester) async {
      await openScreen(tester);

      expect(
        await displacementsWhilePlaying(tester, find.text('🤖')),
        isNotEmpty,
      );
    });
  });
}
