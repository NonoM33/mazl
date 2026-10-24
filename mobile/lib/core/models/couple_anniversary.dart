import '_json_parsing.dart';

/// Couple anniversary data
class CoupleAnniversaryData {
  final DateTime matchDate;
  final int daysTogether;
  final String partnerName;
  final String? partnerPhotoUrl;
  final String? myPhotoUrl;
  final CoupleMilestone? currentMilestone;
  final CoupleMilestone? nextMilestone;
  final bool isAnniversaryToday;

  CoupleAnniversaryData({
    required this.matchDate,
    required this.daysTogether,
    required this.partnerName,
    this.partnerPhotoUrl,
    this.myPhotoUrl,
    this.currentMilestone,
    this.nextMilestone,
    this.isAnniversaryToday = false,
  });

  factory CoupleAnniversaryData.fromJson(Map<String, dynamic> json) {
    return CoupleAnniversaryData(
      matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
      daysTogether: parseIntSafe(json['days_together']) ?? 0,
      partnerName: json['partner_name'] as String? ?? '',
      partnerPhotoUrl: json['partner_photo_url'] as String?,
      myPhotoUrl: json['my_photo_url'] as String?,
      currentMilestone: json['current_milestone'] != null
          ? CoupleMilestone.fromJson(json['current_milestone'])
          : null,
      nextMilestone: json['next_milestone'] != null
          ? CoupleMilestone.fromJson(json['next_milestone'])
          : null,
      isAnniversaryToday: json['is_anniversary_today'] == true,
    );
  }
}

/// Couple milestone
class CoupleMilestone {
  final int days;

  /// What the server called it, if it did. Screens name a milestone from
  /// [days] in the member's language and only fall back on this.
  final String label;
  final String icon;
  final bool isSpecial;
  final DateTime? date;
  final int? daysUntil;
  final bool isReached;

  CoupleMilestone({
    required this.days,
    this.label = '',
    required this.icon,
    this.isSpecial = false,
    this.date,
    this.daysUntil,
    this.isReached = false,
  });

  factory CoupleMilestone.fromJson(Map<String, dynamic> json) {
    return CoupleMilestone(
      days: parseIntSafe(json['days']) ?? 0,
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'heart',
      isSpecial: json['is_special'] == true,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      daysUntil: parseIntSafe(json['days_until']),
      isReached: json['is_reached'] == true,
    );
  }

  /// Predefined milestones
  static List<CoupleMilestone> get defaultMilestones => [
        CoupleMilestone(days: 7, icon: 'seedling'),
        CoupleMilestone(days: 30, icon: 'heart'),
        CoupleMilestone(days: 90, icon: 'star'),
        CoupleMilestone(days: 180, icon: 'fire'),
        CoupleMilestone(days: 365, icon: 'crown', isSpecial: true),
        CoupleMilestone(days: 730, icon: 'diamond', isSpecial: true),
      ];
}
