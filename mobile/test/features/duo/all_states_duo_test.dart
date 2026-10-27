import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/di/providers/privacy_providers.dart';
import 'package:mazl/core/di/providers/web_sessions_providers.dart';
import 'package:mazl/core/premium/purchase_moments.dart';
import 'package:mazl/core/router/app_router.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/auth_service.dart';
import 'package:mazl/core/services/couple_service.dart';
import 'package:mazl/core/services/data_prefetch_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/core/web_sessions/web_session_models.dart';
import 'package:mazl/presentation/features/chat/state/chat_controller_impl.dart';
import 'package:mazl/presentation/features/duo_tutorial/duo_tutorial_providers.dart';
import 'package:mazl/presentation/features/web_sessions/widgets/qr_scanner_view.dart';
import 'package:mazl/presentation/widgets/skeletons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/duo_tutorial/fake_duo_scene_renderer.dart';
import '../../helpers/duo_poses.dart';
import '../../helpers/l10n_helpers.dart';
import '../../presentation/privacy/privacy_fakes.dart';
import '../../presentation/web_sessions/web_sessions_fakes.dart';
import 'duo_geometry.dart';

// The empty, the error and the waiting states of the app, in the two
// half-open postures of the foldable iPhone (iPhone Duo). The crawl of
// all_screens_duo_test.dart never sees them: the demo always has data. Here
// the server answers with empty lists, with an error, or not at all, and no
// text, image or tappable element may cross the fold.

/// How the server answers the requests of one state.
enum _Answer {
  /// The demo answer with every list emptied.
  empty,

  /// A server error (500).
  error,

  /// No answer, ever: the screen stays on its waiting state.
  never,

  /// The state's own JSON body (`_State.body`), with a 200.
  body,
}

class _State {
  const _State(
    this.id,
    this.path,
    this.answer,
    this.endpoint, {
    this.couple = false,
    this.open,
    this.webSessions,
    this.body,
    this.preferences,
  });

  final String id;
  final String path;
  final _Answer answer;

  /// The requests answered in this way: their path matches.
  final RegExp endpoint;
  final bool couple;
  final Future<void> Function(WidgetTester tester)? open;

  /// The state of the list of connected computers (fake API, not HTTP).
  final _Computers? webSessions;

  /// What the server answers for [_Answer.body].
  final Map<String, Object?>? body;

  /// What the phone already remembers (the mock storage), empty by default.
  final Map<String, Object>? preferences;
}

enum _Computers { empty, failing, loading }

RegExp _p(String pattern) => RegExp('^$pattern\$');

