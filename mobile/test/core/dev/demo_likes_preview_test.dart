import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_routes.dart';

// The demo member has no subscription: the demo serves the likes the way the
// server does for such a member (docs/premium/MONETISATION.md §1).

Map<String, dynamic> _received() {
  final reply = DemoRoutes.respond(
    DemoRequest('GET', '/api/likes/received', const {}, const {}),
  );
  expect(reply.status, 200);
  return reply.body as Map<String, dynamic>;
}

void main() {
  test('is the answer of a member without mazl+', () {
    final body = _received();
    expect(body['is_premium'], isFalse);
    final likes = (body['likes'] as List).cast<Map<String, dynamic>>();
    expect(likes, isNotEmpty);
    // The real count, not a rounded one.
    expect(body['count'], likes.length);
  });

  test('carries no identity: no id, no clear photo, no age', () {
    for (final like in (_received()['likes'] as List).cast<Map>()) {
      for (final identity in ['user_id', 'picture', 'age', 'distance']) {
        expect(like.containsKey(identity), isFalse, reason: identity);
      }
      expect(like['liked_at'], isA<String>());
      expect(like['is_verified'], isA<bool>());
      expect(like['is_super_like'], isA<bool>());
    }
  });

  test('the photo is a tiny blurred copy, and some likes have none', () {
    final urls = [
      for (final like in (_received()['likes'] as List).cast<Map>())
        like['blurredPhotoUrl'] as String?,
    ];
    expect(urls.whereType<String>(), isNotEmpty);
    expect(urls.contains(null), isTrue, reason: 'to show the gradient');
    for (final url in urls.whereType<String>()) {
      final query = Uri.parse(url).queryParameters;
      expect(query['w'], '48', reason: url);
      expect(query['blur'], isNotNull, reason: url);
    }
  });

  test('the count route says the same number', () {
    final reply = DemoRoutes.respond(
      DemoRequest('GET', '/api/likes/received/count', const {}, const {}),
    );
    expect((reply.body as Map)['count'], _received()['count']);
  });
}
