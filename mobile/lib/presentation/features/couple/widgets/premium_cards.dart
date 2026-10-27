import 'package:flutter/material.dart';

import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../premium/l10n/plus_text.dart';

/// The inverted card of the subscription (ink on paper in light, the reverse
/// in dark): the colors are the theme's surface and on-surface swapped.
class _InvertedCard extends StatelessWidget {
  const _InvertedCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

TextStyle _small(BuildContext context, {double alpha = 0.72}) => TextStyle(
  fontFamily: AppTypography.family,
  fontSize: 14,
  height: 1.45,
  color: Theme.of(context).colorScheme.surface.withValues(alpha: alpha),
);

Widget _eyebrow(BuildContext context, String text) => Text(
  text.toUpperCase(),
  style: AppTypography.eyebrow(
    Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
  ),
);

Widget _rule(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 14),
  child: SizedBox(
    height: 1,
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
    ),
  ),
);

/// What the store says about the monthly price.
enum PricePhase { loading, ready, unavailable, notSold }

/// « POUR VOUS DEUX »: the price the store gives (never written here), what
/// one subscription brings to both, and what mazl+ adds.
class PremiumPriceCard extends StatelessWidget {
  const PremiumPriceCard({super.key, required this.phase, this.plan});

  final PricePhase phase;
  final SubscriptionPlan? plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _InvertedCard(
      children: [
        _eyebrow(context, l10n.couplePremiumFor),
        const SizedBox(height: 14),
        _price(context),
        const SizedBox(height: 14),
        Text(
          l10n.couplePremiumShared,
          style: _small(context, alpha: 0.86).copyWith(fontSize: 15),
        ),
        _rule(context),
        Text(
          l10n.couplePremiumIncludesPlus,
          style: _small(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _price(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    switch (phase) {
      case PricePhase.loading:
        return SizedBox(
          key: const ValueKey('price-skeleton'),
          height: 48,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(width: 160, height: 40),
            ),
          ),
        );
      case PricePhase.notSold:
        return Text(
          purchaseProblemText(l10n, PurchaseProblem.androidSoon),
          style: _small(context, alpha: 0.9).copyWith(fontSize: 16),
        );
      case PricePhase.unavailable:
        return Text(
          l10n.couplePremiumPriceLater,
          style: _small(context, alpha: 0.9).copyWith(fontSize: 16),
        );
      case PricePhase.ready:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Text(
              plan!.priceLabel,
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(color: scheme.surface),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l10n.couplePremiumPerMonth, style: _small(context)),
            ),
          ],
        );
    }
  }
}

/// The card of a couple that is already subscribed: it is active, who pays,
/// when it renews.
class PremiumActiveCard extends StatelessWidget {
  const PremiumActiveCard({
    super.key,
    required this.paidByLine,
    required this.renewsAt,
  });

  /// « Payé par vous » / « Payé par David », `null` when nobody is named.
  final String? paidByLine;
  final DateTime? renewsAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final date = renewsAt;
    return _InvertedCard(
      children: [
        _eyebrow(context, l10n.couplePremiumFor),
        const SizedBox(height: 14),
        Text(
          l10n.couplePremiumActiveTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: scheme.surface),
        ),
        if (paidByLine != null) ...[
          const SizedBox(height: 14),
          Text(
            paidByLine!,
            style: _small(context, alpha: 0.86).copyWith(fontSize: 15),
          ),
        ],
        if (date != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.couplePremiumRenews(plusDateText(l10n, date.toLocal())),
            style: _small(context),
          ),
        ],
        _rule(context),
        Text(
          l10n.couplePremiumIncludesPlus,
          style: _small(context).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
