import '_json_parsing.dart';
import 'profile.dart';
import 'profile_labels.dart';

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
              .whereType<CompatibilityFactor>()
              .toList() ??
          [],
    );
  }

  /// Le palier du score, que l'écran traduit.
  CompatibilityLevel get level {
    if (isSuperCompatible) return CompatibilityLevel.veryCompatible;
    if (score >= 60) return CompatibilityLevel.compatible;
    if (score >= 40) return CompatibilityLevel.average;
    return CompatibilityLevel.low;
  }

  /// Calculate compatibility locally (fallback if API not available)
  static CompatibilityScore calculate({
    required Profile myProfile,
    required Profile otherProfile,
  }) {
    final factors = <CompatibilityFactor>[];
    int totalScore = 0;
    int factorCount = 0;

    void add(CompatibilityVerdict verdict, int score, int points) {
      factors.add(CompatibilityFactor(verdict: verdict, score: score));
      totalScore += points;
    }

    // 1. Relationship intention match (30 points)
    if (myProfile.relationshipIntention != null &&
        otherProfile.relationshipIntention != null) {
      factorCount++;
      if (myProfile.relationshipIntention == otherProfile.relationshipIntention) {
        add(CompatibilityVerdict.sameIntention, 100, 30);
      } else {
        add(CompatibilityVerdict.differentIntention, 40, 12);
      }
    }

    // 2. Jewish practice alignment (25 points)
    final mine = ProfileLabels.denominationAnswer(myProfile.denomination);
    final theirs = ProfileLabels.denominationAnswer(otherProfile.denomination);
    if (mine != null && theirs != null) {
      factorCount++;
      if (_sameDenomination(mine, theirs)) {
        add(CompatibilityVerdict.sameDenomination, 100, 25);
      } else if (_similarDenominations(mine.kind, theirs.kind)) {
        add(CompatibilityVerdict.similarPractice, 70, 18);
      } else {
        add(CompatibilityVerdict.differentPractice, 30, 8);
      }
    }

    // 3. Age compatibility (20 points)
    if (myProfile.age != null && otherProfile.age != null) {
      factorCount++;
      final ageDiff = (myProfile.age! - otherProfile.age!).abs();
      if (ageDiff <= 3) {
        add(CompatibilityVerdict.veryCloseAge, 100, 20);
      } else if (ageDiff <= 5) {
        add(CompatibilityVerdict.closeAge, 80, 16);
      } else if (ageDiff <= 10) {
        add(CompatibilityVerdict.moderateAgeGap, 50, 10);
      } else {
        add(CompatibilityVerdict.largeAgeGap, 20, 4);
      }
    }

    // 4. Location/Distance (25 points)
    if (otherProfile.distance != null) {
      factorCount++;
      final dist = otherProfile.distance!;
      if (dist <= 10) {
        add(CompatibilityVerdict.veryNear, 100, 25);
      } else if (dist <= 25) {
        add(CompatibilityVerdict.near, 80, 20);
      } else if (dist <= 50) {
        add(CompatibilityVerdict.moderateDistance, 50, 12);
      } else {
        add(CompatibilityVerdict.far, 20, 5);
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

  /// Deux réponses identiques : le même type connu, ou les mêmes mots.
  static bool _sameDenomination(
    ProfileAnswer<Denomination> a,
    ProfileAnswer<Denomination> b,
  ) {
    final kind = a.kind;
    if (kind != null) return kind == b.kind;
    return b.kind == null && a.custom!.toLowerCase() == b.custom!.toLowerCase();
  }

  static const _similarGroups = [
    {Denomination.orthodox, Denomination.modernOrthodox, Denomination.chabad},
    {Denomination.masorti, Denomination.traditional},
    {Denomination.secular},
  ];

  static bool _similarDenominations(Denomination? a, Denomination? b) =>
      a != null && b != null && _similarGroups.any((g) => g.contains(a) && g.contains(b));
}

/// Palier d'un score de compatibilité.
enum CompatibilityLevel { veryCompatible, compatible, average, low }

/// Ce que mesure un critère.
enum CompatibilityFactorKind { intentions, practice, age, distance }

/// Le constat d'un critère ; l'écran le traduit.
enum CompatibilityVerdict {
  sameIntention(CompatibilityFactorKind.intentions),
  differentIntention(CompatibilityFactorKind.intentions),
  sameDenomination(CompatibilityFactorKind.practice),
  similarPractice(CompatibilityFactorKind.practice),
  differentPractice(CompatibilityFactorKind.practice),
  veryCloseAge(CompatibilityFactorKind.age),
  closeAge(CompatibilityFactorKind.age),
  moderateAgeGap(CompatibilityFactorKind.age),
  largeAgeGap(CompatibilityFactorKind.age),
  veryNear(CompatibilityFactorKind.distance),
  near(CompatibilityFactorKind.distance),
  moderateDistance(CompatibilityFactorKind.distance),
  far(CompatibilityFactorKind.distance);

  const CompatibilityVerdict(this.kind);

  final CompatibilityFactorKind kind;

  static CompatibilityVerdict? fromCode(Object? code) {
    for (final verdict in values) {
      if (verdict.name == code) return verdict;
    }
    return null;
  }
}

/// Individual compatibility factor
class CompatibilityFactor {
  final CompatibilityVerdict verdict;
  final int score; // 0-100

  CompatibilityFactor({required this.verdict, required this.score});

  CompatibilityFactorKind get kind => verdict.kind;

  /// `null` quand le constat est inconnu de cette version de l'app.
  static CompatibilityFactor? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final verdict = CompatibilityVerdict.fromCode(json['verdict']);
    if (verdict == null) return null;
    return CompatibilityFactor(
      verdict: verdict,
      score: parseIntSafe(json['score']) ?? 0,
    );
  }
}
