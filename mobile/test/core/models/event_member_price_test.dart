import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/event.dart';

// `member_price_cents: int|null` of `GET /api/events` and `/api/events/:id`
// (docs/premium/MONETISATION.md §10): the reduced price of a mazl+ member, in
// cents of the event's currency, next to `price` (decimal).

Map<String, dynamic> _json({Object? memberPriceCents = 'absent'}) => {
  'id': 7,
  'title': 'Dîner',
  'date': '2026-11-20T19:00:00.000Z',
  'price': 25,
  'currency': 'EUR',
  if (memberPriceCents != 'absent') 'member_price_cents': memberPriceCents,
};

void main() {
  test('reads the member price in cents', () {
    expect(Event.fromJson(_json(memberPriceCents: 800)).memberPriceCents, 800);
  });

  test('null and absent both mean no member price', () {
    expect(
      Event.fromJson(_json(memberPriceCents: null)).memberPriceCents,
      isNull,
    );
    expect(Event.fromJson(_json()).memberPriceCents, isNull);
  });

  test('zero is a real price: free for members', () {
    expect(Event.fromJson(_json(memberPriceCents: 0)).memberPriceCents, 0);
  });

  test('a negative or unreadable value is no price, never a wrong one', () {
    expect(
      Event.fromJson(_json(memberPriceCents: -100)).memberPriceCents,
      isNull,
    );
    expect(
      Event.fromJson(_json(memberPriceCents: 'abc')).memberPriceCents,
      isNull,
    );
  });

  test('copyWith keeps it', () {
    final event = Event.fromJson(_json(memberPriceCents: 800));
    expect(event.copyWith(attendeeCount: 3).memberPriceCents, 800);
  });
}
