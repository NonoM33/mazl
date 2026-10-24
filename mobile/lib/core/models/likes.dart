import '_json_parsing.dart';

/// Likes data model
class LikesData {
  final int count;
  final bool isPremium;
  final List<LikeProfile> likes;

  LikesData({
    required this.count,
    required this.isPremium,
    required this.likes,
  });

  // Alias for count
  int get totalCount => count;

  factory LikesData.fromJson(Map<String, dynamic> json) {
    return LikesData(
      count: parseIntSafe(json['count']) ?? 0,
      isPremium: json['is_premium'] == true,
      likes: (json['likes'] as List<dynamic>?)
          ?.map((e) => LikeProfile.fromJson(e))
          .toList() ?? [],
    );
  }

  String get displayCount {
    if (count <= 10) return '$count';
    if (count <= 25) return '10+';
    if (count <= 50) return '25+';
    if (count <= 99) return '50+';
    return '99+';
  }
}

/// Like profile model
class LikeProfile {
  final int userId;
  final String? displayName;
  final String? picture;
  final int? age;
  final bool isVerified;
  final DateTime likedAt;
  final double? distance;

  LikeProfile({
    required this.userId,
    this.displayName,
    this.picture,
    this.age,
    this.isVerified = false,
    required this.likedAt,
    this.distance,
  });

  // Alias for picture
  String? get photoUrl => picture;

  factory LikeProfile.fromJson(Map<String, dynamic> json) {
    return LikeProfile(
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      age: parseIntSafe(json['age']),
      isVerified: json['is_verified'] == true,
      likedAt: json['liked_at'] != null
          ? DateTime.parse(json['liked_at'])
          : DateTime.now(),
      distance: parseDoubleSafe(json['distance']),
    );
  }
}
