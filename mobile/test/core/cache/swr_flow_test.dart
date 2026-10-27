import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/cache/api_snapshots.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/data_prefetch_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _deck(List<int> ids) => jsonEncode({
  'success': true,
  'profiles': [
    for (final id in ids) {'id': id, 'display_name': 'Membre $id'},
  ],
});

const _matches =
    '{"success":true,"matches":[{"id":1,"name":"Jeanne Exemple"}]}';

void main() {
  late List<String> calls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiSnapshots.instance.clear();
    DataPrefetchService().clearAll();
    calls = [];
  });

  Future<T> withServer<T>(Future<T> Function() body) => http.runWithClient(
    body,
    () => MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      switch (request.url.path) {
        case '/api/discover':
          return http.Response(_deck([1, 2, 3]), 200);
        case '/api/matches':
          return http.Response(_matches, 200);
        case '/api/swipes':
          return http.Response('{"success":true,"match":false}', 200);
        case '/api/users/2/block':
          return http.Response('{"success":true}', 200);
      }
      return http.Response('{"success":false}', 404);
    }),
  );

  test(
    'coming back to a page: the last known answer is there without a call',
    () async {
      await ApiSnapshots.instance.bindOwner('5');
      ApiSnapshots.instance.record(ApiService.matchesKey, _matches);
      ApiSnapshots.instance.record(ApiService.discoverKey, _deck([7, 8]));
      await ApiSnapshots.instance.flush();

      // A new launch: memory is empty, the phone kept the answers.
      ApiSnapshots.instance.forgetMemoryOnly();
      DataPrefetchService().clearAll();
      await DataPrefetchService().hydrate('5');

      expect(DataPrefetchService().matches, isNotNull);
      expect(DataPrefetchService().matches!.single['name'], 'Jeanne Exemple');
      expect(DataPrefetchService().discoverProfiles!.map((p) => p.id), [7, 8]);
      expect(calls, isEmpty, reason: 'hydrating never touches the network');
    },
  );

  test('a fresh answer is not read again', () async {
    await ApiSnapshots.instance.bindOwner('5');
    await withServer(() async {
      await DataPrefetchService().fetchMatches();
      expect(DataPrefetchService().matchesNeedRefresh, isFalse);
      await DataPrefetchService().fetchMatches();
      expect(calls.where((c) => c.endsWith('/api/matches')), hasLength(1));
    });
  });

  test(
    'a swipe removes the card from the kept deck and refreshes matches',
    () async {
      await ApiSnapshots.instance.bindOwner('5');
      await withServer(() async {
        await DataPrefetchService().fetchDiscoverProfiles();
        await DataPrefetchService().fetchMatches();
        expect(DataPrefetchService().matchesNeedRefresh, isFalse);

        await ApiService().sendSwipe(targetUserId: 2, action: 'like');

        final kept = ApiService.peekDiscoverProfiles()!;
        expect(kept.map((p) => p.id), [1, 3]);
        expect(DataPrefetchService().discoverProfiles!.map((p) => p.id), [
          1,
          3,
        ]);
        expect(DataPrefetchService().matchesNeedRefresh, isTrue);
        expect(
          ApiService.peekMatches(),
          isNotNull,
          reason: 'still shown meanwhile',
        );
      });
    },
  );

  test('blocking someone drops the kept deck', () async {
    await ApiSnapshots.instance.bindOwner('5');
    await withServer(() async {
      await DataPrefetchService().fetchDiscoverProfiles();
      await ApiService().blockUser(2);
      expect(ApiService.peekDiscoverProfiles(), isNull);
      expect(DataPrefetchService().discoverProfiles, isNull);
    });
  });

  test('a failed write changes nothing', () async {
    await ApiSnapshots.instance.bindOwner('5');
    await withServer(() async {
      await DataPrefetchService().fetchMatches();
      await ApiService().unblockUser(99); // 404 on the mock
      expect(DataPrefetchService().matchesNeedRefresh, isFalse);
    });
  });

  test('sign-out empties memory, snapshots and disk', () async {
    await ApiSnapshots.instance.bindOwner('5');
    await withServer(() async {
      await DataPrefetchService().fetchDiscoverProfiles();
      await DataPrefetchService().fetchMatches();
    });
    await ApiSnapshots.instance.flush();

    await ApiSnapshots.instance.clear();

    expect(DataPrefetchService().matches, isNull);
    expect(DataPrefetchService().discoverProfiles, isNull);
    expect(ApiService.peekMatches(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ApiSnapshots.preferencesKey,
      ),
      isNull,
    );
  });

  test('another account starts empty', () async {
    await ApiSnapshots.instance.bindOwner('5');
    await withServer(() async => DataPrefetchService().fetchMatches());
    await ApiSnapshots.instance.flush();

    await ApiSnapshots.instance.bindOwner('6');
    await DataPrefetchService().hydrate('6');
    expect(DataPrefetchService().matches, isNull);
    expect(ApiService.peekMatches(), isNull);
  });
}
