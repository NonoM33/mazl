import '_json_parsing.dart';

/// Profile boost status
class BoostStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final int? remainingBoosts; // null if unlimited (premium)
  final int viewsDuringBoost;
  final int likesDuringBoost;

  BoostStatus({
    required this.isActive,
    this.expiresAt,
    this.remainingBoosts,
    this.viewsDuringBoost = 0,
    this.likesDuringBoost = 0,
  });

  int get minutesRemaining {
    if (!isActive || expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inMinutes.clamp(0, 999);
  }

  factory BoostStatus.fromJson(Map<String, dynamic> json) {
    return BoostStatus(
      isActive: json['is_active'] == true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      remainingBoosts: parseIntSafe(json['remaining_boosts']),
      viewsDuringBoost: parseIntSafe(json['views_during_boost']) ?? 0,
      likesDuringBoost: parseIntSafe(json['likes_during_boost']) ?? 0,
    );
  }
}
