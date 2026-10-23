/// Models of the couple space (stats, badges, dates, bucket list, memories),
/// decoded from the backend rows of `couple.content.routes.ts`.
///
/// Postgres `COUNT(*)` is a bigint and can reach the app as a string
/// (`"3"`), and `DATE` columns arrive as ISO strings: every decoder here
/// accepts both numbers and strings.
library;

int? parseLooseInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

DateTime? parseLooseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String? _text(Object? value) {
  final text = value?.toString();
  return (text == null || text.isEmpty) ? null : text;
}

/// Counters of `GET /api/couple/stats` (`stats` object).
class CoupleStats {
  const CoupleStats({
    this.totalBookings = 0,
    this.savedActivities = 0,
    this.eventsRegistered = 0,
    this.memoriesCount = 0,
    this.bucketCompleted = 0,
    this.bucketTotal = 0,
  });

  final int totalBookings;
  final int savedActivities;
  final int eventsRegistered;
  final int memoriesCount;
  final int bucketCompleted;
  final int bucketTotal;

  factory CoupleStats.fromJson(Map<String, dynamic> json) => CoupleStats(
    totalBookings: parseLooseInt(json['total_bookings']) ?? 0,
    savedActivities: parseLooseInt(json['saved_activities']) ?? 0,
    eventsRegistered: parseLooseInt(json['events_registered']) ?? 0,
    memoriesCount: parseLooseInt(json['memories_count']) ?? 0,
    bucketCompleted: parseLooseInt(json['bucket_completed']) ?? 0,
    bucketTotal: parseLooseInt(json['bucket_total']) ?? 0,
  );
}

/// A badge unlocked by the couple (row of `couple_achievements`).
class CoupleAchievement {
  const CoupleAchievement({
    required this.type,
    required this.name,
    this.description,
    this.icon,
  });

  final String type;
  final String name;
  final String? description;
  final String? icon;

  factory CoupleAchievement.fromJson(Map<String, dynamic> json) =>
      CoupleAchievement(
        type: json['achievement_type']?.toString() ?? '',
        name: json['achievement_name']?.toString() ?? '',
        description: _text(json['description']),
        icon: _text(json['icon']),
      );
}

/// Answer of `GET /api/couple/stats`: counters and unlocked badges.
class CoupleStatsSnapshot {
  const CoupleStatsSnapshot({
    this.stats = const CoupleStats(),
    this.achievements = const [],
  });

  final CoupleStats stats;
  final List<CoupleAchievement> achievements;
}

/// An important date (row of `couple_dates`).
class CoupleDate {
  const CoupleDate({
    required this.id,
    required this.title,
    required this.type,
    this.date,
    this.notes,
  });

  final int id;
  final String title;
  final String type;
  final DateTime? date;
  final String? notes;

  factory CoupleDate.fromJson(Map<String, dynamic> json) => CoupleDate(
    id: parseLooseInt(json['id']) ?? 0,
    title: json['title']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    date: parseLooseDate(json['date']),
    notes: _text(json['notes']),
  );
}

/// A bucket list item (row of `couple_bucket_list`).
class BucketListItem {
  const BucketListItem({
    required this.id,
    required this.title,
    this.category,
    this.description,
    this.isCompleted = false,
  });

  final int id;
  final String title;
  final String? category;
  final String? description;
  final bool isCompleted;

  factory BucketListItem.fromJson(Map<String, dynamic> json) => BucketListItem(
    id: parseLooseInt(json['id']) ?? 0,
    title: json['title']?.toString() ?? '',
    category: _text(json['category']),
    description: _text(json['description']),
    isCompleted: json['is_completed'] == true || json['completed_at'] != null,
  );
}

/// A memory (row of `couple_memories`).
class CoupleMemory {
  const CoupleMemory({
    required this.id,
    required this.type,
    this.title,
    this.content,
    this.imageUrl,
    this.memoryDate,
  });

  final int id;
  final String type;
  final String? title;
  final String? content;
  final String? imageUrl;
  final DateTime? memoryDate;

  factory CoupleMemory.fromJson(Map<String, dynamic> json) => CoupleMemory(
    id: parseLooseInt(json['id']) ?? 0,
    type: json['type']?.toString() ?? '',
    title: _text(json['title']),
    content: _text(json['content']),
    imageUrl: _text(json['image_url']),
    memoryDate: parseLooseDate(json['memory_date']),
  );
}
