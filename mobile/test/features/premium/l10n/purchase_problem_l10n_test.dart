import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/subscription_models.dart';
import 'package:mazl/l10n/generated/app_localizations.dart';
import 'package:mazl/presentation/features/premium/l10n/plus_text.dart';

// What the member reads for every reason a purchase can fail. The core only
// returns the reason; these are the sentences.
const _french = {
  PurchaseProblem.purchaseInProgress: 'Un achat est déjà en cours.',
  PurchaseProblem.androidSoon: 'Bientôt disponible sur Android',
  PurchaseProblem.ownedByAnotherAccount:
      'Cet achat App Store est déjà associé à un autre compte mazl.',
  PurchaseProblem.invalidTransaction:
      'Nous n’avons pas pu valider cet achat auprès de l’App Store. '
      'Il sera revérifié au prochain lancement.',
  PurchaseProblem.invalidBody:
      'Votre achat n’a pas pu être transmis correctement. Réessayez dans un instant.',
  PurchaseProblem.signInAgain:
      'Reconnectez-vous à mazl pour finaliser votre achat.',
  PurchaseProblem.offline:
      'Connexion impossible. Votre achat est conservé et sera validé dès que possible.',
  PurchaseProblem.generic:
      'L’achat n’a pas pu aboutir. Réessayez dans un instant.',
  PurchaseProblem.inactive: 'Votre abonnement n’est pas actif.',
  PurchaseProblem.restoreFailed:
      'La restauration a échoué. Réessayez dans un instant.',
};

AppLocalizations _l10n(String code) => lookupAppLocalizations(Locale(code));

void main() {
  test('French keeps the sentences of the core, word for word', () {
    final fr = _l10n('fr');
    for (final problem in PurchaseProblem.values) {
      expect(
        purchaseProblemText(fr, problem),
        _french[problem],
        reason: '$problem',
      );
    }
  });

  test('every problem has a sentence of its own in every language', () {
    for (final code in ['en', 'he', 'es', 'ru']) {
      final l10n = _l10n(code);
      final sentences = <String>{};
      for (final problem in PurchaseProblem.values) {
        final text = purchaseProblemText(l10n, problem);
        expect(text, isNotEmpty, reason: '$code $problem');
        expect(
          text,
          isNot(_french[problem]),
          reason: '$code $problem is French',
        );
        sentences.add(text);
      }
      expect(sentences.length, PurchaseProblem.values.length, reason: code);
    }
  });

  test('English reads like English', () {
    final en = _l10n('en');
    expect(
      purchaseProblemText(en, PurchaseProblem.ownedByAnotherAccount),
      'This App Store purchase is already linked to another mazl account.',
    );
    expect(
      purchaseProblemText(en, PurchaseProblem.androidSoon),
      'Coming soon on Android',
    );
  });
}
