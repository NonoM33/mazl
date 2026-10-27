import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/services/api_service.dart';

import '../../support/credits_fakes.dart';

// POST /api/swipes carries `note` (1..140 characters) with a super_like, and
// nothing new for a like or a pass: the call stays backward compatible.

Future<Map<String, dynamic>> _bodySentBy(
  Future<Object?> Function(ApiService api) call,
) async {
  late Map<String, dynamic> sent;
  await http.runWithClient(
    () => call(ApiService()),
    () => MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'success': true, 'match': false}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  return sent;
}

void main() {
  setUp(installTestCredits);

  test('a super like with a word sends it as note', () async {
    final body = await _bodySentBy(
      (api) => api.sendSwipe(
        targetUserId: 101,
        action: 'super_like',
        note: 'Votre sourire au kiddouch.',
      ),
    );

    expect(body, {
      'target_user_id': 101,
      'action': 'super_like',
      'note': 'Votre sourire au kiddouch.',
    });
  });

  test('without a word there is no note key at all', () async {
    final body = await _bodySentBy(
      (api) => api.sendSwipe(targetUserId: 101, action: 'super_like'),
    );
    expect(body, {'target_user_id': 101, 'action': 'super_like'});
  });

  test('a like keeps its two fields', () async {
    final body = await _bodySentBy(
      (api) => api.sendSwipe(targetUserId: 7, action: 'like'),
    );
    expect(body, {'target_user_id': 7, 'action': 'like'});
  });
}
