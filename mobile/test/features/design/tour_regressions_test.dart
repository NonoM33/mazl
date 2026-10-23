// Non-régression des défauts vus pendant la visite au simulateur du 2026-10-23.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/core/models/conversation.dart';
import 'package:mazl/core/models/profile_labels.dart';
import 'package:mazl/core/services/push_permission.dart';
import 'package:mazl/presentation/features/chat/conversation_lookup.dart';
import 'package:mazl/presentation/features/chat/conversation_time.dart';

Conversation _conv(int id, int userId, {int unread = 0}) => Conversation(
      id: id,
      matchId: id,
      unreadCount: unread,
      otherUser: ConversationUser(userId: userId, displayName: 'Personne $userId'),
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('puces de profil : jamais de valeur brute de l\'API', () {
    test('les valeurs vues au simulateur deviennent des libellés français', () {
      expect(ProfileLabels.kashrut('A la maison'), 'Cacher à la maison');
      expect(ProfileLabels.kashrut('kasher_a_la_maison'), 'Cacher à la maison');
      expect(ProfileLabels.shabbat('Partiellement'), 'Shabbat en partie');
      expect(ProfileLabels.intention('serious'), 'Relation sérieuse');
      expect(ProfileLabels.intention('marriage'), 'Mariage');
    });

    test('formats historiques, casse et accents indifférents', () {
      expect(ProfileLabels.denomination('Laique'), 'Laïque');
      expect(ProfileLabels.denomination('modern_orthodox'), 'Orthodoxe moderne');
      expect(ProfileLabels.denomination('ORTHODOX'), 'Orthodoxe');
      expect(ProfileLabels.shabbat('Tres observant'), 'Shabbat strict');
      expect(ProfileLabels.shabbat('shabbat_en_famille'), 'Shabbat en famille');
      expect(ProfileLabels.kashrut('Glatt'), 'Glatt cacher');
    });

    test('« Non », « Autre » ou vide ne font pas de puce', () {
      expect(ProfileLabels.kashrut('Non'), isNull);
      expect(ProfileLabels.denomination('Autre'), isNull);
      expect(ProfileLabels.shabbat('  '), isNull);
      expect(ProfileLabels.intention(null), isNull);
    });

    test('une valeur inconnue reste lisible (espaces, majuscule), jamais avec des _', () {
      expect(ProfileLabels.denomination('reconstructionist_jew'), 'Reconstructionist jew');
    });
  });

  group('heure d\'une conversation en français', () {
    final now = DateTime(2026, 10, 23, 20, 30); // un vendredi

    test('aujourd\'hui : heure', () {
      expect(formatConversationTime(DateTime(2026, 10, 23, 9, 5), now), '09:05');
    });

    test('hier', () {
      expect(formatConversationTime(DateTime(2026, 10, 22, 18), now), 'Hier');
    });

    test('cette semaine : jour abrégé en français, jamais « Tue »', () {
      final tuesday = DateTime(2026, 10, 20, 12);
      final label = formatConversationTime(tuesday, now);
      expect(label, 'Mar.');
      expect(label, isNot(contains('Tue')));
    });

    test('plus ancien : date en français, jamais « Oct 15 »', () {
      final label = formatConversationTime(DateTime(2026, 10, 15, 12), now);
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
}
