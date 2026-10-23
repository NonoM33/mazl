import 'dart:convert';

import 'demo_fixtures.dart';
import 'demo_store.dart';

/// Réponse fabriquée par le mode démo.
class DemoReply {
  const DemoReply(this.body, {this.status = 200});

  final Object body;
  final int status;

  String get json => jsonEncode(body);
}

/// Ce que le routeur sait d'une requête : la méthode, le chemin (hôte
/// ignoré), la requête et le corps JSON éventuel.
class DemoRequest {
  const DemoRequest(this.method, this.path, this.query, this.body);

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, dynamic> body;
}

typedef _Handler = DemoReply Function(DemoRequest request, RegExpMatch match);

class _Route {
  _Route(this.method, String pattern, this.handler)
    : pattern = RegExp('^$pattern\$');

  final String method;
  final RegExp pattern;
  final _Handler handler;
}

/// Route une requête vers ses données fictives. Toute route inconnue rend un
/// 503 : le mode démo n'invente jamais une réponse qu'il ne connaît pas.
abstract final class DemoRoutes {
  static DemoReply unavailable() => const DemoReply({
    'success': false,
    'error': 'Mode démo : indisponible',
  }, status: 503);

  static DemoReply respond(DemoRequest request) {
    final path = request.path.length > 1 && request.path.endsWith('/')
        ? request.path.substring(0, request.path.length - 1)
        : request.path;
    for (final route in _routes) {
      if (route.method != request.method) continue;
      final match = route.pattern.firstMatch(path);
      if (match != null) return route.handler(request, match);
    }
    return unavailable();
  }

  static const _ok = DemoReply({'success': true});
  static DemoReply _json(Map<String, dynamic> body) => DemoReply(body);
  static int _id(RegExpMatch m) => int.parse(m.group(1)!);

  static DemoReply _swipe(DemoRequest r, RegExpMatch m) {
    final matched =
        r.body['target_user_id'] == DemoFixtures.matchOnLikeUserId &&
        r.body['action'] != 'pass';
    // `match` (découverte, sélection du jour) et `matched` (likes, profil).
    return _json({'success': true, 'match': matched, 'matched': matched});
  }

  static DemoReply _page(
    List<Map<String, dynamic>> items,
    String key,
    DemoRequest r,
  ) {
    final offset = int.tryParse(r.query['offset'] ?? '') ?? 0;
    return _json({'success': true, key: offset > 0 ? <Object>[] : items});
  }

  static Map<String, dynamic> _boost() => {
    'success': true,
    'is_active': DemoStore.boostActive,
    'expires_at': DemoStore.boostActive
        ? DemoFixtures.isoIn(const Duration(minutes: 30))
        : null,
    'remaining_boosts': DemoStore.boostActive ? 0 : 1,
    'views_during_boost': 0,
    'likes_during_boost': 0,
  };

