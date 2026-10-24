import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/chat/scam_rules.dart';

ScamKind? kindOf(String text, {int position = 0}) =>
    detectScam(text, position: position)?.kind;

void main() {
  group('argent et virements', () {
    for (final text in [
      'Peux-tu me faire un virement ?',
      'Je t\'envoie mon IBAN FR76 3000 6000 0112 3456 7890 189',
      'donne moi ton RIB',
      'J\'ai besoin d\'argent pour mon billet',
      'Peux-tu m\'envoyer de l\'argent ?',
      'envoie moi 200 euros par Western Union',
      'Prête-moi de l\'argent stp',
      'Can you send me money for the ticket?',
      'I need money urgently',
      'Please do a bank transfer',
      'wire me the money tonight',
      'Send me cash via MoneyGram',
    ]) {
      test('détecte : $text', () => expect(kindOf(text), ScamKind.money));
    }
  });

  group('cartes cadeaux', () {
    for (final text in [
      'Achète-moi une carte cadeau Amazon',
      'des cartes cadeaux iTunes',
      'Buy a gift card and send me the code',
      'Google Play gift-cards please',
    ]) {
      test('détecte : $text', () => expect(kindOf(text), ScamKind.giftCard));
    }
  });

  group('crypto et placements', () {
    for (final text in [
      'Je gagne beaucoup avec le bitcoin',
      'tu connais la crypto ?',
      'Investis en cryptomonnaie avec moi',
      'Je trade sur Binance',
      'Send USDT to my wallet',
      'BTC is going up',
    ]) {
      test('crypto : $text', () => expect(kindOf(text), ScamKind.crypto));
    }
    for (final text in [
      'J\'ai une opportunité d\'investissement incroyable',
      'rendement garanti de 30 % par mois',
      'I found an investment opportunity',
      'guaranteed returns every week',
      'Je fais du trading, ça rapporte',
      'tu veux doubler ton argent ?',
      'double your money in a week',
      'un revenu passif sans effort',
    ]) {
      test('placement : $text', () => expect(kindOf(text), ScamKind.investment));
    }
  });

  group('sortie de la plateforme tôt dans la conversation', () {
    for (final text in [
      'On continue sur WhatsApp ?',
      'Ajoute-moi sur Telegram',
      'tu as whats app ?',
      'Mon numéro : 06 12 34 56 78',
      'Appelle-moi au +33 6 12 34 56 78',
      'Add me on Signal',
      'tu peux m\'écrire sur Signal ?',
      'Let\'s move to WhatsApp, this app is slow',
      'Do you have Signal?',
      'text me on 0612345678',
      'Passe-moi ton numéro de téléphone',
      'give me your number',
      'viber ?',
    ]) {
      test('détecte : $text', () => expect(kindOf(text, position: 2), ScamKind.offPlatform));
    }

    test('plus tard dans la conversation, ce n\'est plus un signal', () {
      expect(kindOf('On continue sur WhatsApp ?', position: scamEarlyMessageCount), isNull);
      expect(kindOf('On continue sur WhatsApp ?', position: scamEarlyMessageCount - 1), ScamKind.offPlatform);
      expect(kindOf('Mon numéro : 06 12 34 56 78', position: 80), isNull);
    });

    test('l\'argent reste un signal à tout moment', () {
      expect(kindOf('envoie moi un virement', position: 500), ScamKind.money);
    });
  });

  group('insensible aux accents, à la casse et aux apostrophes typographiques', () {
    test('majuscules', () => expect(kindOf('VIREMENT URGENT'), ScamKind.money));
    test('accents', () => expect(kindOf('Prête-moi de l’argent'), ScamKind.money));
    test('sans accent ni apostrophe', () => expect(kindOf('pret moi de l argent'), ScamKind.money));
    test('besoin d’argent typographique', () => expect(kindOf('J’ai besoin d’argent'), ScamKind.money));
  });

  group('aucun faux positif', () {
    for (final text in [
      'Je t\'ai envoyé un télégramme, hihi', // télégramme ≠ telegram
      'Telegramme reçu',
      'Il est argentin',
      'Je t\'envoie une photo argentique',
      'Elle m\'a envoyé l\'argentier du roi, haha',
      'Mon grand-père vient d\'Argentine',
      'J\'adore l\'argent comme couleur de bague',
      'Quel signal fort, ce wifi !',
      'Le signal est mauvais ici',
      'Tu fais de la cryptographie ?',
      'Je travaille dans la banque',
      'On se voit jeudi à 20 h ?',
      'Mon anniversaire est le 12 03 1995',
      'La date est 2026-10-23',
      'Je suis né en 1995, et toi ?',
      'Salut ! Comment ça va ?',
      'J\'aime voyager et la cuisine',
      'Un café, ça te dit ?',
      'Shabbat shalom !',
      'I love hiking on weekends',
      'The signal was great on the hike',
      'My sister lives in Argentina',
      'Tu es très virile',
      'On pourrait investir du temps dans nous deux',
      'C\'est un trading card game ?',
    ]) {
      test('ne signale pas : $text', () {
        expect(detectScam(text, position: 0), isNull);
      });
    }
  });

  test('un texte vide ne signale rien', () {
    expect(detectScam('', position: 0), isNull);
    expect(detectScam('   ', position: 0), isNull);
  });

  test('le signal ne renvoie pas le texte du message', () {
    final signal = detectScam('Envoie un virement', position: 0)!;
    expect(signal.toString().toLowerCase().contains('envoie un'), isFalse);
  });
}
