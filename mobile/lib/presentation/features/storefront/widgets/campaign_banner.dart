import 'package:flutter/material.dart';

import '../../../../core/storefront/storefront_models.dart';
import 'campaign_glyph.dart';
import 'campaign_palette.dart';

/// The discreet strip of the campaign inside the « Passer à mazl+ » card of
/// the settings: its drawing and its title.
class CampaignBanner extends StatelessWidget {
  const CampaignBanner({
    super.key,
    required this.campaign,
    required this.surface,
    this.assetBundle,
  });

  final StorefrontCampaign campaign;

  /// The colour the card is drawn on, for the contrast of the drawing.
  final Color surface;
  final AssetBundle? assetBundle;

  @override
  Widget build(BuildContext context) {
    final palette = CampaignPalette.resolve(campaign.accent, surface);
    return Row(
      key: const ValueKey('campaign-banner'),
      children: [
        CampaignGlyph(
          glyph: campaign.glyph,
          color: palette.mark,
          size: 18,
          bundle: assetBundle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            campaign.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
