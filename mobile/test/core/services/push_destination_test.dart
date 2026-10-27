import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/push_destination.dart';

// Correspondance type -> écran, écrite depuis docs/launch/V1-CONTRAT.md §1
// (tableau « l'app ouvre »), pas depuis le code :
//
//   new_match        conversation_id présent -> /chat/<id>, sinon /matches
//   new_message      -> /chat/<conversation_id>
//   couple_request   -> /couple/space
//   couple_question  -> /couple/space
//   couple_accepted  -> /couple/space (complément du coordinateur, sans autre champ)
//   new_like         -> /likes
//   super_like       -> /likes
//   boost_ended      -> /boost
//   data.screen "boost" (Boost programmé démarré) -> /boost, quel que soit le type
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

    test(
      '« Boost programmé démarré » (data.screen = boost) ouvre le Boost',
      () {
        expect(pushDestination({'screen': 'boost'}), '/boost');
        expect(
          pushDestination({
            'type': 'boost_scheduled_started',
            'screen': 'boost',
          }),
          '/boost',
        );
      },
    );

    test('un autre écran demandé par la notification ne mène nulle part', () {
      // Seule la route connue est reconstruite ; jamais copiée du message.
      expect(pushDestination({'screen': 'admin'}), isNull);
      expect(pushDestination({'screen': '/boost'}), isNull);
      expect(pushDestination({'screen': 42}), isNull);
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
    test('une demande de couple ouvre l\'espace couple', () {
      expect(pushDestination({'type': 'couple_request'}), '/couple/space');
    });

    test('la question du jour ouvre l\'espace couple', () {
      expect(pushDestination({'type': 'couple_question'}), '/couple/space');
    });

    test(
      'une demande acceptée ouvre l\'espace couple (ajout au contrat §1)',
      () {
        expect(pushDestination({'type': 'couple_accepted'}), '/couple/space');
      },
    );
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
        '/couple/space',
      );
    });
  });
}