Future<void> _pumpFor(WidgetTester tester, int millis) async {
  for (var elapsed = 0; elapsed < millis; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openBlockedUsers(WidgetTester tester) async {
  final row = find.text('Utilisateurs bloqués');
  // The settings are a lazy list, or two: scroll them until the row is built.
  for (var i = 0; i < 30 && row.evaluate().isEmpty; i++) {
    for (final scrollable in find.byType(Scrollable).evaluate().toList()) {
      await tester.drag(
        find.byWidget(scrollable.widget),
        const Offset(0, -200),
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(row.first);
  await tester.pump();
  await tester.tap(row.first);
  await _pumpFor(tester, 2000);
}

/// Scrolls the settings to the read receipts row (a lazy list).
Future<void> _scrollToReadReceipts(WidgetTester tester) async {
  final row = find.text('Envoyer les confirmations de lecture');
  for (var i = 0; i < 30 && row.evaluate().isEmpty; i++) {
    for (final scrollable in find.byType(Scrollable).evaluate().toList()) {
      await tester.drag(
        find.byWidget(scrollable.widget),
        const Offset(0, -200),
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(row.first);
  await _pumpFor(tester, 300);
}

Map<String, Object?> _bestTimeBody({bool scheduled = false}) {
  final saturday = DateTime.now().toUtc().add(const Duration(days: 3));
  return {
    'success': true,
    'data': {
      'city': scheduled ? 'Paris' : null,
      'best_time': scheduled
          ? {
              'starts_at': saturday.toIso8601String(),
              'weekday': saturday.weekday,
              'hour': saturday.hour,
            }
          : null,
      'scheduled_at': scheduled ? saturday.toIso8601String() : null,
    },
  };
}

Object? _emptied(Object? json) {
  if (json is List) return const [];
  if (json is Map) {
    return {for (final e in json.entries) e.key: _emptied(e.value)};
  }
  return json;
}

/// The demo server, except for the requests of the state under test.
class _StateServer extends http.BaseClient {
  _StateServer(this.state, this._demo);

  final _State state;
  final http.Client _demo;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET' || !state.endpoint.hasMatch(request.url.path)) {
      return _demo.send(request);
    }
    switch (state.answer) {
      case _Answer.never:
        return Completer<http.StreamedResponse>().future;
      case _Answer.body:
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(state.body))),
          200,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      case _Answer.error:
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"success":false,"error":"boom"}')),
          500,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      case _Answer.empty:
        final reply = DemoRoutes.respond(
          DemoRequest(
            request.method,
            request.url.path,
            request.url.queryParameters,
            const {},
          ),
        );
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(_emptied(reply.body)))),
          reply.status,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
    }
  }
}

Map<String, Object?> _verificationBody({
  bool photo = false,
  bool identity = false,
  bool limit = false,
}) => {
  'success': true,
  'photo': {
    'verified': photo,
    'verified_at': photo ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'identity': {
    'verified': identity,
    'verified_at': identity ? '2026-10-26T09:00:00Z' : null,
    'attempts_today': 0,
  },
  'level': identity ? 'identity' : (photo ? 'photo' : 'none'),
  'is_verified': photo || identity,
  'attempts_today': 0,
  'next_attempt_time': limit
      ? DateTime.now().toUtc().add(const Duration(hours: 5)).toIso8601String()
      : null,
};

const Map<String, Object> _thirdLikeOfferDone = {
  'purchase_moment.third_like_done': true,
};

/// `GET /api/likes/received` as the server answers: a member without mazl+
/// gets previews (no identity, a blurred photo or none), a subscriber the
/// complete likes, the first of them a Super Like with a word.
Map<String, Object?> _likesBody({
  required bool free,
  required int count,
  required bool withPhoto,
}) => {
  'success': true,
  'count': count,
  'is_premium': !free,
  'likes': [
    for (var i = 0; i < count && i < 8; i++)
      {
        if (!free) 'user_id': 100 + i,
        'display_name': 'Membre Exemple $i',
        if (!free) 'picture': null,
        if (!free) 'age': 25 + i,
        'is_verified': i.isEven,
        'liked_at': DateTime.now()
            .toUtc()
            .subtract(Duration(hours: 2 + i * 9))
            .toIso8601String(),
        if (free)
          'blurredPhotoUrl': withPhoto ? 'https://example.com/b$i' : null,
        'is_super_like': i == 0,
        if (!free) 'note': i == 0 ? 'Ton profil m\'a fait sourire.' : null,
      },
  ],
};

final List<_State> _states = [
  // matching
  _State(
    'discover: no more profiles',
    '/discover',
    _Answer.empty,
    _p('/api/discover'),
  ),
  _State('discover: error', '/discover', _Answer.error, _p('/api/discover')),
  _State('discover: loading', '/discover', _Answer.never, _p('/api/discover')),
  _State('matches: none', '/matches', _Answer.empty, _p('/api/matches')),
  _State('matches: error', '/matches', _Answer.error, _p('/api/matches')),
  _State('matches: loading', '/matches', _Answer.never, _p('/api/matches')),
  _State('likes: none', '/likes', _Answer.empty, _p('/api/likes/received')),
  _State('likes: error', '/likes', _Answer.error, _p('/api/likes/received')),
  _State('likes: loading', '/likes', _Answer.never, _p('/api/likes/received')),
  _State(
    'likes: free, blurred photos',
    '/likes',
    _Answer.body,
    _p('/api/likes/received'),
    body: _likesBody(free: true, count: 14, withPhoto: true),
    preferences: _thirdLikeOfferDone,
  ),
  _State(
    'likes: free, no usable photo',
    '/likes',
    _Answer.body,
    _p('/api/likes/received'),
    body: _likesBody(free: true, count: 5, withPhoto: false),
    preferences: _thirdLikeOfferDone,
  ),
  _State(
    'likes: free, the offer of the third like',
    '/likes',
    _Answer.body,
    _p('/api/likes/received'),
    body: _likesBody(free: true, count: 3, withPhoto: true),
  ),
  _State(
    'likes: subscriber, Super Like with a word',
    '/likes',
    _Answer.body,
    _p('/api/likes/received'),
    body: _likesBody(free: false, count: 4, withPhoto: true),
  ),
  _State(
    'daily picks: none',
    '/daily-picks',
    _Answer.empty,
    _p('/api/(daily-picks|discover)'),
  ),
  _State(
    'daily picks: error',
    '/daily-picks',
    _Answer.error,
    _p('/api/(daily-picks|discover)'),
  ),
  _State(
    'daily picks: loading',
    '/daily-picks',
    _Answer.never,
    _p('/api/(daily-picks|discover)'),
  ),
  // chat
  _State(
    'conversations: none',
    '/chat',
    _Answer.empty,
    _p('/api/conversations'),
  ),
  _State(
    'conversations: error',
    '/chat',
    _Answer.error,
    _p('/api/conversations'),
  ),
  _State(
    'conversations: loading',
    '/chat',
    _Answer.never,
    _p('/api/conversations'),
  ),
  _State(
    'conversation: no message',
    '/chat/101',
    _Answer.empty,
    _p('/api/conversations/101/messages'),
  ),
  _State(
    'conversation: error',
    '/chat/101',
    _Answer.error,
    _p('/api/conversations/101/messages'),
  ),
  // events
  _State('events: none', '/events', _Answer.empty, _p('/api/events')),
  _State('events: error', '/events', _Answer.error, _p('/api/events')),
  _State('events: loading', '/events', _Answer.never, _p('/api/events')),
  _State('event: error', '/events/1', _Answer.error, _p('/api/events/1')),
  _State('event: loading', '/events/1', _Answer.never, _p('/api/events/1')),
  // profile
  _State(
    'edit profile: error',
    '/profile/edit',
    _Answer.error,
    _p('/api/(auth/me|profile)'),
  ),
  _State(
    'edit profile: no prompt',
    '/profile/edit',
    _Answer.empty,
    _p('/api/(profile/prompts|prompts)'),
  ),
  _State(
    'profile of another member: loading',
    '/discover/profile/201',
    _Answer.never,
    _p('/api/profile/201'),
  ),
  // settings
  _State(
    'blocked users: none',
    '/profile/settings',
    _Answer.empty,
    _p('/api/users/blocked'),
    open: _openBlockedUsers,
  ),
  _State(
    'blocked users: error',
    '/profile/settings',
    _Answer.error,
    _p('/api/users/blocked'),
    open: _openBlockedUsers,
  ),
  _State(
    'blocked users: loading',
    '/profile/settings',
    _Answer.never,
    _p('/api/users/blocked'),
    open: _openBlockedUsers,
  ),
  _State(
    'computers: none',
    '/profile/settings/computers',
    _Answer.empty,
    _p('/none'),
    webSessions: _Computers.empty,
  ),
  _State(
    'computers: error',
    '/profile/settings/computers',
    _Answer.empty,
    _p('/none'),
    webSessions: _Computers.failing,
  ),
  _State(
    'computers: loading',
    '/profile/settings/computers',
    _Answer.empty,
    _p('/none'),
    webSessions: _Computers.loading,
  ),
  // couple
  _State(
    'couple feed: none',
    '/couple/activities',
    _Answer.empty,
    _p('/api/couple/activities'),
    couple: true,
  ),
  _State(
    'couple feed: error',
    '/couple/activities',
    _Answer.error,
    _p('/api/couple/activities'),
    couple: true,
  ),
  _State(
    'couple saved: none',
    '/couple/activities/saved',
    _Answer.empty,
    _p('/api/couple/saved'),
    couple: true,
  ),
  _State(
    'couple saved: error',
    '/couple/activities/saved',
    _Answer.error,
    _p('/api/couple/saved'),
    couple: true,
  ),
  _State(
    'couple events: none',
    '/couple/events',
    _Answer.empty,
    _p('/api/couple/events.*'),
    couple: true,
  ),
  _State(
    'couple events: error',
    '/couple/events',
    _Answer.error,
    _p('/api/couple/events.*'),
    couple: true,
  ),
  _State(
    'couple activity: error',
    '/couple/activities/1',
    _Answer.error,
    _p('/api/couple/activities/1'),
    couple: true,
  ),
  _State(
    'couple event: error',
    '/couple/events/1',
    _Answer.error,
    _p('/api/couple/events/1'),
    couple: true,
  ),
  _State(
    'couple feed: loading',
    '/couple/activities',
    _Answer.never,
    _p('/api/couple/activities'),
    couple: true,
  ),
  _State(
    'couple saved: loading',
    '/couple/activities/saved',
    _Answer.never,
    _p('/api/couple/saved'),
    couple: true,
  ),
  _State(
    'couple events: loading',
    '/couple/events',
    _Answer.never,
    _p('/api/couple/events.*'),
    couple: true,
  ),
  _State(
    'couple activity: loading',
    '/couple/activities/1',
    _Answer.never,
    _p('/api/couple/activities/1'),
    couple: true,
  ),
  _State(
    'couple event: loading',
    '/couple/events/1',
    _Answer.never,
    _p('/api/couple/events/1'),
    couple: true,
  ),
  _State(
    'couple space: nothing yet',
    '/couple/space',
    _Answer.empty,
    _p('/api/couple/(stats|dates|bucket-list|memories)'),
    couple: true,
  ),
  _State(
    'couple space: error',
    '/couple/space',
    _Answer.error,
    _p('/api/couple/(stats|dates|bucket-list|memories)'),
    couple: true,
  ),
  _State(
    'couple space: loading',
    '/couple/space',
    _Answer.never,
    _p('/api/couple/(stats|dates|bucket-list|memories)'),
    couple: true,
  ),
  _State(
    'couple setup: no match',
    '/couple/setup',
    _Answer.empty,
    _p('/api/matches'),
  ),
  _State(
    'couple setup: error',
    '/couple/setup',
    _Answer.error,
    _p('/api/matches'),
  ),
  _State(
    'couple setup: loading',
    '/couple/setup',
    _Answer.never,
    _p('/api/matches'),
  ),
  // filters, verification, boost, premium
  _State(
    'filters: error',
    '/filters',
    _Answer.error,
    _p('/api/discover/filters'),
  ),
  _State(
    'filters: loading',
    '/filters',
    _Answer.never,
    _p('/api/discover/filters'),
  ),
  _State(
    'verification: error',
    '/profile/verification',
    _Answer.error,
    _p('/api/verification/status'),
  ),
  _State(
    'verification: loading',
    '/profile/verification',
    _Answer.never,
    _p('/api/verification/status'),
  ),
  _State(
    'verification: level 1 only',
    '/profile/verification',
    _Answer.body,
    _p('/api/verification/status'),
    body: _verificationBody(photo: true),
  ),
  _State(
    'verification: both levels',
    '/profile/verification',
    _Answer.body,
    _p('/api/verification/status'),
    body: _verificationBody(photo: true, identity: true),
  ),
  _State(
    'verification: limit reached',
    '/profile/verification',
    _Answer.body,
    _p('/api/verification/status'),
    body: _verificationBody(limit: true),
  ),
  _State(
    'boost: error',
    '/boost',
    _Answer.error,
    _p('/api/(boost/status|credits)'),
  ),
  _State(
    'boost: loading',
    '/boost',
    _Answer.never,
    _p('/api/(boost/status|credits)'),
  ),
  _State(
    'boost: best time not measured yet',
    '/boost',
    _Answer.body,
    _p('/api/boost/best-time'),
    body: _bestTimeBody(),
  ),
  _State(
    'boost: best time Boost scheduled',
    '/boost',
    _Answer.body,
    _p('/api/boost/best-time'),
    body: _bestTimeBody(scheduled: true),
  ),
  _State(
    'boost: best time error',
    '/boost',
    _Answer.error,
    _p('/api/boost/best-time'),
  ),
  _State(
    'boost: best time loading',
    '/boost',
    _Answer.never,
    _p('/api/boost/best-time'),
  ),
  // read receipts
  _State(
    'read receipts: setting unavailable',
    '/profile/settings',
    _Answer.error,
    _p('/api/premium/settings'),
    open: _scrollToReadReceipts,
  ),
  _State(
    'read receipts: setting loading',
    '/profile/settings',
    _Answer.never,
    _p('/api/premium/settings'),
    open: _scrollToReadReceipts,
  ),
];

/// What proves that a state was reached and not another screen: a text of the
/// state (the demo caches and falls back, so a request left empty or failing
/// does not always end on the state it was meant for). A waiting state has
/// a spinner or a skeleton instead.
const Map<String, String> _witness = {
  'discover: no more profiles': 'Vous avez tout vu.',
  'discover: error': 'Réessayer',
  'matches: none': 'Pas encore de match',
  'matches: error': 'Impossible de charger les matchs',
  'likes: none': 'Pas encore de likes',
  'likes: error': 'Erreur de chargement',
  'likes: free, blurred photos': '14 personnes vous ont aimé',
  'likes: free, no usable photo': '5 personnes vous ont aimé',
  'likes: free, the offer of the third like':
      'Plusieurs personnes vous ont aimé.',
  'likes: subscriber, Super Like with a word': 'Ton profil m\'a fait sourire.',
  'daily picks: none': 'Vous avez vu toutes vos sélections.',
  'daily picks: error': 'Réessayer',
  'conversations: none': 'Pas encore de conversations',
  'conversations: error': 'Impossible de charger',
  'conversation: no message': 'Dites bonjour.',
  'conversation: error': 'Réessayer',
  'events: none': 'Aucun événement',
  'events: error': 'Impossible de charger les événements',
  'event: error': 'Événement introuvable',
  'edit profile: error': 'Réessayer',
  'edit profile: no prompt': 'Ajouter un prompt',
  'blocked users: none': 'Aucun utilisateur bloqué',
  'blocked users: error': 'Erreur de chargement',
  'computers: none': "Aucun ordinateur n'est connecté pour le moment.",
  'computers: error': 'Impossible de charger vos ordinateurs.',
  'couple feed: none': 'Aucune activité pour le moment',
  'couple feed: error': 'Chargement impossible',
  'couple saved: none': 'Aucune activité sauvegardée',
  'couple saved: error': 'Chargement impossible',
  'couple events: none': 'Aucun événement disponible',
  'couple events: error': 'Chargement impossible',
  'couple activity: error': 'Chargement impossible',
  'couple event: error': 'Chargement impossible',
  'couple space: nothing yet': 'Votre histoire commence',
  'couple space: error': 'Chargement impossible',
  'couple setup: no match': "Aucun match pour l'instant.",
  'couple setup: error': 'Impossible de charger vos matchs.',
  'filters: error': "Vos filtres avancés n'ont pas pu être chargés.",
  'verification: error': 'Réessayer',
  'verification: level 1 only': 'Vérification en cours',
  'verification: both levels': 'Profil entièrement vérifié',
  'verification: limit reached': 'Limite atteinte',
  'boost: error': 'Réessayer',
  'boost: best time not measured yet': 'Pas encore assez de données',
  'boost: best time Boost scheduled': 'Programmé pour',
  'boost: best time error': 'Impossible de charger le meilleur moment.',
  'read receipts: setting unavailable': 'Réglage indisponible',
};

void _expectStateReached(_State state) {
  if (state.answer == _Answer.never ||
      state.webSessions == _Computers.loading) {
    final waiting =
        find.byType(CircularProgressIndicator).evaluate().length +
        find
            .byWidgetPredicate(
              (w) => w.runtimeType.toString().endsWith('Skeleton'),
            )
            .evaluate()
            .length;
    expect(waiting, greaterThan(0), reason: '${state.id} is not waiting');
    return;
  }
  expect(
    find.textContaining(_witness[state.id]!),
    findsWidgets,
    reason: '${state.id} did not reach its state',
  );
}

class _LoadingComputers extends FakeWebSessionsApi {
  @override
  Future<ApiResponse<List<WebSession>>> listSessions() =>
      Completer<ApiResponse<List<WebSession>>>().future;
}

/// The waiting marks (spinners, and the grey shapes of a skeleton) that the
/// fold of [pose] crosses. [foldCrossingProblems] only sees text, images and
/// tappable elements: a skeleton or a spinner has none.
List<String> _waitingCrossingProblems(WidgetTester tester, DuoPose pose) {
  final fold = pose.fold;
  if (fold == null) return const [];
  final across = fold.height > fold.width ? Axis.horizontal : Axis.vertical;
  final marks = <String, String>{};

  // As for the text and the buttons of foldCrossingProblems: a list that
  // scrolls ACROSS the fold moves its rows out of the curve.
  bool scrollsAcross(Element element) {
    var found = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Scrollable &&
          (widget.axisDirection == AxisDirection.left ||
                      widget.axisDirection == AxisDirection.right
                  ? Axis.horizontal
                  : Axis.vertical) ==
              across) {
        found = true;
      }
      return !found;
    });
    return found;
  }

  void note(Element element, String name) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize || scrollsAcross(element)) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.deflate(0.5).overlaps(fold)) {
      marks['$name at ${rect.left.round()},${rect.top.round()} '
              '${rect.width.round()}x${rect.height.round()}'] =
          name;
    }
  }

  bool hasShapeBelow(Element element) {
    var found = false;
    element.visitChildElements((child) {
      if (found) return;
      found = child.widget is DecoratedBox || hasShapeBelow(child);
    });
    return found;
  }

  void leafShapes(Element element, String name) {
    if (element.widget is DecoratedBox && !hasShapeBelow(element)) {
      note(element, name);
    }
    element.visitChildElements((child) => leafShapes(child, name));
  }

  for (final spinner in find.byType(CircularProgressIndicator).evaluate()) {
    note(spinner, 'CircularProgressIndicator');
  }
  final skeletons = find
      .byWidgetPredicate(
        (w) =>
            w.runtimeType.toString().endsWith('Skeleton') ||
            w is SkeletonBox ||
            w is SkeletonCircle,
      )
      .evaluate();
  for (final skeleton in skeletons) {
    leafShapes(skeleton, skeleton.widget.runtimeType.toString());
  }
  return [for (final line in marks.keys) '$line: crosses the fold'];
}

