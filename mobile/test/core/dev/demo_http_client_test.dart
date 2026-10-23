import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/dev_session.dart';

void main() {
  tearDown(DevSession.stop);

  group('DemoHttpClient', () {
    test('session inactive : transmet la requête au client interne', () async {
      final seen = <http.BaseRequest>[];
      final inner = MockClient((request) async {
        seen.add(request);
        return http.Response('{"success":true,"from":"inner"}', 200);
      });
      final client = DemoHttpClient(inner, latency: Duration.zero);

      final response = await client.get(
        Uri.parse('https://api.example.com/api/discover'),
      );

      expect(seen, hasLength(1));
      expect(seen.single.url.path, '/api/discover');
      expect(jsonDecode(response.body)['from'], 'inner');
    });

    test('session active : le client interne n\'est JAMAIS appelé', () async {
      var calls = 0;
      final inner = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });
      final client = DemoHttpClient(inner, latency: Duration.zero);
      DevSession.start();

      final reads = [
        '/api/discover?limit=20&offset=0',
        '/api/matches',
        '/api/conversations',
        '/api/inconnu',
      ];
      for (final path in reads) {
        await client.get(Uri.parse('https://api.example.com$path'));
      }
      await client.post(
        Uri.parse('https://api.example.com/api/swipes'),
        body: jsonEncode({'target_user_id': 1, 'action': 'like'}),
      );
      await client.put(
        Uri.parse('https://api.example.com/api/profile'),
        body: '{}',
      );
      await client.delete(Uri.parse('https://api.example.com/api/users/me'));

      expect(calls, 0);
    });

    test(
      'session active : sert les données fictives en JSON, hôte ignoré',
      () async {
        final client = DemoHttpClient(
          MockClient((_) async => fail('ne doit pas être appelé')),
          latency: Duration.zero,
        );
        DevSession.start();

        final response = await client.get(
          Uri.parse('https://autre-hote.test/api/matches'),
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], contains('application/json'));
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['matches'], isNotEmpty);
      },
    );

    test('route inconnue : 503 JSON explicite', () async {
      final client = DemoHttpClient(
        MockClient((_) async => fail('ne doit pas être appelé')),
        latency: Duration.zero,
      );
      DevSession.start();

      final response = await client.get(
        Uri.parse('https://api.example.com/api/rien-du-tout'),
      );

      expect(response.statusCode, 503);
      expect(response.headers['content-type'], contains('application/json'));
      expect(jsonDecode(response.body), {
        'success': false,
        'error': 'Mode démo : indisponible',
      });
    });

    test(
      'une méthode non prévue sur une route connue rend aussi 503',
      () async {
        final client = DemoHttpClient(
          MockClient((_) async => fail('ne doit pas être appelé')),
          latency: Duration.zero,
        );
        DevSession.start();

        final response = await client.delete(
          Uri.parse('https://api.example.com/api/discover'),
        );

        expect(response.statusCode, 503);
      },
    );

    test('répond après une latence d\'environ 200 ms par défaut', () async {
      final client = DemoHttpClient(MockClient((_) async => fail('interdit')));
      DevSession.start();

      final watch = Stopwatch()..start();
      await client.get(Uri.parse('https://api.example.com/api/matches'));

      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(180));
    });

    test(
      'après stop() la session ne répond plus : retour au client interne',
      () async {
        var calls = 0;
        final client = DemoHttpClient(
          MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
          latency: Duration.zero,
        );
        DevSession.start();
        DevSession.stop();

        await client.get(Uri.parse('https://api.example.com/api/matches'));

        expect(calls, 1);
      },
    );
  });

  group('écritures', () {
    late DemoHttpClient client;
    setUp(() {
      client = DemoHttpClient(
        MockClient((_) async => fail('ne doit pas être appelé')),
        latency: Duration.zero,
      );
      DevSession.start();
    });

    Future<Map<String, dynamic>> post(
      String path,
      Map<String, dynamic> body,
    ) async {
      final r = await client.post(
        Uri.parse('https://api.example.com$path'),
        body: jsonEncode(body),
      );
      return jsonDecode(r.body) as Map<String, dynamic>;
    }

    test(
      'un message envoyé est renvoyé avec un nouvel identifiant et relu',
      () async {
        final sent = await post('/api/conversations/101/messages', {
          'content': 'Bonjour depuis la démo',
        });
        final message = sent['message'] as Map<String, dynamic>;
        expect(message['content'], 'Bonjour depuis la démo');
        expect(message['id'], isNot(0));

        final reread = await client.get(
          Uri.parse('https://api.example.com/api/conversations/101/messages'),
        );
        final messages = jsonDecode(reread.body)['messages'] as List;
        expect((messages.first as Map)['id'], message['id']);
      },
    );

    test('un like ne matche pas, sauf le profil prévu pour la démo', () async {
      final plain = await post('/api/swipes', {
        'target_user_id': 202,
        'action': 'like',
      });
      expect(plain['match'], isFalse);
      expect(plain['matched'], isFalse);

      final special = await post('/api/swipes', {
        'target_user_id': 201,
        'action': 'like',
      });
      expect(special['match'], isTrue);
      expect(special['matched'], isTrue);

      final pass = await post('/api/swipes', {
        'target_user_id': 201,
        'action': 'pass',
      });
      expect(pass['match'], isFalse);
    });

    test('marquer comme lu vide le compteur de la conversation', () async {
      await client.put(
        Uri.parse('https://api.example.com/api/conversations/101/read'),
        body: '{}',
      );
      final r = await client.get(
        Uri.parse('https://api.example.com/api/conversations'),
      );
      final conv = (jsonDecode(r.body)['conversations'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['id'] == 101);
      expect(conv['unreadCount'], 0);
    });

    test('RSVP : succès puis statut relu sur l\'évènement', () async {
      final ok = await post('/api/events/2/rsvp', {'status': 'going'});
      expect(ok['success'], isTrue);
      final r = await client.get(
        Uri.parse('https://api.example.com/api/events/2'),
      );
      expect(jsonDecode(r.body)['event']['user_rsvp_status'], 'going');
    });
  });
}
