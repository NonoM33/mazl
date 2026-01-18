import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact badge showing compatibility score
class CompatibilityBadge extends StatelessWidget {
  const CompatibilityBadge({
    super.key,
    required this.score,
    this.onTap,
    this.size = CompatibilityBadgeSize.medium,
  });

  final CompatibilityScore score;
  final VoidCallback? onTap;
  final CompatibilityBadgeSize size;

  Color get _color {
    if (score.isSuperCompatible) return AppColors.success;
    if (score.score >= 70) return AppColors.primary;
    if (score.score >= 50) return Colors.orange;
    return Colors.grey;
  }

  double get _fontSize {
    switch (size) {
      case CompatibilityBadgeSize.small:
        return 10;
      case CompatibilityBadgeSize.medium:
        return 12;
      case CompatibilityBadgeSize.large:
        return 14;
    }
  }

  double get _padding {
    switch (size) {
      case CompatibilityBadgeSize.small:
        return 4;
      case CompatibilityBadgeSize.medium:
        return 6;
      case CompatibilityBadgeSize.large:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _padding * 1.5, vertical: _padding),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (score.isSuperCompatible) ...[
              Icon(LucideIcons.sparkles, size: _fontSize + 2, color: _color),
              SizedBox(width: _padding / 2),
            ],
            Text(
              '${score.score}%',
              style: TextStyle(
                color: _color,
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum CompatibilityBadgeSize { small, medium, large }

/// Card showing compatibility score with details
class CompatibilityScoreCard extends StatelessWidget {
  const CompatibilityScoreCard({
    super.key,
    required this.score,
    this.userName,
    this.onTap,
  });

  final CompatibilityScore score;
  final String? userName;
  final VoidCallback? onTap;

  Color get _mainColor {
    if (score.isSuperCompatible) return AppColors.success;
    if (score.score >= 70) return AppColors.primary;
    if (score.score >= 50) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _mainColor.withOpacity(0.15),
              _mainColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _mainColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Score circle
            _ScoreCircle(score: score.score, color: _mainColor),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (score.isSuperCompatible) ...[
                        Icon(LucideIcons.sparkles, size: 16, color: _mainColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        score.isSuperCompatible
                            ? 'Super compatible !'
                            : 'Compatibilite',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _mainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.factors.length} criteres analyses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(LucideIcons.chevronRight, color: _mainColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompatibilityDetailsSheet(
        score: score,
        userName: userName,
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  const _ScoreCircle({
    required this.score,
    required this.color,
  });

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(color.withOpacity(0.2)),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          // Score text
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with compatibility details
class CompatibilityDetailsSheet extends StatelessWidget {
  const CompatibilityDetailsSheet({
    super.key,
    required this.score,
    this.userName,
  });

  final CompatibilityScore score;
  final String? userName;

  Color get _mainColor {
    if (score.isSuperCompatible) return AppColors.success;
    if (score.score >= 70) return AppColors.primary;
    if (score.score >= 50) return Colors.orange;
    return Colors.grey;
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'heart':
        return LucideIcons.heart;
      case 'star':
        return LucideIcons.star;
      case 'calendar':
        return LucideIcons.calendar;
      case 'map-pin':
        return LucideIcons.mapPin;
      default:
        return LucideIcons.check;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header with score
              Row(
                children: [
                  _ScoreCircle(score: score.score, color: _mainColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (score.isSuperCompatible) ...[
                              Icon(LucideIcons.sparkles, size: 20, color: _mainColor),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                score.isSuperCompatible
                                    ? 'Super compatible !'
                                    : 'Score de compatibilite',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _mainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (userName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Avec $userName',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Factors list
              if (score.factors.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...score.factors.map((factor) => _FactorRow(
                      factor: factor,
                      icon: _getIcon(factor.icon),
                    )),
              ] else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Completez vos profils pour voir plus de details',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, size: 18, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le score est base sur vos preferences et points communs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.factor,
    required this.icon,
  });

  final CompatibilityFactor factor;
  final IconData icon;

  Color get _color {
    if (factor.score >= 80) return AppColors.success;
    if (factor.score >= 50) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  factor.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${factor.score}%',
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
