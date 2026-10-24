import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazl/core/models/profile_prompt.dart';
import 'package:mazl/presentation/features/profile/widgets/profile_prompts_display.dart';

import '../../support/reduce_motion_support.dart';

// Like button of a profile prompt: no press scale under
// « Réduire les animations », and the like still goes through.

void main() {
  group('prompt like button', () {
    final prompt = ProfilePrompt(
      id: 1,
      promptId: 'sunday',
      promptText: 'Un dimanche idéal',
      answer: 'Marché puis lecture',
      position: 1,
    );

    /// Presses the like heart, reports how it moved while pressed and
    /// how many likes went through.
    Future<({List<String> whilePressed, int likes})> pressLike(
      WidgetTester tester,
    ) async {
      var likes = 0;
      await tester.pumpWidget(
        reduceMotionApp(
          home: Scaffold(
            body: ProfilePromptsDisplay(
              prompts: [prompt],
              onLikePrompt: (_) => likes++,
            ),
          ),
        ),
      );
      final heart = find.byType(GestureDetector).last;
      await tester.tap(heart);
      await tester.pump(); // the tap starts the press animation
      await tester.pump(const Duration(milliseconds: 60));
      final whilePressed = displacementsOf(find.byIcon(LucideIcons.heart));
      await tester.pump(const Duration(milliseconds: 400));
      return (whilePressed: whilePressed, likes: likes);
    }

    testWidgets('Reduce Motion on: no press scale, the like goes through', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      final result = await pressLike(tester);

      expect(result.whilePressed, isEmpty);
      expect(result.likes, 1);
    });

    testWidgets('Reduce Motion off: the heart shrinks while pressed', (
      tester,
    ) async {
      final result = await pressLike(tester);

      expect(result.whilePressed, isNotEmpty);
      expect(result.likes, 1);
    });
  });
}
