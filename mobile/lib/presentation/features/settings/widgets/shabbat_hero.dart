import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import 'package:mazl/core/layout/bar_navigation.dart';

/// Bandeau sombre « Shabbat shalom. » : deux bougies, le titre, l'heure
/// d'allumage et celle de la havdala. Pensé pour s'étendre sous la barre
/// d'état ; réutilisable tel quel comme écran de repos plein écran.
class ShabbatHero extends StatelessWidget {
  const ShabbatHero({
    super.key,
    required this.candleLighting,
    required this.havdala,
    required this.city,
    this.onBack,
  });

  static const _eyebrowColor = Color(0xFF8E8B84);
  static const _hairline = Color(0xFF26262C);
  static const _minHeight = 420.0;

  final String candleLighting;
  final String havdala;
  final String city;

  /// Affiche le bouton retour quand il est fourni.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.shabbatBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _minHeight + topInset),
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 28 + topInset, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onBack != null)
                    BarNavigation(
                      // On the app's own (light) background in the vertical
                      // bar: a dark icon, not the white one of the dark hero.
                      buttons: [
                        IconButton(
                          tooltip: context.l10n.commonBack,
                          icon: const DirectionalIcon(LucideIcons.chevronLeft, size: 26),
                          onPressed: onBack,
                        ),
                      ],
                      inline: _BackButton(onPressed: onBack!),
                    ),
                  const Spacer(),
                  const _Candles(),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                context.l10n.settingsShabbatHeroTitle,
                style: const TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: 64,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -3.5,
                  height: 0.95,
                  color: AppColors.shabbatText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.settingsShabbatHeroSubtitle,
                style: const TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: 19,
                  height: 1.35,
                  letterSpacing: -0.2,
                  color: AppColors.shabbatMuted,
                ),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, thickness: 1, color: _hairline),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TimeColumn(label: context.l10n.settingsShabbatCandleLighting, time: candleLighting)),
                  Expanded(child: _TimeColumn(label: context.l10n.settingsShabbatHavdalah, time: havdala)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                city,
                style: const TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: 13,
                  color: AppColors.shabbatMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.commonBack,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: 44,
        child: InkResponse(
          onTap: onPressed,
          radius: 24,
          child: const Center(
            child: DirectionalIcon(LucideIcons.chevronLeft, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Candles extends StatelessWidget {
  const _Candles();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Candle(),
          SizedBox(width: 22),
          _Candle(),
        ],
      ),
    );
  }
}

class _Candle extends StatelessWidget {
  const _Candle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.candleFlame,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: SizedBox(width: 10, height: 16),
        ),
        SizedBox(height: 2),
        ColoredBox(
          color: Color(0xFF3A3A42),
          child: SizedBox(width: 2, height: 90),
        ),
      ],
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.eyebrow(ShabbatHero._eyebrowColor)),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            fontFamily: AppTypography.family,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.4,
            color: AppColors.shabbatText,
          ),
        ),
      ],
    );
  }
}
