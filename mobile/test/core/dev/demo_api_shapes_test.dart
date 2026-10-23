import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/dev/demo_fixtures.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/http_verification_api.dart';
import 'package:mazl/core/services/verification_api.dart';
import 'package:mazl/presentation/features/chat/conversation_lookup.dart';

/// Rejoue les VRAIES méthodes d'`ApiService` (donc les vrais décodeurs) contre
/// les données fictives : si une forme JSON diverge, le décodeur le dit ici.
Future<T> _demo<T>(Future<T> Function(ApiService api) body) =>
    http.runWithClient(
      () => body(ApiService()),
      () => DemoHttpClient(
        MockClient(
          (request) async =>
              fail('Le vrai réseau ne doit jamais être joint : ${request.url}'),
        ),
        latency: Duration.zero,
      ),
    );

T _ok<T>(ApiResponse<T> response) {
  expect(response.success, isTrue, reason: response.error);
  expect(response.data, isNotNull);
  return response.data as T;
}

void _success(ApiResponse<void> response) =>
    expect(response.success, isTrue, reason: response.error);

void main() {
  setUp(DevSession.start);
  tearDown(DevSession.stop);

  test('getCurrentUser', () async {
    final me = _ok(await _demo((a) => a.getCurrentUser()));
    expect(me.email, 'demo@example.com');
    expect(me.name, 'Léa (démo)');
    expect(me.profile?.displayName, 'Léa (démo)');
  });

  test('getDiscoverProfiles : 8 profils variés, sans photo', () async {
    final profiles = _ok(await _demo((a) => a.getDiscoverProfiles()));
    expect(profiles, hasLength(8));
    expect(profiles.first.displayName, 'Rachel');
    expect(profiles.every((p) => p.photos.isEmpty), isTrue);
    expect(profiles.map((p) => p.denomination).toSet().length, greaterThan(3));
    expect(profiles.any((p) => p.isVerified), isTrue);
    expect(profiles.any((p) => !p.isVerified), isTrue);
    expect(profiles.every((p) => p.relationshipIntention != null), isTrue);
  });

  test('getDiscoverProfiles : la page suivante est vide', () async {
    final profiles = _ok(await _demo((a) => a.getDiscoverProfiles(offset: 20)));
    expect(profiles, isEmpty);
  });

  test('getDailyPicks', () async {
    final picks = _ok(await _demo((a) => a.getDailyPicks()));
    expect(picks, isNotEmpty);
    expect(picks.first.displayName, isNotEmpty);
  });

  test('getMatches : forme lue par l\'écran des matchs', () async {
    final matches = _ok(await _demo((a) => a.getMatches()));
    expect(matches.length, greaterThanOrEqualTo(4));
    final first = matches.first;
    final profile = first['profile'] as Map<String, dynamic>;
    expect(profile['display_name'], 'Noémie');
    expect(profile['user_id'], isA<int>());
    expect(first['conversationId'], isA<int>());
    expect(DateTime.tryParse(first['matchedAt'] as String), isNotNull);
  });

  test('getConversations et getMessages', () async {
    final conversations = _ok(await _demo((a) => a.getConversations()));
    expect(conversations, hasLength(5));
    expect(conversations.any((c) => c.unreadCount > 0), isTrue);
    expect(conversations.first.otherUser?.displayName, 'Noémie');

    for (final conversation in conversations) {
      final messages = _ok(await _demo((a) => a.getMessages(conversation.id)));
      expect(messages, isNotEmpty, reason: 'conversation ${conversation.id}');
      expect(messages.first.content, conversation.lastMessage);
    }
  });

  test('sendMessage renvoie le message avec un nouvel identifiant', () async {
    final message = _ok(await _demo((a) => a.sendMessage(101, 'Coucou')));
    expect(message.content, 'Coucou');
    expect(message.id, isNot(0));
    final all = _ok(await _demo((a) => a.getMessages(101)));
    expect(all.first.id, message.id);
  });

  test('getReceivedLikes et son compteur', () async {
    final likes = _ok(await _demo((a) => a.getReceivedLikes()));
    expect(likes.count, likes.likes.length);
    expect(likes.likes, isNotEmpty);
    expect(likes.likes.first.displayName, isNotEmpty);
    final count = _ok(await _demo((a) => a.getReceivedLikesCount()));
    expect(count, likes.count);
  });

  test('getEvents, getEvent et rsvp', () async {
    final events = _ok(await _demo((a) => a.getEvents()));
    expect(events, hasLength(3));
    expect(events.first.title, isNotEmpty);
    expect(events.first.date.isAfter(DateTime.now()), isTrue);
    final one = _ok(await _demo((a) => a.getEvent(events.first.id)));
    expect(one.title, events.first.title);
    _success(await _demo((a) => a.rsvpEvent(1)));
  });

  test('getProfileById : connu et inconnu', () async {
    final profile = _ok(await _demo((a) => a.getProfileById(301)));
    expect(profile.displayName, 'Noémie');
    final unknown = await _demo((a) => a.getProfileById(99999));
    expect(unknown.success, isFalse);
  });

  test('prompts : les miens, le catalogue, ajout et suppression', () async {
    final mine = _ok(await _demo((a) => a.getMyPrompts()));
    expect(mine, isNotEmpty);
    expect(mine.first.answer, isNotEmpty);
    final templates = _ok(await _demo((a) => a.getAvailablePrompts()));
    expect(templates, isNotEmpty);
    final added = _ok(
      await _demo(
        (a) =>
            a.addPrompt(promptId: 'fun_fact', answer: 'Réponse', position: 3),
      ),
    );
    expect(added.promptText, isNotEmpty);
    _success(await _demo((a) => a.deletePrompt(added.id)));
    expect(
      _ok(await _demo((a) => a.getMyPrompts())).any((p) => p.id == added.id),
      isFalse,
    );
  });

  test('photos, vérification, boost, visiteurs, bloqués, histoires', () async {
    expect(_ok(await _demo((a) => a.getProfilePhotos())), isEmpty);
    expect(_ok(await _demo((a) => a.getBoostStatus())).isActive, isFalse);
    expect(_ok(await _demo((a) => a.activateBoost())).isActive, isTrue);
    expect(
      _ok(await _demo((a) => a.getProfileVisitors())).visitors,
      isNotEmpty,
    );
    expect(_ok(await _demo((a) => a.getBlockedUsers())), isEmpty);
    expect(_ok(await _demo((a) => a.getSuccessStories())), isNotEmpty);
  });

  test(
    'démarrage de la navigation : couple absent, aucune requête en échec',
    () async {
      final couple = _ok(await _demo((a) => a.getCoupleData()));
      expect(couple['couple'], isNull);
      final requests = _ok(await _demo((a) => a.getCoupleRequests()));
      expect(requests['sent'], isEmpty);
      expect(requests['received'], isEmpty);
      expect(_ok(await _demo((a) => a.isUserInCoupleMode(301))), isFalse);
    },
  );

  test('sendSwipe : la forme lue par la découverte et par les likes', () async {
    final plain = _ok(
      await _demo((a) => a.sendSwipe(targetUserId: 202, action: 'like')),
    );
    expect(plain['match'], false);
    final match = _ok(
      await _demo((a) => a.sendSwipe(targetUserId: 201, action: 'like')),
    );
    expect(match['match'], true);
    expect(match['matched'], true);
  });

  test('un match ouvre une conversation, retrouvée par « Envoyer un message »', () async {
    final match = _ok(await _demo(
      (a) => a.sendSwipe(targetUserId: DemoFixtures.matchOnLikeUserId, action: 'like'),
    ));
    expect(match['match'], isTrue);
    final conversations = _ok(await _demo((a) => a.getConversations()));
    final id = conversationIdWith(conversations, DemoFixtures.matchOnLikeUserId);
    expect(id, isNotNull);
    expect(_ok(await _demo((a) => a.getMessages(id!))), isEmpty);
    // Un second like ne crée pas de doublon.
    await _demo((a) => a.sendSwipe(targetUserId: DemoFixtures.matchOnLikeUserId, action: 'like'));
    final again = _ok(await _demo((a) => a.getConversations()));
    expect(again.where((c) => c.otherUser?.userId == DemoFixtures.matchOnLikeUserId), hasLength(1));
  });

  test('vérification : les vrais décodeurs du niveau 1 et 2 lisent la démo', () async {
    Future<R> verif<R>(Future<R> Function(VerificationApi api) body) => _demo((_) => body(HttpVerificationApi()));

    expect(_ok(await verif((a) => a.getStatus())).level, 'none');
    final session = _ok(await verif((a) => a.startFaceSession(FacePurpose.photo)));
    expect(session.challenges.first, FaceChallenge.front);
    expect(session.expiresAt.isAfter(DateTime.now()), isTrue);

    final frames = [for (var i = 0; i < session.challenges.length; i++) Uint8List.fromList([i])];
    expect(_ok(await verif((a) => a.submitFace(session.sessionId, frames))).verified, isTrue);
    expect(_ok(await verif((a) => a.getStatus())).photo.verified, isTrue);

    final chip = ChipReadResult(dg1: Uint8List(1), dg2: Uint8List(1), sod: Uint8List(1));
    expect(_ok(await verif((a) => a.submitIdentity('demo-id', frames, chip))).verified, isTrue);
    expect(_ok(await verif((a) => a.getStatus())).level, 'identity');

    _success(await verif((a) => a.deleteFaceReference()));
    expect(_ok(await verif((a) => a.getStatus())).photo.verified, isFalse);
  });
}
