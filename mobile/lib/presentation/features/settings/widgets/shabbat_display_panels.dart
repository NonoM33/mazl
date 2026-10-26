import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../l10n/shabbat_display_labels.dart';
import 'hanukkiah.dart';

/// The first part of the Shabbat display: the hour, big, then the words that
/// name the moment. Nothing here can be touched.
class ShabbatDisplayHeader extends StatelessWidget {
  const ShabbatDisplayHeader({
    super.key,
    required this.clock,
    required this.eyebrow,
    required this.title,
  });

  final String clock;
  final String? eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The digits read left to right in every language.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            clock,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: 120,
              fontWeight: FontWeight.w400,
              letterSpacing: -4,
              height: 1,
              color: AppColors.shabbatDisplayText,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.eyebrow(
              AppColors.shabbatDisplayMuted,
            ).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.family,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            height: 1.1,
            color: AppColors.shabbatDisplayText,
          ),
        ),
      ],
    );
  }
}

/// The second part: the Hanukkah candles of the night when there are any, the
/// times of the rest and the parasha, and the place they are worked out for.
class ShabbatDisplayFacts extends StatelessWidget {
  const ShabbatDisplayFacts({
    super.key,
    required this.facts,
    this.restName,
    this.hanukkahNight,
    this.place,
  });

  final List<DisplayFact> facts;

  /// The name of the rest the facts belong to, when the title is another.
  final String? restName;
  final int? hanukkahNight;
  final String? place;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hanukkahNight != null) ...[
          Hanukkiah(
            night: hanukkahNight!,
            flame: AppColors.shabbatDisplayFlame,
            wax: AppColors.shabbatDisplayWax,
          ),
          const SizedBox(height: 28),
        ],
        if (restName != null) ...[
          Text(
            restName!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.shabbatDisplayText,
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final fact in facts) ...[_Fact(fact), const SizedBox(height: 18)],
        if (place != null)
          Text(
            place!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: 14,
              color: AppColors.shabbatDisplayMuted,
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.fact);

  final DisplayFact fact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          fact.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTypography.eyebrow(
            AppColors.shabbatDisplayMuted,
          ).copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          fact.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.family,
            fontSize: 30,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.6,
            height: 1.15,
            color: AppColors.shabbatDisplayText,
          ),
        ),
      ],
    );
  }
}
