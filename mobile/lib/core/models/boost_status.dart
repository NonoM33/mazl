import '../services/store/credit_models.dart';
import '_json_parsing.dart';

/// Profile boost status
class BoostStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final int? remainingBoosts;

  /// Le solde de crédits que le serveur joint au statut ; absent d'un serveur
  /// qui ne le renvoie pas encore.
  final CreditBalance? credits;
  final int viewsDuringBoost;
  final int likesDuringBoost;

  BoostStatus({
    required this.isActive,
    this.expiresAt,
    this.remainingBoosts,
    this.credits,
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
      credits: CreditBalance.tryParse(json['credits']),
      viewsDuringBoost: parseIntSafe(json['views_during_boost']) ?? 0,
      likesDuringBoost: parseIntSafe(json['likes_during_boost']) ?? 0,
    );
  }
}
