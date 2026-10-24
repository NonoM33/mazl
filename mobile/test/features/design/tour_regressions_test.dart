// Non-régression des défauts vus pendant la visite au simulateur du 2026-10-23.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/models/profile_labels.dart';
import 'package:mazl/core/models/relationship_intention.dart';
import 'package:mazl/core/services/push_permission.dart';
import 'package:mazl/presentation/features/chat/conversation_lookup.dart';
import 'package:mazl/presentation/features/chat/conversation_time.dart';
import 'package:mazl/presentation/features/profile/l10n/profile_answer_labels.dart';

import '../../helpers/l10n_helpers.dart';

Conversation _conv(int id, int userId, {int unread = 0}) => Conversation(
      id: id,
      matchId: id,
      unreadCount: unread,
      otherUser: ConversationUser(userId: userId, displayName: 'Personne $userId'),
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('puces de profil : jamais de valeur brute de l\'API', () {
    final l10n = lookupAppLocalizations(kTestLocale);
    String? kashrut(String? raw) => kashrutFact(l10n, raw);
    String? shabbat(String? raw) => shabbatFact(l10n, raw);
    String? denomination(String? raw) => denominationFact(l10n, raw);
    String? intention(String? raw) => intentionFact(l10n, raw);

    test('les valeurs vues au simulateur deviennent des libellés français', () {
      expect(kashrut('A la maison'), 'Cacher à la maison');
      expect(kashrut('kasher_a_la_maison'), 'Cacher à la maison');
      expect(shabbat('Partiellement'), 'Shabbat en partie');
      expect(intention('serious'), 'Relation sérieuse');
      expect(intention('marriage'), 'Mariage');
    });

    test('formats historiques, casse et accents indifférents', () {
      expect(denomination('Laique'), 'Laïque');
      expect(denomination('modern_orthodox'), 'Orthodoxe moderne');
      expect(denomination('ORTHODOX'), 'Orthodoxe');
      expect(shabbat('Tres observant'), 'Shabbat strict');
      expect(shabbat('shabbat_en_famille'), 'Shabbat en famille');
      expect(kashrut('Glatt'), 'Glatt cacher');
    });

    test('« Non », « Autre » ou vide ne font pas de puce', () {
      expect(kashrut('Non'), isNull);
      expect(denomination('Autre'), isNull);
      expect(shabbat('  '), isNull);
      expect(intention(null), isNull);
    });

    test('une valeur inconnue reste lisible (espaces, majuscule), jamais avec des _', () {
      expect(denomination('reconstructionist_jew'), 'Reconstructionist jew');
    });

    test('le cœur rend des types, pas des textes', () {
      expect(ProfileLabels.kashrutAnswer('A la maison')?.kind, Kashrut.home);
      expect(ProfileLabels.shabbatAnswer('Partiellement')?.kind, ShabbatObservance.partial);
      expect(ProfileLabels.denominationAnswer('Autre')?.isHidden, isTrue);
      expect(ProfileLabels.intentionAnswer('Relation serieuse')?.kind, RelationshipIntention.serious);
      expect(ProfileLabels.denominationAnswer('reconstructionist_jew')?.custom, 'Reconstructionist jew');
    });
  });

  group('heure d\'une conversation en français', () {
    final now = DateTime(2026, 10, 23, 20, 30); // un vendredi
    late AppLocalizations fr;

    setUpAll(() async {
      await initializeDateFormatting();
      fr = lookupAppLocalizations(const Locale('fr'));
    });

    test('aujourd\'hui : heure', () {
      expect(formatConversationTime(fr, DateTime(2026, 10, 23, 9, 5), now), '09:05');
    });

    test('hier', () {
      expect(formatConversationTime(fr, DateTime(2026, 10, 22, 18), now), 'Hier');
    });

    test('cette semaine : jour abrégé en français, jamais « Tue »', () {
      final tuesday = DateTime(2026, 10, 20, 12);
      final label = formatConversationTime(fr, tuesday, now);
      expect(label, 'Mar.');
      expect(label, isNot(contains('Tue')));
    });

    test('plus ancien : date en français, jamais « Oct 15 »', () {
      final label = formatConversationTime(fr, DateTime(2026, 10, 15, 12), now);
      expect(label, '15 oct.');
    });
  });

  group('après un match, « Envoyer un message » ouvre la conversation', () {
    test('trouve la conversation avec la personne matchée', () {
      final convs = [_conv(3, 10), _conv(7, 201), _conv(9, 12)];
      expect(conversationIdWith(convs, 201), 7);
    });

    test('aucune conversation encore créée : null (repli sur Messages)', () {
      expect(conversationIdWith([_conv(3, 10)], 201), isNull);
    });
  });

  group('une conversation ouverte n\'est plus marquée non lue', () {
    test('markConversationRead remet le compteur à zéro sans toucher aux autres', () {
      final convs = [_conv(1, 10, unread: 2), _conv(2, 11, unread: 1)];
      final updated = markConversationRead(convs, 1);
      expect(updated.firstWhere((c) => c.id == 1).unreadCount, 0);
      expect(updated.firstWhere((c) => c.id == 2).unreadCount, 1);
      expect(updated.firstWhere((c) => c.id == 1).otherUser?.userId, 10);
    });
  });

  group('notifications : pas de rappel « Open Settings » à chaque lancement', () {
    test('ne renvoie jamais vers les Réglages', () async {
      final calls = <bool>[];
      await askPushPermissionIfNeeded(
        canRequest: () async => true,
        request: (fallbackToSettings) async {
          calls.add(fallbackToSettings);
          return false;
        },
      );
      expect(calls, [false]);
    });

    test('déjà demandé (accepté ou refusé) : ne redemande pas', () async {
      var asked = false;
      await askPushPermissionIfNeeded(
        canRequest: () async => false,
        request: (_) async => asked = true,
      );
      expect(asked, isFalse);
    });
  });

  group('la liste Messages se recharge quand elle redevient visible', () {
    test('retour sur l\'onglet Messages depuis un autre onglet', () {
      expect(conversationListBecameVisible('/discover', '/chat'), isTrue);
    });

    test('retour depuis une conversation', () {
      expect(conversationListBecameVisible('/chat/106', '/chat'), isTrue);
    });

    test('déjà sur la liste, ou ailleurs : pas de rechargement', () {
      expect(conversationListBecameVisible('/chat', '/chat'), isFalse);
      expect(conversationListBecameVisible('/chat', '/chat/106'), isFalse);
      expect(conversationListBecameVisible('/chat', '/matches'), isFalse);
    });
  });
}
