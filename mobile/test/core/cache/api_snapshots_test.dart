import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/cache/api_snapshots.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late ApiSnapshots store;

  ApiSnapshots build() =>
      ApiSnapshots(clock: () => now, persistDelay: const Duration(days: 1));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 10, 27, 12);
    store = build();
  });

  test('nothing is kept without a signed-in account', () async {
    store.record('/api/matches', '{}');
    expect(store.read('/api/matches'), isNull);
  });

  test('answers survive a restart of the same account', () async {
    await store.bindOwner('5');
    store.record('/api/matches', '{"success":true}');
    await store.flush();

    final relaunched = build();
    await relaunched.bindOwner('5');
    expect(relaunched.read('/api/matches'), '{"success":true}');
    expect(relaunched.recordedAt('/api/matches'), now);
  });

  test('another account never sees the previous account answers', () async {
    await store.bindOwner('5');
    store.record('/api/matches', '{"success":true}');
    await store.flush();

    final other = build();
    await other.bindOwner('6');
    expect(other.read('/api/matches'), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ApiSnapshots.preferencesKey), isNull);
  });

  test('switching account in the same run clears memory and disk', () async {
    await store.bindOwner('5');
    store.record('/api/matches', '{}');
    await store.flush();
    await store.bindOwner('6');
    expect(store.read('/api/matches'), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ApiSnapshots.preferencesKey,
      ),
      isNull,
    );
  });

  test('sign-out clears everything and tells the listeners', () async {
    await store.bindOwner('5');
    store.record('/api/matches', '{}');
    await store.flush();
    final seen = <SnapshotChangeKind>[];
    store.addListener((change) => seen.add(change.kind));

    await store.clear();

    expect(store.read('/api/matches'), isNull);
    expect(store.owner, isNull);
    expect(seen, [SnapshotChangeKind.cleared]);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ApiSnapshots.preferencesKey,
      ),
      isNull,
    );
    store.record('/api/matches', '{}');
    expect(store.read('/api/matches'), isNull, reason: 'no owner, no record');
  });

  test(
    'an answer is fresh until it ages or an action marks it stale',
    () async {
      await store.bindOwner('5');
      store.record('/api/matches', '{}');
      const ttl = Duration(minutes: 5);
      expect(store.isFresh('/api/matches', ttl), isTrue);

      now = now.add(const Duration(minutes: 6));
      expect(store.isFresh('/api/matches', ttl), isFalse);

      store.record('/api/matches', '{}');
      store.markStale(['/api/matches']);
      expect(store.isFresh('/api/matches', ttl), isFalse);
      expect(
        store.read('/api/matches'),
        '{}',
        reason: 'still shown, to be read again',
      );
    },
  );

  test('a dropped answer is gone', () async {
    await store.bindOwner('5');
    store.record('/api/discover?limit=20&offset=0', '{}');
    store.drop(['/api/discover']);
    expect(store.read('/api/discover?limit=20&offset=0'), isNull);
  });

  test('only the most recent profiles of other members are kept', () async {
    await store.bindOwner('5');
    for (var i = 0; i < ApiSnapshots.maxProfiles + 5; i++) {
      now = now.add(const Duration(seconds: 1));
      store.record('/api/profile/${100 + i}', '{}');
    }
    await store.flush();
    final relaunched = build();
    await relaunched.bindOwner('5');
    expect(relaunched.read('/api/profile/100'), isNull);
    expect(
      relaunched.read('/api/profile/${100 + ApiSnapshots.maxProfiles + 4}'),
      '{}',
    );
  });

  test('the dev demo session writes nothing to disk', () async {
    await store.bindOwner('0');
    store.record('/api/matches', '{}');
    await store.flush();
    expect(
      (await SharedPreferences.getInstance()).getString(
        ApiSnapshots.preferencesKey,
      ),
      isNull,
    );
  });
}
