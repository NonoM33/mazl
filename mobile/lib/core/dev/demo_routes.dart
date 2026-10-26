import 'dart:convert';
import 'dart:typed_data';

import 'demo_chat_routes.dart';
import 'demo_couple_routes.dart';
import 'demo_fixtures.dart';
import 'demo_privacy_routes.dart';
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
  const DemoRequest(
    this.method,
    this.path,
    this.query,
    this.body, {
    this.files = const [],
  });

  final String method;
  final String path;
  final Map<String, String> query;

  /// Corps JSON ; pour un envoi multipart, les champs texte.
  final Map<String, dynamic> body;

  /// Fichiers d'un envoi multipart, octets lus.
  final List<DemoUpload> files;
}

/// Un fichier reçu dans un envoi multipart.
class DemoUpload {
  const DemoUpload(this.field, this.filename, this.bytes);

  final String field;
  final String? filename;
  final Uint8List bytes;
}

typedef DemoHandler =
    DemoReply Function(DemoRequest request, RegExpMatch match);

/// Une route du routeur fictif. La méthode `*` répond à toutes les méthodes.
class DemoRoute {
  DemoRoute(this.method, String pattern, this.handler)
    : pattern = RegExp('^$pattern\$');

  final String method;
  final RegExp pattern;
  final DemoHandler handler;
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
      if (route.method != '*' && route.method != request.method) continue;
      final match = route.pattern.firstMatch(path);
      if (match != null) return route.handler(request, match);
    }
    return unavailable();
  }

  static const _ok = DemoReply({'success': true});

  static Map<String, dynamic> _verificationStatus() {
    final photo = DemoStore.photoVerified;
    final identity = DemoStore.identityVerified;
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'success': true,
      'photo': {
        'verified': photo,
        'verified_at': photo ? now : null,
        'attempts_today': 0,
      },
      'identity': {
        'verified': identity,
        'verified_at': identity ? now : null,
        'attempts_today': 0,
      },
      'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
      'is_verified': photo || identity,
      'attempts_today': 0,
      'next_attempt_time': null,
    };
  }

  static DemoReply _json(Map<String, dynamic> body) => DemoReply(body);
  static int _id(RegExpMatch m) => int.parse(m.group(1)!);

  /// Le `credits` du serveur (`GET /api/credits`), pour un membre gratuit.
  static Map<String, dynamic> _credits() => {
    'super_like': {
      'daily_allowance': 1,
      'daily_remaining': DemoStore.superLikesLeft,
      'purchased_balance': 0,
      'available': DemoStore.superLikesLeft,
    },
    'boost': {
      'daily_allowance': 0,
      'daily_remaining': 0,
      'purchased_balance': DemoStore.boostsLeft,
      'available': DemoStore.boostsLeft,
    },
    'resets_at': _nextMidnightUtc(),
  };

  static String _nextMidnightUtc() {
    final now = DemoStore.clock().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1).toIso8601String();
  }

  static DemoReply _swipe(DemoRequest r, RegExpMatch m) {
    final superLike = r.body['action'] == 'super_like';
    if (superLike && !DemoStore.spendSuperLike()) {
      return DemoReply({
        'success': false,
        'error': 'super_likes_exhausted',
        'credits': _credits(),
      }, status: 402);
    }
    final matched =
        r.body['target_user_id'] == DemoFixtures.matchOnLikeUserId &&
        r.body['action'] != 'pass';
    if (matched) {
      DemoStore.openMatchConversation(
        DemoFixtures.profileById(DemoFixtures.matchOnLikeUserId)!,
      );
    }
    // Même réponse que le serveur (SwipeResult) : la clé est `match`.
    return _json({
      'success': true,
      'match': matched,
      if (superLike) 'credits': _credits(),
    });
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
    'remaining_boosts': DemoStore.boostsLeft,
    'views_during_boost': 0,
    'likes_during_boost': 0,
    'credits': _credits(),
  };

  static final List<DemoRoute> _routes = [
    // --- Compte et profil ---
    DemoRoute(
      'GET',
      '/api/auth/me',
      (r, m) => _json({
        'success': true,
        'user': DemoFixtures.meUser(),
        'profile': DemoStore.myProfile(),
        'missing': <String>[],
      }),
    ),
    DemoRoute('PUT', '/api/profile', (r, m) {
      DemoStore.patchProfile(r.body);
      return _json({'success': true, 'profile': DemoStore.myProfile()});
    }),
    DemoRoute(
      'GET',
      '/api/profile/photos',
      (r, m) => _json({'success': true, 'photos': <Object>[]}),
    ),
    DemoRoute(
      'GET',
      '/api/profile/prompts',
      (r, m) => _json({'success': true, 'prompts': DemoStore.prompts()}),
    ),
    DemoRoute(
      'POST',
      '/api/profile/prompts',
      (r, m) => _json({'success': true, 'prompt': DemoStore.addPrompt(r.body)}),
    ),
    DemoRoute('PUT', '/api/profile/prompts/(\\d+)', (r, m) {
      final prompt = DemoStore.updatePrompt(
        _id(m),
        '${r.body['answer'] ?? ''}',
      );
      return prompt == null
          ? unavailable()
          : _json({'success': true, 'prompt': prompt});
    }),
    DemoRoute('DELETE', '/api/profile/prompts/(\\d+)', (r, m) {
      DemoStore.deletePrompt(_id(m));
      return _ok;
    }),
    DemoRoute(
      'GET',
      '/api/prompts',
      (r, m) =>
          _json({'success': true, 'prompts': DemoFixtures.promptTemplates()}),
    ),
    DemoRoute('GET', '/api/profile/(\\d+)', (r, m) {
      final profile = DemoFixtures.profileById(_id(m));
      return profile == null
          ? const DemoReply({
              'success': false,
              'error': 'Profil introuvable',
            }, status: 404)
          : _json({'success': true, 'profile': profile});
    }),
    DemoRoute('DELETE', '/api/users/me', (r, m) => _ok),
    // Vérification : mêmes formes que le serveur (docs/verification/CONTRAT.md).
    // Le mode démo n'analyse rien : toute capture est acceptée.
    DemoRoute(
      'GET',
      '/api/verification/status',
      (r, m) => _json(_verificationStatus()),
    ),
    DemoRoute(
      'POST',
      '/api/verification/face/session',
      (r, m) => _json({
        'success': true,
        'session_id': 'demo-${DemoStore.nextId()}',
        'challenges': const ['front', 'left', 'right'],
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 2))
            .toIso8601String(),
      }),
    ),
    DemoRoute('POST', '/api/verification/face/submit', (r, m) {
      DemoStore.setPhotoVerified(true);
      return _json({
        'success': true,
        'verified': true,
        'photo_matches': const [],
      });
    }),
    DemoRoute('POST', '/api/verification/identity', (r, m) {
      DemoStore.markIdentityVerified();
      return _json({'success': true, 'verified': true});
    }),
    DemoRoute('DELETE', '/api/verification/face/reference', (r, m) {
      DemoStore.setPhotoVerified(false);
      return _ok;
    }),

    // --- Découverte, matchs, likes ---
    DemoRoute(
      'GET',
      '/api/discover',
      (r, m) => _page(DemoFixtures.discoverProfiles(), 'profiles', r),
    ),
    DemoRoute(
      'GET',
      '/api/daily-picks',
      (r, m) => _json({'success': true, 'picks': DemoFixtures.dailyPicks()}),
    ),
    DemoRoute(
      'GET',
      '/api/likes/allowance',
      (r, m) => _json({
        'success': true,
        'allowance': {
          'daily_allowance': null,
          'remaining': null,
          'resets_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 1))
              .toIso8601String(),
        },
      }),
    ),
    DemoRoute(
      'GET',
      '/api/discover/filters',
      (r, m) => _json({
        'success': true,
        'filters': DemoStore.discoverFilters,
        'plus': true,
      }),
    ),
    DemoRoute(
      'PUT',
      '/api/discover/filters',
      (r, m) => _json({
        'success': true,
        'filters': DemoStore.patchDiscoverFilters(r.body),
      }),
    ),
    DemoRoute('POST', '/api/swipes', _swipe),
    DemoRoute(
      'GET',
      '/api/matches',
      (r, m) => _json({'success': true, 'matches': DemoFixtures.matches()}),
    ),
    DemoRoute(
      'GET',
      '/api/likes/received',
      (r, m) => _json(DemoFixtures.likesReceived()),
    ),
    DemoRoute(
      'GET',
      '/api/likes/received/count',
      (r, m) => _json({
        'success': true,
        'count': DemoFixtures.likesReceived()['count'] as int,
      }),
    ),
    DemoRoute('GET', '/api/boost/status', (r, m) => _json(_boost())),
    DemoRoute('POST', '/api/boost/activate', (r, m) {
      if (DemoStore.boostActive) {
        return const DemoReply({
          'success': false,
          'error': 'boost_already_active',
        }, status: 409);
      }
      if (!DemoStore.spendBoost()) {
        return DemoReply({
          'success': false,
          'error': 'boosts_exhausted',
          'credits': _credits(),
        }, status: 402);
      }
      DemoStore.activateBoost();
      return DemoReply(_boost(), status: 201);
    }),
    DemoRoute(
      'GET',
      '/api/credits',
      (r, m) => _json({'success': true, 'credits': _credits()}),
    ),
    DemoRoute(
      'GET',
      '/api/users/blocked',
      (r, m) => _json({'success': true, 'blocked': <Object>[]}),
    ),
    DemoRoute('POST', '/api/users/(\\d+)/block', (r, m) => _ok),
    DemoRoute('DELETE', '/api/users/(\\d+)/block', (r, m) => _ok),
    DemoRoute('POST', '/api/users/(\\d+)/report', (r, m) => _ok),

    // --- Messagerie ---
    DemoRoute(
      'GET',
      '/api/conversations',
      (r, m) =>
          _json({'success': true, 'conversations': DemoStore.conversations()}),
    ),

    // --- Évènements ---
    DemoRoute(
      'GET',
      '/api/events',
      (r, m) => _json({'success': true, 'events': DemoStore.events()}),
    ),
    DemoRoute('GET', '/api/events/(\\d+)', (r, m) {
      final event = DemoStore.events().where((e) => e['id'] == _id(m));
      return event.isEmpty
          ? unavailable()
          : _json({'success': true, 'event': event.first});
    }),
    DemoRoute('POST', '/api/events/(\\d+)/rsvp', (r, m) {
      DemoStore.setRsvp(_id(m), '${r.body['status'] ?? 'going'}');
      return _ok;
    }),
    DemoRoute('DELETE', '/api/events/(\\d+)/rsvp', (r, m) {
      DemoStore.setRsvp(_id(m), null);
      return _ok;
    }),

    // --- Mode couple (demo_couple_routes.dart) ---
    ...DemoPrivacyRoutes.routes,
    ...DemoCoupleRoutes.routes,

    // --- Messagerie : messages, médias, réactions (demo_chat_routes.dart) ---
    ...DemoChatRoutes.routes,
  ];
}
