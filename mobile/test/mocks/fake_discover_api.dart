import 'dart:async';

import 'package:mazl/core/likes/like_allowance.dart';
import 'package:mazl/core/likes/like_allowance_api.dart';
import 'package:mazl/core/services/api_service.dart';
import 'package:mazl/core/services/store/credits_service.dart';

import '../support/credits_fakes.dart';

/// Stands in for [ApiService] on the Discover screen: serves a fixed list of
/// profiles and records every swipe it is asked to send.
///
/// It also plays the SERVER's part for Super Likes and Boosts, with the
/// answers the real routes give (`swipe.routes.ts`, `boost.routes.ts`): a
/// debit when there is a credit, a 402 with the balance when there is none,
/// a 409 when a Boost already runs. The balance it reports goes to the same
/// [CreditsService] the real [ApiService] feeds.
class FakeDiscoverApi implements ApiService {
  FakeDiscoverApi(
    this.profiles, {
    this.superLikes = 1,
    this.boosts = 0,
    this.boostActive = false,
  });

  final List<Profile> profiles;

  /// What the « server » still lets the member spend.
  int superLikes;
  int boosts;
  bool boostActive;

  /// Forces a 402 on the next super like even when [superLikes] says there is
  /// one: the server knows better than the app's last balance.
  bool refuseNextSuperLike = false;

  /// `userId:action`, in the order the screen sent them.
  final List<String> swipes = [];

  /// The word that went with each swipe of [swipes], null for none.
  final List<String?> swipeNotes = [];

  /// The server refuses the word of a Super Like with its 400 `invalid_note`
  /// (too long, a link): nothing is recorded or spent.
  bool refuseNote = false;

  /// `userId:super_like` the server refused for its word.
  final List<String> refusedNotes = [];

  /// How many times the screen asked to turn a Boost on.
  int boostActivations = 0;

  Map<String, Object?> get _credits => serverCredits(
    superLikeAllowance: 1,
    superLikeRemaining: superLikes,
    superLikePurchased: 0,
    boostAllowance: 0,
    boostRemaining: 0,
    boostPurchased: boosts,
  );

  void _relay() => CreditsService().applyFromServer(_credits);

  /// User ids whose like or super like is a reciprocal match.
  final Set<int> matchWith = {};

  /// Every swipe fails, as when the network is down.
  bool swipesFail = false;

  /// The server refuses every like with its 402 `likes_exhausted`
  /// (`like-allowance.routes.ts`): nothing is recorded, the day's likes are gone.
  bool refuseLikes = false;

  /// What the 402 carries as `allowance`.
  int refusedDailyAllowance = 10;

  /// `userId:like` the server refused with a 402.
  final List<String> refusedLikes = [];

  /// While set, a like waits for it before the server answers (a slow reply).
  Completer<void>? holdLikes;

  /// What the profile page loads.
  @override
  Future<ApiResponse<Profile>> getProfileById(int userId) async {
    for (final p in profiles) {
      if (p.userId == userId) return ApiResponse.success(p);
    }
    return ApiResponse.failure('User not found');
  }

  @override
  Future<ApiResponse<UserProfile>> getCurrentUser() async =>
      ApiResponse.failure('no signed-in user in this test');

  @override
  Future<ApiResponse<List<Profile>>> getDailyPicks() async =>
      ApiResponse.success(profiles);

  /// Who liked the signed-in member, for the Likes screen.
  LikesData? receivedLikes;

  @override
  Future<ApiResponse<LikesData>> getReceivedLikes() async =>
      receivedLikes == null
      ? ApiResponse.failure('no likes in this test')
      : ApiResponse.success(receivedLikes!);

  @override
  Future<ApiResponse<List<Conversation>>> getConversations() async =>
      ApiResponse.success(const []);

