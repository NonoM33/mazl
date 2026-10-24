import 'package:mazl/core/services/api_service.dart';

/// Stands in for [ApiService] on the Discover screen: serves a fixed list of
/// profiles and records every swipe it is asked to send.
class FakeDiscoverApi implements ApiService {
  FakeDiscoverApi(this.profiles);

  final List<Profile> profiles;

  /// `userId:action`, in the order the screen sent them.
  final List<String> swipes = [];

  /// User ids whose like or super like is a reciprocal match.
  final Set<int> matchWith = {};

  /// Every swipe fails, as when the network is down.
  bool swipesFail = false;

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
  }) async {
    if (swipesFail) return ApiResponse.failure('Failed to send swipe');
    swipes.add('$targetUserId:$action');
    // The server's answer, SwipeResult in src/features/matching/swipe.routes.ts.
    return ApiResponse.success(<String, dynamic>{
      'success': true,
      'match': action != 'pass' && matchWith.contains(targetUserId),
    });
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
