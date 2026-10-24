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

  @override
  Future<ApiResponse<List<Profile>>> getDiscoverProfiles({
    int limit = 20,
    int offset = 0,
  }) async => ApiResponse.success(profiles);

  @override
  Future<ApiResponse<Map<String, dynamic>>> sendSwipe({
    required int targetUserId,
    required String action,
  }) async {
    swipes.add('$targetUserId:$action');
    if (action != 'super_like') {
      return ApiResponse.success(<String, dynamic>{'match': false});
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
      'match': false,
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