  @override
  Future<ApiResponse<List<Profile>>> getDiscoverProfiles({
    int limit = 20,
    int offset = 0,
  }) async => ApiResponse.success(profiles);

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendSwipe({
    required int targetUserId,
    required String action,
    String? note,
  }) async {
    if (swipesFail) return ApiResponse.failure('Failed to send swipe');
    if (note != null && refuseNote) {
      refusedNotes.add('$targetUserId:$action');
      return ApiResponse(
        success: false,
        error: 'Failed to send swipe (HTTP 400)',
        errorKind: ApiErrorKind.invalid,
        errorCode: 'invalid_note',
        statusCode: 400,
        body: {'success': false, 'error': 'invalid_note'},
      );
    }
    swipes.add('$targetUserId:$action');
    swipeNotes.add(note);
    if (action == 'like') {
      final hold = holdLikes;
      if (hold != null) await hold.future;
      if (refuseLikes) {
        refusedLikes.add('$targetUserId:$action');
        return ApiResponse(
          success: false,
          error: 'Failed to send swipe (HTTP 402)',
          errorKind: ApiErrorKind.creditsExhausted,
          errorCode: 'likes_exhausted',
          statusCode: 402,
          body: {
            'success': false,
            'error': 'likes_exhausted',
            'allowance': {
              'daily_allowance': refusedDailyAllowance,
              'remaining': 0,
              'resets_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 5))
                  .toIso8601String(),
            },
          },
        );
      }
    }
    // The server's answer, SwipeResult in src/features/matching/swipe.routes.ts.
    final matched = action != 'pass' && matchWith.contains(targetUserId);
    if (action != 'super_like') {
      return ApiResponse.success(<String, dynamic>{
        'success': true,
        'match': matched,
      });
    }
    if (refuseNextSuperLike || superLikes <= 0) {
      refuseNextSuperLike = false;
      superLikes = 0;
      _relay();
      return ApiResponse(
        success: false,
        error: 'Failed to send swipe (HTTP 402)',
        errorKind: ApiErrorKind.creditsExhausted,
        errorCode: 'super_likes_exhausted',
        statusCode: 402,
        body: {
          'success': false,
          'error': 'super_likes_exhausted',
          'credits': _credits,
        },
      );
    }
    superLikes--;
    _relay();
    return ApiResponse.success(<String, dynamic>{
      'success': true,
      'match': matched,
      'credits': _credits,
    });
  }

  @override
  Future<ApiResponse<BoostStatus>> activateBoost() async {
    boostActivations++;
    if (boostActive) {
      return ApiResponse(
        success: false,
        error: 'Failed to activate boost (HTTP 409)',
        errorKind: ApiErrorKind.boostAlreadyActive,
        errorCode: 'boost_already_active',
        statusCode: 409,
        body: {'success': false, 'error': 'boost_already_active'},
      );
    }
    if (boosts <= 0) {
      _relay();
      return ApiResponse(
        success: false,
        error: 'Failed to activate boost (HTTP 402)',
        errorKind: ApiErrorKind.creditsExhausted,
        errorCode: 'boosts_exhausted',
        statusCode: 402,
        body: {
          'success': false,
          'error': 'boosts_exhausted',
          'credits': _credits,
        },
      );
    }
    boosts--;
    boostActive = true;
    _relay();
    return ApiResponse.success(
      BoostStatus(isActive: true, remainingBoosts: boosts),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeDiscoverApi: ${invocation.memberName}');
}

/// Profiles `Profil1`…, user ids 101…
List<Profile> discoverProfiles(
  int count, {
  List<String> photos = const [],
  bool verified = false,
}) => [
  for (var i = 1; i <= count; i++)
    Profile(
      id: i,
      userId: 100 + i,
      displayName: 'Profil$i',
      age: 20 + i,
      location: 'Paris',
      photos: photos,
      isVerified: verified,
    ),
];

/// Stands in for `GET /api/likes/allowance`: answers [answers] in turn, the
/// last one for ever after, or fails when [failure] is set.
class FakeLikeAllowanceApi implements LikeAllowanceApi {
  FakeLikeAllowanceApi(List<LikeAllowance> answers) : _answers = answers;

  /// A free member with [remaining] likes left today.
  FakeLikeAllowanceApi.free({int remaining = 10, Duration resetsIn = const Duration(hours: 5)})
    : _answers = [freeAllowance(remaining: remaining, resetsIn: resetsIn)];

  /// A mazl+ member: no limit.
  FakeLikeAllowanceApi.unlimited()
    : _answers = [
        LikeAllowance(
          dailyAllowance: null,
          remaining: null,
          resetsAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
        ),
      ];

  final List<LikeAllowance> _answers;

  /// How many times the screen asked.
  int reads = 0;

  /// When set, every read fails with it.
  LikeAllowanceException? failure;

  @override
  Future<LikeAllowance> getAllowance() async {
    final index = reads < _answers.length ? reads : _answers.length - 1;
    reads++;
    final error = failure;
    if (error != null) throw error;
    return _answers[index];
  }
}

LikeAllowance freeAllowance({
  int remaining = 10,
  Duration resetsIn = const Duration(hours: 5),
}) => LikeAllowance(
  dailyAllowance: 10,
  remaining: remaining,
  resetsAt: DateTime.now().toUtc().add(resetsIn),
);
