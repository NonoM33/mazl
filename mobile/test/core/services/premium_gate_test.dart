import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/premium_gate.dart';
import 'package:mazl/core/services/store/credits_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/l10n_helpers.dart';
import '../../support/credits_fakes.dart';

void main() {
  late CreditsService credits;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PremiumGate.resetForTest();
    credits = installTestCredits();
  });

  tearDown(PremiumGate.resetForTest);

  group('likes quotidiens gratuits', () {
    test('un utilisateur gratuit dispose de 10 likes par jour', () {
      expect(PremiumGate.freeLikesPerDay, 10);
      expect(PremiumGate.remainingFreeLikes, 10);
    });

    test('avec des likes restants : le like part et le compteur baisse', () {
      expect(PremiumGate.tryConsumeFreeLike(), isTrue);
      expect(PremiumGate.remainingFreeLikes, 9);
    });

    test('à 0 restant : le like est refusé et le compteur ne bouge plus', () {
      for (var i = 0; i < 10; i++) {
        expect(
          PremiumGate.tryConsumeFreeLike(),
          isTrue,
          reason: 'like ${i + 1}',
        );
      }
      expect(PremiumGate.remainingFreeLikes, 0);

      expect(PremiumGate.tryConsumeFreeLike(), isFalse);
      expect(PremiumGate.tryConsumeFreeLike(), isFalse);
      expect(PremiumGate.remainingFreeLikes, 0);
    });

    test('un utilisateur premium n\'est jamais bloqué', () {
      PremiumGate.debugPremiumOverride = true;
      for (var i = 0; i < 40; i++) {
        expect(PremiumGate.tryConsumeFreeLike(), isTrue);
      }
      expect(PremiumGate.remainingFreeLikes, -1);
    });
  });

  group('boosts et Super Likes : le solde du serveur', () {
    test('solde inconnu : rien n\'est accordé', () {
      expect(PremiumGate.remainingSuperLikes, 0);
      expect(PremiumGate.superLikesPerDay, 0);
      expect(PremiumGate.remainingBoosts, 0);
    });

    test('les compteurs lisent available et daily_allowance du serveur', () {
      credits.applyFromServer(serverCredits());

      expect(PremiumGate.remainingSuperLikes, 15);
      expect(PremiumGate.superLikesPerDay, 5);
      expect(PremiumGate.remainingBoosts, 2);
    });

    test('un nouveau solde du serveur se lit tout de suite', () {
      credits.applyFromServer(serverCredits());
      credits.applyFromServer(
        serverCredits(
          superLikeAllowance: 1,
          superLikeRemaining: 0,
          superLikePurchased: 0,
          boostRemaining: 0,
          boostPurchased: 0,
        ),
      );

      expect(PremiumGate.remainingSuperLikes, 0);
      expect(PremiumGate.superLikesPerDay, 1);
      expect(PremiumGate.remainingBoosts, 0);
    });

    test('être abonné ou non ne change rien : le serveur seul décide', () {
      credits.applyFromServer(
        serverCredits(superLikeRemaining: 0, superLikePurchased: 0),
      );
      PremiumGate.debugPremiumOverride = true;
      expect(PremiumGate.remainingSuperLikes, 0);
      PremiumGate.debugPremiumOverride = false;
      expect(PremiumGate.remainingSuperLikes, 0);
    });

    test('plus de compteur local ni de clé locale pour eux', () {
      final source = File(
        'lib/core/services/premium_gate.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('useSuperLike')));
      expect(source, isNot(contains('useBoost')));
      expect(source, isNot(contains('premium_gate_super_likes_used')));
      expect(source, isNot(contains('premium_gate_boosts_used')));
    });
  });

  group('guardLike', () {
    Future<void> pumpHost(WidgetTester tester, void Function(bool) onResult) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => onResult(PremiumGate.guardLike(context)),
                child: const Text('liker'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'à 0 restant : bloque, ne consomme rien et ouvre la fenêtre de limite',
      (tester) async {
        for (var i = 0; i < 10; i++) {
          PremiumGate.tryConsumeFreeLike();
        }
        bool? allowed;
        await pumpHost(tester, (value) => allowed = value);

        await tester.tap(find.text('liker'));
        await tester.pumpAndSettle();

        expect(allowed, isFalse);
        expect(PremiumGate.remainingFreeLikes, 0);
        expect(find.text('Vos likes du jour sont partis.'), findsOneWidget);
      },
    );

    testWidgets(
      'avec des likes restants : laisse passer, consomme un like, aucune fenêtre',
      (tester) async {
        bool? allowed;
        await pumpHost(tester, (value) => allowed = value);

        await tester.tap(find.text('liker'));
        await tester.pumpAndSettle();

        expect(allowed, isTrue);
        expect(PremiumGate.remainingFreeLikes, 9);
        expect(find.text('Vos likes du jour sont partis.'), findsNothing);
      },
    );

    testWidgets('premium : laisse passer sans fenêtre', (tester) async {
      PremiumGate.debugPremiumOverride = true;
      bool? allowed;
      await pumpHost(tester, (value) => allowed = value);

      await tester.tap(find.text('liker'));
      await tester.pumpAndSettle();

      expect(allowed, isTrue);
      expect(find.text('Vos likes du jour sont partis.'), findsNothing);
    });
  });
}
