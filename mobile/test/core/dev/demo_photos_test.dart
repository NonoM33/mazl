import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/dev/demo_fixtures.dart';

List<Map<String, dynamic>> _allProfiles() {
  final ids = <int>{
    for (final p in DemoFixtures.discoverProfiles()) p['user_id'] as int,
    for (final m in DemoFixtures.matches()) m['id'] as int,
    for (final l in DemoFixtures.likesReceived()['likes'] as List)
      (l as Map)['user_id'] as int,
  };
  return [for (final id in ids) DemoFixtures.profileById(id)!];
}

List<String> _photos(Map<String, dynamic> p) =>
    (p['photos'] as List).cast<String>();

void main() {
  test('chaque profil de démo, sauf Léa, a au moins une photo', () {
    for (final p in _allProfiles()) {
      expect(_photos(p), isNotEmpty, reason: '${p['display_name']}');
    }
    expect(_photos(DemoFixtures.me()), isEmpty);
    expect(DemoFixtures.meUser()['picture'], isNull);
  });

  test('toutes les photos viennent de images.unsplash.com en https', () {
    const prefix = 'https://images.unsplash.com/';
    for (final p in _allProfiles()) {
      for (final url in _photos(p)) {
        expect(url.startsWith(prefix), isTrue, reason: url);
      }
    }
    final avatars = [
      for (final m in DemoFixtures.matches())
        (m['profile'] as Map)['picture'] as String?,
      for (final c in DemoFixtures.conversations())
        (c['otherUser'] as Map)['picture'] as String?,
      for (final l in DemoFixtures.likesReceived()['likes'] as List)
        (l as Map)['picture'] as String?,
    ];
    for (final url in avatars) {
      expect(url, isNotNull);
      expect(url!.startsWith(prefix), isTrue, reason: url);
    }
  });

  test('deux profils voisins dans Découvrir n\'ont pas la même photo', () {
    final discover = DemoFixtures.discoverProfiles();
    for (var i = 0; i < discover.length; i++) {
      final mine = _photos(discover[i]);
      for (final j in [i - 1, i + 1]) {
        if (j < 0 || j >= discover.length) continue;
        final other = _photos(discover[j]);
        expect(mine.first, isNot(other.first));
        expect(mine.contains(other.first), isFalse);
      }
      expect(mine.toSet().length, mine.length);
    }
  });

  test('un même user_id garde le même visage partout', () {
    final byId = {for (final p in _allProfiles()) p['user_id'] as int: p};
    String face(String url) => url.split('?').first;
    for (final m in DemoFixtures.matches()) {
      final p = m['profile'] as Map;
      expect(
        face(p['picture'] as String),
        face(_photos(byId[p['user_id']]!).first),
      );
    }
    for (final c in DemoFixtures.conversations()) {
      final u = c['otherUser'] as Map;
      expect(
        face(u['picture'] as String),
        face(_photos(byId[u['user_id']]!).first),
      );
    }
    for (final l in DemoFixtures.likesReceived()['likes'] as List) {
      final u = l as Map;
      expect(
        face(u['picture'] as String),
        face(_photos(byId[u['user_id']]!).first),
      );
    }
  });
}