  static final List<_Route> _routes = [
    // --- Compte et profil ---
    _Route(
      'GET',
      '/api/auth/me',
      (r, m) => _json({
        'success': true,
        'user': DemoFixtures.meUser(),
        'profile': DemoStore.myProfile(),
      }),
    ),
    _Route('PUT', '/api/profile', (r, m) {
      DemoStore.patchProfile(r.body);
      return _json({'success': true, 'profile': DemoStore.myProfile()});
    }),
    _Route(
      'GET',
      '/api/profile/photos',
      (r, m) => _json({'success': true, 'photos': <Object>[]}),
    ),
    _Route(
      'GET',
      '/api/profile/prompts',
      (r, m) => _json({'success': true, 'prompts': DemoStore.prompts()}),
    ),
    _Route(
      'POST',
      '/api/profile/prompts',
      (r, m) => _json({'success': true, 'prompt': DemoStore.addPrompt(r.body)}),
    ),
    _Route('PUT', '/api/profile/prompts/(\\d+)', (r, m) {
      final prompt = DemoStore.updatePrompt(
        _id(m),
        '${r.body['answer'] ?? ''}',
      );
      return prompt == null
          ? unavailable()
          : _json({'success': true, 'prompt': prompt});
    }),
    _Route('DELETE', '/api/profile/prompts/(\\d+)', (r, m) {
      DemoStore.deletePrompt(_id(m));
      return _ok;
    }),
    _Route(
      'GET',
      '/api/prompts',
      (r, m) =>
          _json({'success': true, 'prompts': DemoFixtures.promptTemplates()}),
    ),
    _Route(
      'GET',
      '/api/profile/visitors',
      (r, m) => _json({'success': true, ...DemoFixtures.visitors()}),
    ),
    _Route(
      'GET',
      '/api/profile/visitors/count',
      (r, m) => _json({'success': true, 'count': 2}),
    ),
    _Route('GET', '/api/profile/(\\d+)', (r, m) {
      final profile = DemoFixtures.profileById(_id(m));
      return profile == null
          ? const DemoReply({
              'success': false,
              'error': 'Profil introuvable',
            }, status: 404)
          : _json({'success': true, 'profile': profile});
    }),
    _Route('DELETE', '/api/users/me', (r, m) => _ok),
    _Route(
      'GET',
      '/api/verification/status',
      (r, m) => _json({
        'success': true,
        'is_verified': false,
        'attempts_today': 0,
        'next_attempt_time': null,
      }),
    ),
    _Route(
      'POST',
      '/api/verification/start',
      (r, m) => _json({'success': true, 'gesture_id': 'smile'}),
    ),
    _Route(
      'POST',
      '/api/verification/submit',
      (r, m) => _json({
        'success': true,
        'verified': true,
        'message': 'Mode démo : vérification simulée.',
      }),
    ),

    // --- Découverte, matchs, likes ---
    _Route(
      'GET',
      '/api/discover',
      (r, m) => _page(DemoFixtures.discoverProfiles(), 'profiles', r),
    ),
    _Route(
      'GET',
      '/api/daily-picks',
      (r, m) => _json({'success': true, 'picks': DemoFixtures.dailyPicks()}),
    ),
    _Route('POST', '/api/swipes', _swipe),
    _Route('POST', '/api/swipes/like-prompt', _swipe),
    _Route(
      'GET',
      '/api/matches',
      (r, m) => _json({'success': true, 'matches': DemoFixtures.matches()}),
    ),
    _Route(
      'GET',
      '/api/likes/received',
      (r, m) => _json(DemoFixtures.likesReceived()),
    ),
    _Route(
      'GET',
      '/api/likes/received/count',
      (r, m) => _json({
        'success': true,
        'count': DemoFixtures.likesReceived()['count'] as int,
      }),
    ),
    _Route('GET', '/api/boost/status', (r, m) => _json(_boost())),
    _Route('POST', '/api/boost/activate', (r, m) {
      DemoStore.activateBoost();
      return _json(_boost());
    }),
    _Route(
      'GET',
      '/api/users/blocked',
      (r, m) => _json({'success': true, 'blocked_users': <Object>[]}),
    ),
    _Route('POST', '/api/users/(\\d+)/block', (r, m) => _ok),
    _Route('DELETE', '/api/users/(\\d+)/block', (r, m) => _ok),
    _Route('POST', '/api/users/(\\d+)/report', (r, m) => _ok),

    // --- Messagerie ---
    _Route(
      'GET',
      '/api/conversations',
      (r, m) =>
          _json({'success': true, 'conversations': DemoStore.conversations()}),
    ),
    _Route('GET', '/api/conversations/(\\d+)/messages', (r, m) {
      final offset = int.tryParse(r.query['offset'] ?? '') ?? 0;
      return _json({
        'success': true,
        'messages': offset > 0 ? <Object>[] : DemoStore.messages(_id(m)),
      });
    }),
    _Route(
      'POST',
      '/api/conversations/(\\d+)/messages',
      (r, m) => _json({
        'success': true,
        'message': DemoStore.sendMessage(_id(m), '${r.body['content'] ?? ''}'),
      }),
    ),
    _Route('PUT', '/api/conversations/(\\d+)/read', (r, m) {
      DemoStore.markRead(_id(m));
      return _ok;
    }),

    // --- Évènements ---
    _Route(
      'GET',
      '/api/events',
      (r, m) => _json({'success': true, 'events': DemoStore.events()}),
    ),
    _Route('GET', '/api/events/(\\d+)', (r, m) {
      final event = DemoStore.events().where((e) => e['id'] == _id(m));
      return event.isEmpty
          ? unavailable()
          : _json({'success': true, 'event': event.first});
    }),
    _Route('POST', '/api/events/(\\d+)/rsvp', (r, m) {
      DemoStore.setRsvp(_id(m), '${r.body['status'] ?? 'going'}');
      return _ok;
    }),
    _Route('DELETE', '/api/events/(\\d+)/rsvp', (r, m) {
      DemoStore.setRsvp(_id(m), null);
      return _ok;
    }),

    // --- Histoires de couples ---
    _Route(
      'GET',
      '/api/success-stories',
      (r, m) =>
          _json({'success': true, 'stories': DemoFixtures.successStories()}),
    ),
    _Route('POST', '/api/success-stories', (r, m) => _ok),
    _Route('POST', '/api/success-stories/(\\d+)/like', (r, m) => _ok),

    // --- Mode couple : l'utilisateur fictif n'est pas en couple ---
    _Route(
      'GET',
      '/api/couple',
      (r, m) => _json({'success': true, 'couple': null}),
    ),
    _Route(
      'GET',
      '/api/couple/requests',
      (r, m) =>
          _json({'success': true, 'sent': <Object>[], 'received': <Object>[]}),
    ),
    _Route(
      'GET',
      '/api/couple/check/(\\d+)',
      (r, m) => _json({'success': true, 'in_couple_mode': false}),
    ),
    _Route(
      'GET',
      '/api/couple/milestones',
      (r, m) => _json({'success': true, 'milestones': <Object>[]}),
    ),
    _Route(
      'GET',
      '/api/couple/success-story',
      (r, m) => _json({'success': true, 'story': null}),
    ),
    for (final entry in const {
      '/api/couple/activities': 'activities',
      '/api/couple/saved': 'activities',
      '/api/couple/events': 'events',
      '/api/couple/events/registered': 'events',
      '/api/couple/dates': 'dates',
      '/api/couple/bucket-list': 'items',
      '/api/couple/memories': 'memories',
    }.entries)
      _Route(
        'GET',
        entry.key,
        (r, m) => _json({'success': true, entry.value: <Object>[]}),
      ),
  ];
}
