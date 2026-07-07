import '_json_parsing.dart';

/// Success story
class SuccessStory {
  final int id;
  final String couple1Name;
  final String couple2Name;
  final String? couple1PhotoUrl;
  final String? couple2PhotoUrl;
  final String story;
  final List<String> photoUrls;
  final String status; // 'dating', 'engaged', 'married'
  final DateTime? statusDate;
  final DateTime matchDate;
  final DateTime submittedAt;
  final int likesCount;
  final bool isLikedByMe;
  final bool isApproved;

  SuccessStory({
    required this.id,
    required this.couple1Name,
    required this.couple2Name,
    this.couple1PhotoUrl,
    this.couple2PhotoUrl,
    required this.story,
    this.photoUrls = const [],
    this.status = 'dating',
    this.statusDate,
    required this.matchDate,
    required this.submittedAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isApproved = false,
  });

  String get statusLabel {
    switch (status) {
      case 'engaged':
        return 'Fiances';
      case 'married':
        return 'Maries';
      default:
        return 'En couple';
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'engaged':
        return '💍';
      case 'married':
        return '👰';
      default:
        return '❤️';
    }
  }

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      id: parseIntSafe(json['id']) ?? 0,
      couple1Name: json['couple1_name'] as String? ?? '',
      couple2Name: json['couple2_name'] as String? ?? '',
      couple1PhotoUrl: json['couple1_photo_url'] as String?,
      couple2PhotoUrl: json['couple2_photo_url'] as String?,
      story: json['story'] as String? ?? '',
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'dating',
      statusDate: json['status_date'] != null
          ? DateTime.tryParse(json['status_date'])
          : null,
      matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
      submittedAt:
          DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
      likesCount: parseIntSafe(json['likes_count']) ?? 0,
      isLikedByMe: json['is_liked_by_me'] == true,
      isApproved: json['is_approved'] == true,
    );
  }
}
