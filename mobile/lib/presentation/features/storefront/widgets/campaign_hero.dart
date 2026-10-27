import 'package:flutter/material.dart';

import '../../../../core/storefront/storefront_models.dart';
import '../../../../l10n/l10n.dart';
import '../../premium/l10n/plus_text.dart';
import 'campaign_glyph.dart';
import 'campaign_palette.dart';

/// The minimal template of a campaign on the mazl+ page: the drawing in the
/// accent of the theme, title, subtitle, the last day, and the button.
class CampaignHero extends StatelessWidget {
  const CampaignHero({
    super.key,
    required this.campaign,
    required this.onAction,
    this.busy = false,
    this.assetBundle,
  });

  final StorefrontCampaign campaign;

  /// The button: opens the Apple offer code when there is one, else buys.
  final VoidCallback onAction;
  final bool busy;
  final AssetBundle? assetBundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final palette = CampaignPalette.resolve(campaign.accent, scheme.surface);
    final until = l10n.storefrontCampaignUntil(
      plusDateText(l10n, campaign.lastDay),
    );
    final cta = campaign.cta.isEmpty
        ? l10n.storefrontCampaignDefaultCta
        : campaign.cta;
    return Container(
      key: const ValueKey('campaign-hero'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.fill, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampaignGlyph(
            glyph: campaign.glyph,
            color: palette.mark,
            bundle: assetBundle,
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              campaign.title,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.45,
              ),
            ),
          ),
          if (campaign.subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              campaign.subtitle,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            until,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('campaign-cta'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: palette.fill,
                foregroundColor: palette.onFill,
              ),
              onPressed: busy ? null : onAction,
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }
}

/// « -30 % » on a plan the campaign discounts.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, required this.accent});

  final int percent;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = CampaignPalette.resolve(
      accent,
      Theme.of(context).colorScheme.surface,
    );
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        context.l10n.storefrontDiscountBadge(percent),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.onFill,
        ),
      ),
    );
  }
}
