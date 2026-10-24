import '_json_parsing.dart';

/// Profile visitor
class ProfileVisitor {
  final int userId;
  final String? displayName;
  final String? photoUrl;
  final int? age;
  final bool isVerified;
  final DateTime visitedAt;
  final bool isBlurred; // true for free users

  ProfileVisitor({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.age,
    this.isVerified = false,
    required this.visitedAt,
    this.isBlurred = true,
  });

  factory ProfileVisitor.fromJson(Map<String, dynamic> json) {
    return ProfileVisitor(
      userId: parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      age: parseIntSafe(json['age']),
      isVerified: json['is_verified'] == true,
      visitedAt: DateTime.tryParse(json['visited_at'] ?? '') ?? DateTime.now(),
      isBlurred: json['is_blurred'] == true,
    );
  }
}

/// Visitors data (includes premium status)
class VisitorsData {
  final List<ProfileVisitor> visitors;
  final int totalCount;
  final bool isPremium;

  VisitorsData({
    required this.visitors,
    required this.totalCount,
    required this.isPremium,
  });

  factory VisitorsData.fromJson(Map<String, dynamic> json) {
    return VisitorsData(
      visitors: (json['visitors'] as List<dynamic>?)
              ?.map((v) => ProfileVisitor.fromJson(v))
              .toList() ??
          [],
      totalCount: parseIntSafe(json['total_count']) ?? 0,
      isPremium: json['is_premium'] == true,
    );
  }
}