Future<List<String>> _measure(
  WidgetTester tester,
  _State state,
  DuoPose pose,
) async {
  setDuoPose(tester, pose);
  SharedPreferences.setMockInitialValues(state.preferences ?? {});
  PurchaseMoments.resetForTest();
  await AuthService().signInAsDemo();
  if (state.couple) {
    DemoRoutes.respond(
      DemoRequest('POST', '/api/couple/request', const {}, const {
        'target_user_id': 301,
      }),
    );
    final later = DateTime.now().add(const Duration(seconds: 10));
    DemoStore.clock = () => later;
    var done = false;
    final formed = CoupleService().initialize().whenComplete(() => done = true);
    for (var i = 0; i < 100 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await formed;
    if (!CoupleService().isCoupleModeEnabled) {
      throw StateError('the demo couple did not form');
    }
  }
  final computers = switch (state.webSessions) {
    _Computers.empty => FakeWebSessionsApi(),
    _Computers.failing => FakeWebSessionsApi()..listFails = true,
    _Computers.loading => _LoadingComputers(),
    null => FakeWebSessionsApi(sessions: [fakeSession('s1')]),
  };
  final container = ProviderContainer(
    overrides: [
      duoSceneRendererFactoryProvider.overrideWithValue(
        FakeDuoSceneRenderer.new,
      ),
      privacyConsentApiProvider.overrideWithValue(
        FakePrivacyConsentApi(granted: true, version: '2026-10-24'),
      ),
      webSessionsApiProvider.overrideWithValue(computers),
      qrScannerBuilderProvider.overrideWithValue(
        (context, onCode) => const ColoredBox(color: Colors.black),
      ),
    ],
  );
  final router = container.read(appRouterProvider)..go(state.path);
  final controller = DuoPoseController(pose);
  final previousHandler = FlutterError.onError;
  FlutterError.onError = (_) {};
  final problems = <String>[];
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: kTestLocale,
          routerConfig: router,
          builder: duoAppBuilder(controller),
        ),
      ),
    );
    await _pumpFor(tester, 3000);
    await settleFold(tester);
    if (state.open != null) {
      await state.open!(tester);
      await settleFold(tester);
    }
    if (state.open == null && router.state.uri.path != state.path) {
      throw StateError('${state.path} redirected to ${router.state.uri.path}');
    }
    _expectStateReached(state);
    problems
      ..addAll(foldCrossingProblems(tester, pose))
      ..addAll(navigationOutsideColumnProblems(tester, pose))
      ..addAll(_waitingCrossingProblems(tester, pose));
    await _pumpFor(tester, 1000);
    await tester.pumpWidget(const SizedBox());
    container.invalidate(chatControllerProvider);
    // A request left unanswered gives up after 15 s (twice for a screen that
    // asks again).
    await tester.pump(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
  } finally {
    FlutterError.onError = previousHandler;
    router.dispose();
  }
  return problems;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The prefetched lists of an earlier state would hide this one.
    DataPrefetchService().clearAll();
  });
  tearDown(() async {
    DemoStore.clock = DateTime.now;
    await CoupleService().reset();
    DevSession.stop();
  });

  for (final state in _states) {
    for (final pose in [DuoPose.halfOpenBook, DuoPose.halfOpenLaptop]) {
      testWidgets('${state.id} in ${pose.name}', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final List<String> problems;
        try {
          problems = await http.runWithClient(
            () => _measure(tester, state, pose),
            () => _StateServer(
              state,
              DemoHttpClient(
                MockClient((r) async => fail('real network reached: ${r.url}')),
                latency: Duration.zero,
              ),
            ),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        for (final problem in problems) {
          debugPrint('STATE_FAILURE|${state.id}|${pose.name}|$problem');
        }
        expect(problems, isEmpty, reason: '${state.id} crosses the fold');
      });
    }
  }
}
