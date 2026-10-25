import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/conversation.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_components.dart';

/// Back, avatar, name and status, options (docs/design/CHAT.md §13).
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.user,
    required this.isTyping,
    required this.onBack,
    required this.onOpenProfile,
    required this.onOptions,
  });

  final ConversationUser? user;
  final bool isTyping;
  final VoidCallback onBack;
  final VoidCallback? onOpenProfile;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top,
        start: 4,
        end: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.commonBack,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const DirectionalIcon(LucideIcons.chevronLeft, size: 24),
              onPressed: onBack,
            ),
            Expanded(
              child: InkWell(
                onTap: onOpenProfile,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 36,
                      child: ProfilePhoto(
                        url: user?.picture,
                        seed: user?.userId ?? 0,
                        radius: 18,
                        iconSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? context.l10n.chatHeaderLoading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            isTyping
                                ? context.l10n.chatHeaderTyping
                                : context.l10n.chatHeaderOnline,
                            style: TextStyle(
                              fontSize: 12,
                              color: isTyping
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.l10n.chatHeaderOptions,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(LucideIcons.ellipsis, size: 22),
              onPressed: onOptions,
            ),
          ],
        ),
      ),
    );
  }
}
