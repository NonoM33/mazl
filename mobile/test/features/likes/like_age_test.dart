import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/presentation/features/likes/logic/like_age.dart';

// Written from the sentence of the contract (« il y a 2 h »), not from the code.

final _now = DateTime.utc(2026, 10, 27, 12);

LikeAge _age(Duration ago) => likeAge(_now.subtract(ago), _now);

void main() {
  test('under a minute: just now, and a like from the future too', () {
    expect(_age(Duration.zero).unit, LikeAgeUnit.justNow);
    expect(_age(const Duration(seconds: 59)).unit, LikeAgeUnit.justNow);
    expect(
      likeAge(_now.add(const Duration(minutes: 5)), _now).unit,
      LikeAgeUnit.justNow,
    );
  });

  test('minutes from 1 to 59', () {
    final one = _age(const Duration(minutes: 1));
    expect((one.unit, one.count), (LikeAgeUnit.minutes, 1));
    final last = _age(const Duration(minutes: 59, seconds: 59));
    expect((last.unit, last.count), (LikeAgeUnit.minutes, 59));
  });

  test('hours from 1 to 23, rounded down', () {
    final two = _age(const Duration(hours: 2, minutes: 40));
    expect((two.unit, two.count), (LikeAgeUnit.hours, 2));
    final last = _age(const Duration(hours: 23, minutes: 59));
    expect((last.unit, last.count), (LikeAgeUnit.hours, 23));
  });

  test('days from 1 up', () {
    final one = _age(const Duration(hours: 24));
    expect((one.unit, one.count), (LikeAgeUnit.days, 1));
    final forty = _age(const Duration(days: 40));
    expect((forty.unit, forty.count), (LikeAgeUnit.days, 40));
  });
}
