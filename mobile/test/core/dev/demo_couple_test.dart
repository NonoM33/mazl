import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_fixtures.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rejoue les VRAIS décodeurs du mode couple (`ApiService`,
/// `CoupleApiService`, `CoupleService`) contre la démo, avec une horloge
/// factice : aucune attente réelle.
Future<T> _demo<T>(Future<T> Function() body) => http.runWithClient(
  body,
  () => DemoHttpClient(
    MockClient((r) async => fail('Réseau réel joint : ${r.url}')),
    latency: Duration.zero,
  ),
);

/// Appel brut du routeur : le statut HTTP et le JSON tels que les voit l'app.
({int status, Map<String, dynamic> json}) _call(
  String method,
  String path, {
  Map<String, dynamic> body = const {},
  Map<String, String> query = const {},
}) {
  final reply = DemoRoutes.respond(DemoRequest(method, path, query, body));
  return (
    status: reply.status,
    json: jsonDecode(reply.json) as Map<String, dynamic>,
  );
}

late DateTime _now;
void _advance(Duration by) => _now = _now.add(by);

Map<String, dynamic> _requestTo(int userId) {
  final reply = _call(
    'POST',
    '/api/couple/request',
    body: {'target_user_id': userId},
  );
  expect(reply.status, 200, reason: '${reply.json}');
  return reply.json['request'] as Map<String, dynamic>;
}

/// Envoie une demande à Noémie (301) et laisse passer les 3 s.
Map<String, dynamic> _enterCouple() {
  _requestTo(301);
  _advance(const Duration(seconds: 3));
  final couple = _call('GET', '/api/couple').json['couple'];
  expect(couple, isNotNull);
  return couple as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DevSession.start();
    _now = DateTime.now();
    DemoStore.clock = () => _now;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    DemoStore.clock = DateTime.now;
    DevSession.stop();
  });

  group('création du couple, avec consentement', () {
    test(
      'POST /api/couple ne crée plus rien : 403 couple_request_required',
      () {
        final reply = _call(
          'POST',
          '/api/couple',
          body: {'partnerId': 301, 'relationshipStatus': 'in_relationship'},
        );
        expect(reply.status, 403);
        expect(reply.json['success'], isFalse);
        expect(reply.json['error'], 'couple_request_required');
        expect(_call('GET', '/api/couple').json['couple'], isNull);
      },
    );

    test(
      'la demande part, reste en attente 3 s, puis le couple existe',
      () async {
        await _demo(() async {
          final api = ApiService();
          final sent = await api.sendCoupleRequest(301);
          expect(sent.success, isTrue, reason: sent.error);
          final request = sent.data!['request'] as Map<String, dynamic>;
          expect(request['requester_id'], DemoFixtures.meId);
          expect(request['target_id'], 301);
          expect(request['status'], 'pending');
          expect(request['target_name'], 'Noémie');
          expect(request['target_picture'], isNull);
          expect(DateTime.tryParse(request['created_at'] as String), isNotNull);

          _advance(const Duration(milliseconds: 2900));
          final waiting = (await api.getCoupleRequests()).data!;
          final pending = (waiting['sent'] as List)
              .cast<Map<String, dynamic>>();
          expect(pending, hasLength(1));
          expect(CoupleRequest.fromJson(pending.first).targetId, 301);
          expect((await api.getCoupleData()).data!['couple'], isNull);

          _advance(const Duration(milliseconds: 100));
          final accepted = (await api.getCoupleData()).data!;
          final couple = accepted['couple'] as Map<String, dynamic>;
          expect(couple['partner_id'], 301);
          expect(couple['partner_name'], 'Noémie');
          expect(couple['partner_picture'], isNull);
          expect(couple['status'], 'in_relationship');
          expect(DateTime.tryParse(couple['started_at'] as String), isNotNull);
          expect(
            DateTime.tryParse(couple['met_on_mazl_at'] as String),
            isNotNull,
          );
          expect(couple['id'], isA<int>());
          expect(accepted['milestones'], isEmpty);

          final after = (await api.getCoupleRequests()).data!;
          expect(after['sent'], isEmpty);
          expect(after['received'], isEmpty);
          expect((await api.isUserInCoupleMode(301)).data, isTrue);
          expect((await api.isUserInCoupleMode(302)).data, isFalse);
        });
      },
    );

    test('CoupleService relit le couple accepté au recalage', () async {
      await _demo(() async {
        final service = CoupleService();
        expect((await service.sendCoupleRequest(targetUserId: 302, targetName: 'Léa')).ok, isTrue);
        await service.refresh();
        expect(service.pendingRequest?.targetId, 302);

        _advance(const Duration(seconds: 3));
        await service.initialize();
        expect(service.isCoupleModeEnabled, isTrue);
        expect(service.coupleData?.partnerId, 302);
        expect(service.coupleData?.partnerName, isNotEmpty);
        expect(service.coupleData?.coupleId, isNotNull);

        expect((await service.leaveCouple()).ok, isTrue);
        expect(service.isCoupleModeEnabled, isFalse);
        expect(_call('GET', '/api/couple').json['couple'], isNull);
      });
    });

    test(
      'une demande à quelqu\'un qui n\'est pas un match : 403 not_matched',
      () {
        for (final stranger in [202, 999]) {
          final reply = _call(
            'POST',
            '/api/couple/request',
            body: {'target_user_id': stranger},
          );
          expect(reply.status, 403, reason: 'cible $stranger');
          expect(reply.json['error'], 'not_matched');
        }
        _advance(const Duration(minutes: 1));
        expect(_call('GET', '/api/couple').json['couple'], isNull);
        expect(_call('GET', '/api/couple/requests').json['sent'], isEmpty);
      },
    );

    test('un match ouvert pendant la session peut recevoir une demande', () {
      _call(
        'POST',
        '/api/swipes',
        body: {
          'target_user_id': DemoFixtures.matchOnLikeUserId,
          'action': 'like',
        },
      );
      final request = _requestTo(DemoFixtures.matchOnLikeUserId);
      expect(request['target_id'], DemoFixtures.matchOnLikeUserId);
    });

    test(
      'règles de la demande : cible absente, soi-même, doublon, déjà en couple',
      () {
        expect(
          _call('POST', '/api/couple/request').status,
          400,
          reason: 'target_user_id manquant',
        );
        final self = _call(
          'POST',
          '/api/couple/request',
          body: {'target_user_id': DemoFixtures.meId},
        );
        expect(self.status, 400);
        _requestTo(301);
        final twice = _call(
          'POST',
          '/api/couple/request',
          body: {'target_user_id': 301},
        );
        expect(twice.status, 400);
        expect(twice.json['error'], contains('pending'));
        _advance(const Duration(seconds: 3));
        final coupled = _call(
          'POST',
          '/api/couple/request',
          body: {'target_user_id': 302},
        );
        expect(coupled.status, 400);
        expect(coupled.json['error'], contains('already in a couple'));
      },
    );

    test(
      'annuler la demande avant les 3 s : plus de demande, pas de couple',
      () async {
        await _demo(() async {
          final api = ApiService();
          final id = _requestTo(301)['id'] as int;
          _advance(const Duration(seconds: 1));
          final cancelled = await api.cancelCoupleRequest(id);
          expect(cancelled.success, isTrue, reason: cancelled.error);
          _advance(const Duration(seconds: 10));
          expect((await api.getCoupleRequests()).data!['sent'], isEmpty);
          expect((await api.getCoupleData()).data!['couple'], isNull);
        });
      },
    );

    test('annuler une demande déjà acceptée : 409 ; inconnue : 404', () {
      final id = _requestTo(301)['id'] as int;
      _advance(const Duration(seconds: 3));
      expect(_call('DELETE', '/api/couple/request/$id').status, 409);
      expect(_call('DELETE', '/api/couple/request/424242').status, 404);
    });

    test('seul le destinataire répond : l\'émetteur est refusé', () {
      final id = _requestTo(301)['id'] as int;
      final own = _call(
        'PUT',
        '/api/couple/request/$id',
        body: {'action': 'accept'},
      );
      expect(own.status, 403);
      final unknown = _call(
        'PUT',
        '/api/couple/request/424242',
        body: {'action': 'reject'},
      );
      expect(unknown.status, 404);
      final invalid = _call(
        'PUT',
        '/api/couple/request/$id',
        body: {'action': 'maybe'},
      );
      expect(invalid.status, 400);
    });

    test('archive-conversations répond success', () async {
      await _demo(() async {
        final archived = await ApiService().archiveAllConversationsExcept(
          301,
          message: 'Bonne chance',
        );
        expect(archived.success, isTrue, reason: archived.error);
      });
    });
  });

  group('contenus du couple', () {
    const gated = <(String, String)>[
      ('GET', '/api/couple/activities'),
      ('POST', '/api/couple/activities/1/save'),
      ('POST', '/api/couple/activities/1/pass'),
      ('GET', '/api/couple/saved'),
      ('DELETE', '/api/couple/saved/1'),
      ('GET', '/api/couple/events/registered'),
      ('POST', '/api/couple/events/1/register'),
      ('DELETE', '/api/couple/events/1/register'),
      ('GET', '/api/couple/dates'),
      ('POST', '/api/couple/dates'),
      ('GET', '/api/couple/bucket-list'),
      ('POST', '/api/couple/bucket-list'),
      ('POST', '/api/couple/bucket-list/1/complete'),
      ('GET', '/api/couple/memories'),
      ('POST', '/api/couple/memories'),
      ('GET', '/api/couple/stats'),
    ];

    test('sans couple : 400 « Not in a couple », comme le serveur', () {
      for (final (method, path) in gated) {
        final reply = _call(method, path);
        expect(reply.status, 400, reason: '$method $path');
        expect(reply.json['success'], isFalse);
        expect(reply.json['error'], 'Not in a couple', reason: '$method $path');
      }
    });

    test('sans couple, le catalogue public répond quand même', () async {
      await _demo(() async {
        final content = CoupleApiService();
        expect(_okValue(await content.getEvents()), hasLength(3));
        expect((await content.getEvent(1)).isOk, isTrue);
        expect((await content.getActivity(1)).isOk, isTrue);
      });
    });

    test('activités : fil, enregistrer, passer, retirer', () async {
      _enterCouple();
      await _demo(() async {
        final content = CoupleApiService();
        final feed = _okValue(await content.getActivities());
        expect(feed, hasLength(6));
        expect(feed.every((a) => a.title.isNotEmpty), isTrue);
        expect(feed.every((a) => a.imageUrl == null), isTrue);
        expect(feed.first.formattedPrice, isNotEmpty);
        expect(_okValue(await content.getActivities(category: 'gastronomy')), hasLength(1));
        expect(_okValue(await content.getActivities(limit: 2, offset: 4)), hasLength(2));

        expect((await content.saveActivity(1, notes: 'Pour notre anniversaire')).isOk, isTrue);
        expect((await content.passActivity(2)).isOk, isTrue);
        expect(_okValue(await content.getActivities()).map((a) => a.id), [3, 4, 5, 6]);

        final saved = _okValue(await content.getSavedActivities());
        expect(saved.map((a) => a.id), [1]);
        expect(saved.first.savedAt, isNotNull);
        expect(saved.first.userNotes, 'Pour notre anniversaire');

        expect((await content.removeSavedActivity(1)).isOk, isTrue);
        expect(_okValue(await content.getSavedActivities()), isEmpty);
        expect((await content.getActivity(3)).isOk, isTrue);
        expect((await content.getActivity(999)).failureOrNull?.kind, CoupleFailureKind.notFound);
        expect((await content.saveActivity(999)).isOk, isFalse);
      });
    });

    test('évènements : inscription et désinscription', () async {
      _enterCouple();
      await _demo(() async {
        final content = CoupleApiService();
        final before = _okValue(await content.getEvent(1));
        expect(before.eventDate.isAfter(DateTime.now()), isTrue);
        expect(_okValue(await content.getRegisteredEvents()), isEmpty);

        expect((await content.registerForEvent(1)).isOk, isTrue);
        final registered = _okValue(await content.getRegisteredEvents());
        expect(registered.map((e) => e.id), [1]);
        expect(registered.first.registrationStatus, 'registered');
        expect(registered.first.registeredAt, isNotNull);
        expect(_okValue(await content.getEvent(1)).currentCouples, before.currentCouples + 1);

        expect((await content.cancelEventRegistration(1)).isOk, isTrue);
        expect(_okValue(await content.getRegisteredEvents()), isEmpty);
        expect(_okValue(await content.getEvent(1)).currentCouples, before.currentCouples);
        expect((await content.registerForEvent(999)).isOk, isFalse);
      });
    });

    test(
      'dates, projets, souvenirs et statistiques : les ajouts persistent',
      () async {
        _enterCouple();
        await _demo(() async {
          final content = CoupleApiService();
          expect(_okValue(await content.getDates()), isEmpty);
          expect(_okValue(await content.getBucketList()), isEmpty);
          expect(_okValue(await content.getMemories()), isEmpty);

          expect((await content.addDate(title: 'Notre anniversaire', date: '2026-12-01', type: 'anniversary')).isOk, isTrue);
          final dates = _okValue(await content.getDates());
          expect(dates, hasLength(1));
          expect(dates.first.title, 'Notre anniversaire');
          expect(dates.first.date, DateTime(2026, 12, 1));
          expect(dates.first.type, 'anniversary');

          expect((await content.addBucketListItem(title: 'Voir Rome', category: 'travel')).isOk, isTrue);
          var items = _okValue(await content.getBucketList());
          expect(items, hasLength(1));
          expect(items.first.isCompleted, isFalse);
          expect((await content.completeBucketListItem(items.first.id)).isOk, isTrue);
          items = _okValue(await content.getBucketList());
          expect(items.first.isCompleted, isTrue);

          expect((await content.addMemory(type: 'note', title: 'Premier café', content: 'Un souvenir inventé.')).isOk, isTrue);
          final memories = _okValue(await content.getMemories());
          expect(memories.single.title, 'Premier café');
          expect(memories.single.imageUrl, isNull);

          final snapshot = _okValue(await content.getStats());
          expect(snapshot.stats.memoriesCount, 1);
          expect(snapshot.stats.bucketTotal, 1);
          expect(snapshot.stats.bucketCompleted, 1);
          expect(snapshot.achievements, isEmpty);
        });
      },
    );
  });

  group('fin du couple', () {
    test(
      'DELETE /api/couple/:id le supprime pour de bon, contenus compris',
      () async {
        final couple = _enterCouple();
        await _demo(() async {
          final content = CoupleApiService();
          await content.saveActivity(1);
          await content.addMemory(type: 'note', title: 'À effacer');
          expect(_okValue(await content.getSavedActivities()), hasLength(1));
        });

        final wrong = _call('DELETE', '/api/couple/424242');
        expect(wrong.status, 403);
        expect(_call('GET', '/api/couple').json['couple'], isNotNull);

        final ended = _call('DELETE', '/api/couple/${couple['id']}');
        expect(ended.status, 200);
        expect(ended.json['success'], isTrue);
        expect(_call('GET', '/api/couple').json['couple'], isNull);
        expect(_call('GET', '/api/couple/saved').status, 400);

        _enterCouple();
        expect(_call('GET', '/api/couple/saved').json['activities'], isEmpty);
        expect(_call('GET', '/api/couple/memories').json['memories'], isEmpty);
      },
    );

    test(
      'DELETE /api/couple sans identifiant n\'existe pas (404, jamais 503)',
      () {
        expect(_call('DELETE', '/api/couple').status, 404);
      },
    );

    test('une nouvelle session démo repart sans couple ni demande', () {
      _enterCouple();
      DevSession.start();
      _now = DateTime.now();
      expect(_call('GET', '/api/couple').json['couple'], isNull);
      expect(_call('GET', '/api/couple/requests').json['sent'], isEmpty);
    });
  });

  test('aucune route du mode couple ne répond 503, couple ou non', () {
    const paths = <(String, String)>[
      ('GET', '/api/couple'),
      ('POST', '/api/couple'),
      ('DELETE', '/api/couple'),
      ('GET', '/api/couple/requests'),
      ('POST', '/api/couple/archive-conversations'),
      ('GET', '/api/couple/check/301'),
      ('GET', '/api/couple/milestones'),
      ('GET', '/api/couple/success-story'),
      ('GET', '/api/couple/anniversary'),
      ('GET', '/api/couple/bookings'),
      ('GET', '/api/couple/inconnu/42'),
      ('PATCH', '/api/couple/1/status'),
      ('GET', '/api/couple/events'),
      ('GET', '/api/couple/activities/1'),
      ('GET', '/api/couple/stats'),
    ];
    void sweep(String when) {
      for (final (method, path) in paths) {
        expect(
          _call(method, path).status,
          isNot(503),
          reason: '$when : $method $path',
        );
      }
    }

    sweep('hors couple');
    _enterCouple();
    sweep('en couple');
  });
}

/// The value of a successful call; fails the test with the failure otherwise.
T _okValue<T>(CoupleResult<T> result) => switch (result) {
  CoupleOk<T>(:final value) => value,
  CoupleFailed<T>(:final failure) => fail('expected success, got $failure'),
};
