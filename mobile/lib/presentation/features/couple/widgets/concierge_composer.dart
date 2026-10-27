import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import 'concierge_controller.dart';

/// The privacy mention of the concierge (contract §0.4): what reads the
/// requests. Always on screen, small but readable.
class ConciergePrivacyNote extends StatelessWidget {
  const ConciergePrivacyNote({super.key});

  @override
  Widget build(BuildContext context) => Text(
    context.l10n.coupleConciergePrivacy,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelMedium,
  );
}

/// The field of a conversation: a 56 pt pill with a round 44 pt send button
/// in the accent, and the privacy mention under it. Sending is off while a
/// message is on its way.
class ConciergeComposer extends StatelessWidget {
  const ConciergeComposer({super.key, required this.controller});

  final ConciergeController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, controller.text]),
            builder: (context, _) {
              final enabled = controller.canSend;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.focus.requestFocus,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 20,
                              top: 4,
                              bottom: 4,
                            ),
                            child: TextField(
                              controller: controller.text,
                              focusNode: controller.focus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) {
                                if (controller.canSend) controller.send();
                              },
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                hintText: l10n.coupleConciergeComposerHint,
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 8,
                            end: 6,
                          ),
                          child: Semantics(
                            button: true,
                            enabled: enabled,
                            label: l10n.coupleConciergeSend,
                            excludeSemantics: true,
                            child: Material(
                              color: enabled
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: const ValueKey('concierge-send'),
                                onTap: enabled ? controller.send : null,
                                child: SizedBox.square(
                                  dimension: 44,
                                  child: Icon(
                                    LucideIcons.arrowUp,
                                    size: 20,
                                    color: enabled
                                        ? scheme.onPrimary
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const ConciergePrivacyNote(),
        ],
      ),
    );
  }
}
