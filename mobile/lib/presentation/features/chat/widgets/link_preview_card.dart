import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../chat_providers.dart';
import '../state/chat_controller.dart';
import 'bubble_style.dart';
import 'chat_image.dart';

/// Card under a text bubble's text (docs/design/CHAT.md §9). The link opens
/// outside the app.
class LinkPreviewCard extends ConsumerWidget {
  const LinkPreviewCard({super.key, required this.preview, required this.mine});

  final LinkPreview preview;
  final bool mine;

  /// Host of the link, « example.org ».
  static String domainOf(LinkPreview preview) {
    final host = Uri.tryParse(preview.url)?.host ?? '';
    final bare = host.startsWith('www.') ? host.substring(4) : host;
    return bare.isEmpty ? (preview.siteName ?? preview.url) : bare;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = BubbleColors.of(context, mine: mine);
    final fill = mine
        ? scheme.onPrimaryContainer.withValues(alpha: 0.12)
        : scheme.surface;
    final domainColor = mine
        ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;
    final uri = Uri.tryParse(preview.url);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: uri == null ? null : () => ref.read(chatLinkOpenerProvider)(uri),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: fill,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: preview.imageUrl == null
                      ? ColoredBox(
                          color:
                              AppColors.photoTints[preview.url.length %
                                  AppColors.photoTints.length],
                        )
                      : ChatImage(
                          url: preview.imageUrl,
                          tint: preview.url.length,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preview.title != null && preview.title!.isNotEmpty)
                        Text(
                          preview.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: colors.text,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        domainOf(preview),
                        style: TextStyle(fontSize: 12, color: domainColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
