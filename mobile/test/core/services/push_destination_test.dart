import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/push_destination.dart';

// Correspondance type -> écran, écrite depuis docs/launch/V1-CONTRAT.md §1
// (tableau « l'app ouvre »), pas depuis le code :
//
//   new_match        conversation_id présent -> /chat/<id>, sinon /matches
//   new_message      -> /chat/<conversation_id>
//   couple_request   -> /couple/today
//   couple_accepted  -> /couple/today (complément du coordinateur, sans autre champ)
// et docs/couple/ESPACE-COUPLE.md §8 :
//   couple_reminder  -> /couple/agenda
//   couple_question  -> /couple/us
//   couple_concierge -> /couple/concierge
//   new_like         -> /likes
//   super_like       -> /likes
//   boost_ended      -> /boost
//   event_available  -> /events/<event_id>, sinon /events
//   event_opened     -> idem (type des faux événements « Bientôt disponible »)
//   admin_test       -> rien
void main() {
  group('likes et Boost', () {
    test('un like ou un super like ouvre les likes reçus', () {
      expect(pushDestination({'type': 'new_like'}), '/likes');
      expect(pushDestination({'type': 'super_like'}), '/likes');
    });

    test('la fin d\'un Boost ouvre le Boost', () {
      expect(pushDestination({'type': 'boost_ended'}), '/boost');
    });
  });

  group('événement disponible', () {
    test('ouvre l\'événement, pour les deux types', () {
      for (final type in ['event_available', 'event_opened']) {
        expect(pushDestination({'type': type, 'event_id': 12}), '/events/12');
        expect(pushDestination({'type': type, 'event_id': '12'}), '/events/12');
      }
    });

    test('sans identifiant exploitable : la liste des événements', () {
      expect(pushDestination({'type': 'event_available'}), '/events');
      expect(
        pushDestination({'type': 'event_opened', 'event_id': '12/../premium'}),
        '/events',
      );
      expect(
        pushDestination({'type': 'event_available', 'event_id': 0}),
        '/events',
      );
    });

    test('la push de test d\'un administrateur n\'ouvre rien', () {
      expect(pushDestination({'type': 'admin_test'}), isNull);
    });
  });

  group('new_match', () {
    test('avec la conversation : ouvre la conversation', () {
      expect(
        pushDestination({
          'type': 'new_match',
          'match_user_id': 7,
          'conversation_id': 41,
        }),
        '/chat/41',
      );
    });

    test('sans conversation : ouvre la liste des matchs', () {
      expect(
        pushDestination({'type': 'new_match', 'match_user_id': 7}),
        '/matches',
      );
    });

    test('conversation_id nul : même chose, la liste des matchs', () {
      expect(
        pushDestination({
          'type': 'new_match',
          'match_user_id': 7,
          'conversation_id': null,
        }),
        '/matches',
      );
    });
  });

  group('new_message', () {
    test('ouvre la conversation', () {
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': 41}),
        '/chat/41',
      );
    });

    test('un nombre arrivé en décimal ou en texte est le même nombre', () {
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': 41.0}),
        '/chat/41',
      );
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': '41'}),
        '/chat/41',
      );
    });

    test('sans identifiant exploitable : la liste des conversations', () {
      expect(pushDestination({'type': 'new_message'}), '/chat');
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': 0}),
        '/chat',
      );
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': -3}),
        '/chat',
      );
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': 4.5}),
        '/chat',
      );
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': 'abc'}),
        '/chat',
      );
    });

    test('un identifiant n\'est jamais recopié dans le chemin tel quel', () {
      expect(
        pushDestination({
          'type': 'new_message',
          'conversation_id': '41/../../premium',
        }),
        '/chat',
      );
      expect(
        pushDestination({'type': 'new_message', 'conversation_id': '4 1'}),
        '/chat',
      );
    });
  });

  group('couple', () {
    test('une demande de couple ouvre le jour du couple', () {
      expect(pushDestination({'type': 'couple_request'}), '/couple/today');
    });

    test('une demande acceptée ouvre le jour du couple', () {
      expect(pushDestination({'type': 'couple_accepted'}), '/couple/today');
    });

    test('un rappel ouvre l\'agenda', () {
      expect(pushDestination({'type': 'couple_reminder'}), '/couple/agenda');
    });

    test('la question du jour ouvre « Nous deux »', () {
      expect(pushDestination({'type': 'couple_question'}), '/couple/us');
    });

    test('un message de la conciergerie ouvre la conciergerie', () {
      expect(
        pushDestination({'type': 'couple_concierge'}),
        '/couple/concierge',
      );
    });
  });

  group('anciens et inconnus : aucune navigation, aucun plantage', () {
    test('event_reminder, l\'ancien type, n\'ouvre rien', () {
      expect(
        pushDestination({'type': 'event_reminder', 'eventId': 12}),
        isNull,
      );
    });

    test('type inconnu, absent ou mal typé', () {
      expect(pushDestination({'type': 'super_nouveaute'}), isNull);
      expect(pushDestination(const {}), isNull);
      expect(pushDestination({'type': null}), isNull);
      expect(pushDestination({'type': 42}), isNull);
      expect(pushDestination({'type': ''}), isNull);
    });

    test('un champ en trop ne change rien', () {
      expect(
        pushDestination({
          'type': 'couple_question',
          'eventId': 3,
          'extra': {'a': 1},
        }),
        '/couple/us',
      );
    });
  });
}
