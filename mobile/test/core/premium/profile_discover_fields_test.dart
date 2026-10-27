import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/models/profile.dart';

// The three fields GET /api/discover adds to a profile (contract of
// docs/premium/MONETISATION.md §2 and §5).

Map<String, dynamic> _base() => {'id': 1, 'user_id': 101};

void main() {
  test('a profile that super liked the member, with its word', () {
    final profile = Profile.fromJson({
      ..._base(),
      'super_liked_you': true,
      'super_like_note': 'Votre playlist de Shabbat est parfaite.',
      'traveling_city': 'Tel Aviv',
    });

    expect(profile.superLikedYou, isTrue);
    expect(profile.superLikeNote, 'Votre playlist de Shabbat est parfaite.');
    expect(profile.travelingCity, 'Tel Aviv');
  });

  test('the new fields are absent on an older server', () {
    final profile = Profile.fromJson(_base());

    expect(profile.superLikedYou, isFalse);
    expect(profile.superLikeNote, isNull);
    expect(profile.travelingCity, isNull);
  });

  test('null, blank or non-text values are no note and no city', () {
    for (final value in <Object?>[null, '', '   ', 42, true]) {
      final profile = Profile.fromJson({
        ..._base(),
        'super_liked_you': true,
        'super_like_note': value,
        'traveling_city': value,
      });
      expect(profile.superLikeNote, isNull, reason: '$value');
      expect(profile.travelingCity, isNull, reason: '$value');
      expect(profile.superLikedYou, isTrue);
    }
  });

  test('only a real true marks a Super Like', () {
    for (final value in <Object?>['true', 1, null, false]) {
      expect(
        Profile.fromJson({..._base(), 'super_liked_you': value}).superLikedYou,
        isFalse,
        reason: '$value',
      );
    }
  });
}
