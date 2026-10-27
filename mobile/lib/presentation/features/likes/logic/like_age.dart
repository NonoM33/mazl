import '../../../../l10n/l10n.dart';

enum LikeAgeUnit { justNow, minutes, hours, days }

/// How long ago a like was given, in the largest whole unit.
typedef LikeAge = ({LikeAgeUnit unit, int count});

LikeAge likeAge(DateTime likedAt, DateTime now) {
  final elapsed = now.difference(likedAt);
  if (elapsed.inMinutes < 1) return (unit: LikeAgeUnit.justNow, count: 0);
  if (elapsed.inHours < 1) {
    return (unit: LikeAgeUnit.minutes, count: elapsed.inMinutes);
  }
  if (elapsed.inDays < 1) {
    return (unit: LikeAgeUnit.hours, count: elapsed.inHours);
  }
  return (unit: LikeAgeUnit.days, count: elapsed.inDays);
}

/// « il y a 2 h », in the member's language.
String likeAgeText(AppLocalizations l10n, DateTime likedAt, DateTime now) {
  final age = likeAge(likedAt, now);
  return switch (age.unit) {
    LikeAgeUnit.justNow => l10n.likesAgoJustNow,
    LikeAgeUnit.minutes => l10n.likesAgoMinutes(age.count),
    LikeAgeUnit.hours => l10n.likesAgoHours(age.count),
    LikeAgeUnit.days => l10n.likesAgoDays(age.count),
  };
}
