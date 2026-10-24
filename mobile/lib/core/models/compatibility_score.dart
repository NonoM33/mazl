import '_json_parsing.dart';
import 'profile.dart';

/// Compatibility score between two users
class CompatibilityScore {
  final int score; // 0-100
  final bool isSuperCompatible; // score > 85
  final List<CompatibilityFactor> factors;

  CompatibilityScore({
    required this.score,
    required this.isSuperCompatible,
    required this.factors,
  });

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    final score = parseIntSafe(json['score']) ?? 0;
    return CompatibilityScore(
      score: score,
      isSuperCompatible: score >= 85,
      factors: (json['factors'] as List<dynamic>?)
              ?.map((f) => CompatibilityFactor.fromJson(f))
              .toList() ??
          [],
    );
  }

  /// Calculate compatibility locally (fallback if API not available)
  static CompatibilityScore calculate({
    required Profile myProfile,
    required Profile otherProfile,
  }) {
    final factors = <CompatibilityFactor>[];
    int totalScore = 0;
    int factorCount = 0;

    // 1. Relationship intention match (30 points)
    if (myProfile.relationshipIntention != null &&
        otherProfile.relationshipIntention != null) {
      factorCount++;
      if (myProfile.relationshipIntention == otherProfile.relationshipIntention) {
        totalScore += 30;
        factors.add(CompatibilityFactor(
          name: 'Intentions',
          score: 100,
          description: 'Vous cherchez la même chose',
          icon: 'heart',
        ));
      } else {
        factors.add(CompatibilityFactor(
          name: 'Intentions',
          score: 40,
          description: 'Intentions différentes',
          icon: 'heart',
        ));
        totalScore += 12;
      }
    }

    // 2. Jewish practice alignment (25 points)
    if (myProfile.denomination != null && otherProfile.denomination != null) {
      factorCount++;
      final denom1 = myProfile.denomination!.toLowerCase();
      final denom2 = otherProfile.denomination!.toLowerCase();
      if (denom1 == denom2) {
        totalScore += 25;
        factors.add(CompatibilityFactor(
          name: 'Pratique',
          score: 100,
          description: 'Même dénomination',
          icon: 'star',
        ));
      } else {
        // Partial match for similar denominations
        final similarGroups = [
          ['orthodox', 'modern orthodox', 'habad'],
          ['massorti', 'traditionaliste'],
          ['laique'],
        ];
        bool similar = false;
        for (final group in similarGroups) {
          if (group.contains(denom1) && group.contains(denom2)) {
            similar = true;
            break;
          }
        }
        if (similar) {
          totalScore += 18;
          factors.add(CompatibilityFactor(
            name: 'Pratique',
            score: 70,
            description: 'Pratique similaire',
            icon: 'star',
          ));
        } else {
          totalScore += 8;
          factors.add(CompatibilityFactor(
            name: 'Pratique',
            score: 30,
            description: 'Pratique différente',
            icon: 'star',
          ));
        }
      }
    }

    // 3. Age compatibility (20 points)
    if (myProfile.age != null && otherProfile.age != null) {
      factorCount++;
      final ageDiff = (myProfile.age! - otherProfile.age!).abs();
      if (ageDiff <= 3) {
        totalScore += 20;
        factors.add(CompatibilityFactor(
          name: 'Âge',
          score: 100,
          description: 'Âge très proche',
          icon: 'calendar',
        ));
      } else if (ageDiff <= 5) {
        totalScore += 16;
        factors.add(CompatibilityFactor(
          name: 'Âge',
          score: 80,
          description: 'Âge proche',
          icon: 'calendar',
        ));
      } else if (ageDiff <= 10) {
        totalScore += 10;
        factors.add(CompatibilityFactor(
          name: 'Âge',
          score: 50,
          description: 'Différence d\'âge modérée',
          icon: 'calendar',
        ));
      } else {
        totalScore += 4;
        factors.add(CompatibilityFactor(
          name: 'Âge',
          score: 20,
          description: 'Grande différence d\'âge',
          icon: 'calendar',
        ));
      }
    }

    // 4. Location/Distance (25 points)
    if (otherProfile.distance != null) {
      factorCount++;
      final dist = otherProfile.distance!;
      if (dist <= 10) {
        totalScore += 25;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 100,
          description: 'Très proche (< 10 km)',
          icon: 'map-pin',
        ));
      } else if (dist <= 25) {
        totalScore += 20;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 80,
          description: 'Proche (< 25 km)',
          icon: 'map-pin',
        ));
      } else if (dist <= 50) {
        totalScore += 12;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 50,
          description: 'Distance modérée',
          icon: 'map-pin',
        ));
      } else {
        totalScore += 5;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 20,
          description: 'Assez loin',
          icon: 'map-pin',
        ));
      }
    }

    // Normalize score if we have factors
    final finalScore = factorCount > 0 ? (totalScore * 100 ~/ (factorCount * 25)) : 50;
    final clampedScore = finalScore.clamp(0, 100);

    return CompatibilityScore(
      score: clampedScore,
      isSuperCompatible: clampedScore >= 85,
      factors: factors,
    );
  }
}

/// Individual compatibility factor
class CompatibilityFactor {
  final String name;
  final int score; // 0-100
  final String description;
  final String icon;

  CompatibilityFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.icon,
  });

  factory CompatibilityFactor.fromJson(Map<String, dynamic> json) {
    return CompatibilityFactor(
      name: json['name'] as String? ?? '',
      score: parseIntSafe(json['score']) ?? 0,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
    );
  }
}
