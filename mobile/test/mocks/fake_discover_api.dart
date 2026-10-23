import 'package:mazl/core/services/api_service.dart';

/// Stands in for [ApiService] on the Discover screen: serves a fixed list of
/// profiles and records every swipe it is asked to send.
class FakeDiscoverApi implements ApiService {
  FakeDiscoverApi(this.profiles);

  final List<Profile> profiles;

  /// `userId:action`, in the order the screen sent them.
  final List<String> swipes = [];

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
    return ApiResponse.success(<String, dynamic>{'match': false});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeDiscoverApi: ${invocation.memberName}');
}

/// Profiles `Profil1`…, user ids 101…
List<Profile> discoverProfiles(int count, {List<String> photos = const []}) => [
  for (var i = 1; i <= count; i++)
    Profile(
      id: i,
      userId: 100 + i,
      displayName: 'Profil$i',
      age: 20 + i,
      location: 'Paris',
      photos: photos,
    ),
];
