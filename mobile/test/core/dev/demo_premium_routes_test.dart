import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mazl/core/dev/demo_http_client.dart';
import 'package:mazl/core/dev/demo_premium_routes.dart';
import 'package:mazl/core/dev/demo_store.dart';
import 'package:mazl/core/dev/dev_session.dart';
import 'package:mazl/core/premium/premium_settings.dart';
import 'package:mazl/core/premium/premium_settings_api.dart';
import 'package:mazl/core/premium/swipe_undo_api.dart';
import 'package:mazl/core/services/api_service.dart';

// The demo answers the mazl+ routes with the shapes and refusals of the
// contract (docs/premium/MONETISATION.md), read by the app's REAL clients.

Future<T> _demo<T>(Future<T> Function() body) => http.runWithClient(
  body,
  () => DemoHttpClient(
    MockClient((request) async => fail('real network: ${request.url}')),
    latency: Duration.zero,
  ),
);

Future<SwipeUndoErrorKind> _undoFails() async {
  try {
    await _demo(HttpSwipeUndoApi().undoLastSwipe);
  } on SwipeUndoException catch (error) {
    return error.kind;
  }
  fail('the undo should be refused');
}

Future<PremiumSettingsErrorKind> _settingsFail(
  Future<Object?> Function(HttpPremiumSettingsApi api) call,
) async {
  try {
    await _demo(() => call(HttpPremiumSettingsApi()));
  } on PremiumSettingsException catch (error) {
    return error.kind;
  }
  fail('the call should be refused');
}

Future<ApiResponse<Map<String, dynamic>>> _swipe(
  int user,
  String action, {
  String? note,
}) => _demo(
  () => ApiService().sendSwipe(targetUserId: user, action: action, note: note),
);

