import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/observability/redaction.dart';

/// Ce qu'un message d'erreur ne doit jamais emporter hors du téléphone : une
/// adresse e-mail ou un jeton de session. Les exemples sont fictifs.
void main() {
  group('redactSensitive — adresses e-mail', () {
    test('masque une adresse dans une phrase', () {
      final out = redactSensitive(
        'Compte jeanne.exemple@example.com introuvable',
      );
      expect(out, isNot(contains('jeanne')));
      expect(out, isNot(contains('example.com')));
      expect(out, contains('Compte'));
      expect(out, contains('introuvable'));
    });

    test('masque une adresse avec « + » et un sous-domaine', () {
      final out = redactSensitive('to=jeanne+mazl@mail.exemple.example.org;');
      expect(out, isNot(contains('jeanne')));
      expect(out, isNot(contains('exemple.example.org')));
    });

    test('masque chaque adresse quand il y en a plusieurs', () {
      final out = redactSensitive('a@example.com puis b@example.net');
      expect(out, isNot(contains('@')));
    });
  });

  group('redactSensitive — jetons', () {
    const jwt =
        'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJlRmljdGlmMTIz';

    test('masque un JWT nu', () {
      final out = redactSensitive('Réponse 401 pour $jwt');
      expect(out, isNot(contains('eyJ')));
      expect(out, isNot(contains('c2lnbmF0dXJl')));
    });

    test('masque la valeur après « Bearer »', () {
      final out = redactSensitive('Authorization: Bearer abc123def456');
      expect(out, isNot(contains('abc123def456')));
    });

    test('masque les paires clé=valeur ou clé: valeur sensibles', () {
      for (final input in <String>[
        'GET /x?token=abcd1234efgh',
        '{"access_token":"abcd1234efgh"}',
        'id_token: abcd1234efgh',
        'refresh_token = abcd1234efgh',
        'password=abcd1234efgh',
        'api_key=abcd1234efgh',
        'secret: abcd1234efgh',
      ]) {
        expect(
          redactSensitive(input),
          isNot(contains('abcd1234efgh')),
          reason: input,
        );
      }
    });

    test('masque une longue chaîne opaque (jeton sans libellé)', () {
      final opaque = 'a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8s9T0uV';
      expect(redactSensitive('clé $opaque reçue'), isNot(contains(opaque)));
    });
  });

  group('redactSensitive — ce qui doit rester lisible', () {
    test('laisse intacts les diagnostics ordinaires', () {
      for (final input in <String>[
        'Bad state: No element',
        'SocketException: Connection refused (OS Error: Connection refused, '
            'errno = 61), address = api.mazl.app, port = 443',
        "type 'Null' is not a subtype of type 'String' in type cast",
        'RangeError (index): Invalid value: Not in inclusive range 0..2: 5',
      ]) {
        expect(redactSensitive(input), input);
      }
    });

    test('une chaîne vide reste vide', () {
      expect(redactSensitive(''), '');
    });
  });

  group('redactSensitiveOrNull', () {
    test('garde null', () => expect(redactSensitiveOrNull(null), isNull));
    test('masque sinon', () {
      expect(redactSensitiveOrNull('x@example.com'), isNot(contains('@')));
    });
  });
}
