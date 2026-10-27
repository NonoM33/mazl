import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/premium/swipe_undo_api.dart';

// POST /api/swipes/undo, against the contract: 200 { target_user_id, action,
// remaining_free_undos }, 402 undo_limit_reached, 404 nothing_to_undo,
// 409 undo_not_possible.

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

HttpSwipeUndoApi _api(Future<http.Response> Function(http.Request) handler) =>
    HttpSwipeUndoApi.withClient(
      baseUrl: 'https://api.test',
      token: () => 'jwt-2',
      clientFactory: () => MockClient(handler),
    );

Future<SwipeUndoErrorKind> _kindOf(HttpSwipeUndoApi api) async {
  try {
    await api.undoLastSwipe();
  } on SwipeUndoException catch (error) {
    return error.kind;
  }
  fail('the undo did not fail');
}

void main() {
  test('a success returns the swipe taken back, without a body', () async {
    late http.Request seen;
    final api = _api((request) async {
      seen = request;
      return _json({
        'success': true,
        'data': {
          'target_user_id': 202,
          'action': 'pass',
          'remaining_free_undos': 0,
        },
      });
    });

    final undone = await api.undoLastSwipe();

    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://api.test/api/swipes/undo');
    expect(seen.headers['Authorization'], 'Bearer jwt-2');
    expect(seen.body, isEmpty);
    expect(undone.targetUserId, 202);
    expect(undone.action, 'pass');
    expect(undone.remainingFreeUndos, 0);
  });

  test('null remaining undos means no limit (mazl+)', () async {
    final api = _api(
      (request) async => _json({
        'success': true,
        'data': {
          'target_user_id': 5,
          'action': 'like',
          'remaining_free_undos': null,
        },
      }),
    );
    final undone = await api.undoLastSwipe();
    expect(undone.action, 'like');
    expect(undone.remainingFreeUndos, isNull);
  });

  test('402 undo_limit_reached', () async {
    final api = _api(
      (request) async =>
          _json({'success': false, 'error': 'undo_limit_reached'}, 402),
    );
    expect(await _kindOf(api), SwipeUndoErrorKind.limitReached);
  });

  test('404 nothing_to_undo', () async {
    final api = _api(
      (request) async =>
          _json({'success': false, 'error': 'nothing_to_undo'}, 404),
    );
    expect(await _kindOf(api), SwipeUndoErrorKind.nothingToUndo);
  });

  test('409 undo_not_possible', () async {
    final api = _api(
      (request) async =>
          _json({'success': false, 'error': 'undo_not_possible'}, 409),
    );
    expect(await _kindOf(api), SwipeUndoErrorKind.notPossible);
  });

  test('a 404 with another code is not « nothing to undo »', () async {
    final api = _api(
      (request) async => _json({'success': false, 'error': 'other'}, 404),
    );
    expect(await _kindOf(api), SwipeUndoErrorKind.unknown);
  });

  test('401 is an expired session, 500 a server error', () async {
    expect(
      await _kindOf(_api((request) async => _json({'success': false}, 401))),
      SwipeUndoErrorKind.sessionExpired,
    );
    expect(
      await _kindOf(_api((request) async => _json({'success': false}, 503))),
      SwipeUndoErrorKind.server,
    );
  });

  test('a success whose data is malformed is an error, not an undo', () async {
    for (final data in <Object?>[
      null,
      {'target_user_id': 'x', 'action': 'like', 'remaining_free_undos': null},
      {'target_user_id': 3, 'action': 'super_like', 'remaining_free_undos': 1},
      {'target_user_id': 3, 'action': 'like'},
    ]) {
      final api = _api(
        (request) async => _json({'success': true, 'data': data}),
      );
      expect(await _kindOf(api), SwipeUndoErrorKind.unknown, reason: '$data');
    }
  });

  test('no connection is a network error', () async {
    final api = _api((request) async => throw const SocketException('down'));
    expect(await _kindOf(api), SwipeUndoErrorKind.network);
  });
}
