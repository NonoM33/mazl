import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/auth/screens/email_auth_screen.dart';

import '../../support/reduce_motion_support.dart';

// Email sign-in: no slide on the title and form, no shake on the error under
// « Réduire les animations ».

void main() {
  group('email sign-in', () {
    Future<void> openScreen(WidgetTester tester, {bool isLogin = true}) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: reduceMotionApp(home: EmailAuthScreen(isLogin: isLogin)),
        ),
      );
    }

    testWidgets('Reduce Motion on: the title does not slide up', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await openScreen(tester);

      expect(
        await displacementsWhilePlaying(tester, find.text('Connexion')),
        isEmpty,
      );
      expect(
        await displacementsWhilePlaying(tester, find.text('Se connecter')),
        isEmpty,
      );
    });

    testWidgets('Reduce Motion off: the title slides up', (tester) async {
      await openScreen(tester);

      expect(
        await displacementsWhilePlaying(tester, find.text('Connexion')),
        isNotEmpty,
      );
    });

    Future<void> failSignUp(WidgetTester tester) async {
      await openScreen(tester, isLogin: false);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jeanne');
      await tester.enterText(fields.at(1), 'jeanne@example.com');
      await tester.enterText(fields.at(2), 'Motdepasse1');
      await tester.enterText(fields.at(3), 'Motdepasse1');
      await tester.tap(find.text('Créer mon compte'));
      await tester.pump(); // builds the error block
    }

    testWidgets('Reduce Motion on: the error message does not shake', (
      tester,
    ) async {
      setReduceMotion(tester, on: true);
      await failSignUp(tester);

      final error = find.text(
        'Veuillez accepter les conditions d\'utilisation',
      );
      expect(error, findsOneWidget);
      expect(await displacementsWhilePlaying(tester, error), isEmpty);
    });

    testWidgets('Reduce Motion off: the error message shakes', (tester) async {
      await failSignUp(tester);

      final error = find.text(
        'Veuillez accepter les conditions d\'utilisation',
      );
      expect(error, findsOneWidget);
      expect(await displacementsWhilePlaying(tester, error), isNotEmpty);
    });
  });
}