void main() {
  setUp(() {
    DevSession.start();
    DemoStore.reset();
  });
  tearDown(DevSession.stop);

  group('settings, passport and discreet mode', () {
    test('the demo member is a subscriber with no passport', () async {
      final settings = await _demo(HttpPremiumSettingsApi().getSettings);
      expect(settings.isPlus, isTrue);
      expect(settings.passport, isNull);
      expect(settings.incognito, isFalse);
      expect(settings.sendReadReceipts, isTrue);
    });

    test('a passport is kept, read back and turned off', () async {
      const lisbon = Passport(
        city: 'Lisbon',
        latitude: 38.72,
        longitude: -9.14,
      );
      final api = HttpPremiumSettingsApi();
      expect(await _demo(() => api.setPassport(lisbon)), lisbon);
      expect((await _demo(api.getSettings)).passport, lisbon);
      expect(await _demo(() => api.setPassport(null)), isNull);
      expect((await _demo(api.getSettings)).passport, isNull);
    });

    test('the discreet mode is kept and read back', () async {
      final api = HttpPremiumSettingsApi();
      expect(await _demo(() => api.setIncognito(true)), isTrue);
      expect((await _demo(api.getSettings)).incognito, isTrue);
      expect(await _demo(() => api.setIncognito(false)), isFalse);
    });

    test(
      'without mazl+ the server says 402, and turning off is allowed',
      () async {
        DemoPremiumRoutes.isPlus = false;
        expect(
          await _settingsFail(
            (api) => api.setPassport(
              const Passport(city: 'Paris', latitude: 48.85, longitude: 2.35),
            ),
          ),
          PremiumSettingsErrorKind.plusRequired,
        );
        expect(
          await _settingsFail((api) => api.setIncognito(true)),
          PremiumSettingsErrorKind.plusRequired,
        );
        expect(
          await _demo(() => HttpPremiumSettingsApi().setPassport(null)),
          isNull,
        );
        expect(
          await _demo(() => HttpPremiumSettingsApi().setIncognito(false)),
          isFalse,
        );
        expect(
          (await _demo(HttpPremiumSettingsApi().getSettings)).isPlus,
          isFalse,
        );
      },
    );

    test('a new session starts again with no passport', () async {
      final api = HttpPremiumSettingsApi();
      await _demo(
        () => api.setPassport(
          const Passport(city: 'Nice', latitude: 43.7, longitude: 7.26),
        ),
      );
      DemoStore.reset();
      expect((await _demo(api.getSettings)).passport, isNull);
    });
  });

  group('Super Like word', () {
    test('a word with a Super Like is accepted', () async {
      final response = await _swipe(
        202,
        'super_like',
        note: 'Belle photo de Shabbat.',
      );
      expect(response.success, isTrue, reason: response.error);
    });

    test('the word is refused when empty, too long or a link', () async {
      for (final note in ['', '   ', 'x' * 141, 'voir https://example.com']) {
        final response = await _swipe(202, 'super_like', note: note);
        expect(response.success, isFalse, reason: '"$note"');
        expect(response.errorCode, 'invalid_note');
        expect(response.statusCode, 400);
      }
    });

    test('140 characters are accepted', () async {
      final response = await _swipe(202, 'super_like', note: 'x' * 140);
      expect(response.success, isTrue, reason: response.error);
    });

    test('a word with a like or a pass is refused', () async {
      for (final action in ['like', 'pass']) {
        final response = await _swipe(202, action, note: 'Bonjour');
        expect(response.errorCode, 'note_requires_super_like', reason: action);
      }
    });

    test('a refused word spends no Super Like', () async {
      await _swipe(202, 'super_like', note: '');
      final accepted = await _swipe(202, 'super_like');
      expect(
        accepted.success,
        isTrue,
        reason: 'the day\'s Super Like is intact',
      );
    });

    test('the feed has a profile that super liked the member, and one passing '
        'through', () async {
      final profiles = (await _demo(
        () => ApiService().getDiscoverProfiles(),
      )).data!;
      final liked = profiles.where((p) => p.superLikedYou).toList();
      expect(liked, hasLength(1));
      expect(liked.single.superLikeNote, isNotEmpty);
      expect(liked.single.superLikeNote!.length, lessThanOrEqualTo(140));
      expect(profiles.where((p) => p.travelingCity != null), hasLength(1));
    });
  });

  group('undo', () {
    test('nothing was swiped: 404 nothing_to_undo', () async {
      expect(await _undoFails(), SwipeUndoErrorKind.nothingToUndo);
    });

    test('a pass is taken back, with no limit for a subscriber', () async {
      await _swipe(203, 'pass');
      final undone = await _demo(HttpSwipeUndoApi().undoLastSwipe);
      expect(undone.targetUserId, 203);
      expect(undone.action, 'pass');
      expect(undone.remainingFreeUndos, isNull);
      expect(await _undoFails(), SwipeUndoErrorKind.nothingToUndo);
    });

    test('a Super Like cannot be taken back', () async {
      await _swipe(202, 'super_like');
      expect(await _undoFails(), SwipeUndoErrorKind.notPossible);
    });

    test('a like that formed a match cannot be taken back', () async {
      await _swipe(101, 'like');
      // Rachel is the demo's match on like.
      final rachel = (await _demo(
        () => ApiService().getDiscoverProfiles(),
      )).data!.first.userId;
      await _swipe(rachel, 'like');
      expect(await _undoFails(), SwipeUndoErrorKind.notPossible);
    });

    test('without mazl+ one undo a day, then 402', () async {
      DemoPremiumRoutes.isPlus = false;
      await _swipe(203, 'pass');
      final first = await _demo(HttpSwipeUndoApi().undoLastSwipe);
      expect(first.remainingFreeUndos, 0);
      await _swipe(204, 'pass');
      expect(await _undoFails(), SwipeUndoErrorKind.limitReached);
    });

    test('after ten minutes there is nothing to undo', () async {
      await _swipe(203, 'pass');
      final later = DateTime.now().add(const Duration(minutes: 11));
      DemoStore.clock = () => later;
      addTearDown(() => DemoStore.clock = DateTime.now);
      expect(await _undoFails(), SwipeUndoErrorKind.nothingToUndo);
    });
  });
}
