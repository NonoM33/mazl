import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../state/chat_controller.dart';

/// A line of the long-press menu.
class MessageMenuAction {
  const MessageMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Red: take back, report.
  final bool destructive;
}

/// Long press on a bubble (docs/design/CHAT.md §5): the screen goes under a 40 %
/// black veil, the bubble stays where it is, a reaction bar floats above it and
/// a menu below. Pushed on the ROOT navigator so it covers the tab bar and the
/// composer.
Future<void> showMessageActions(
  BuildContext context, {
  required Rect bubbleRect,
  required Widget bubble,
  required bool mine,
  required Set<String> myReactions,
  required ValueChanged<String> onReact,
  required List<MessageMenuAction> actions,
  bool showReactionBar = true,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Fermer le menu',
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, __) => _ActionsPage(
        bubbleRect: bubbleRect,
        bubble: bubble,
        mine: mine,
        myReactions: myReactions,
        onReact: onReact,
        actions: actions,
        showReactionBar: showReactionBar,
      ),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    ),
  );
}

class _ActionsPage extends StatelessWidget {
  const _ActionsPage({
    required this.bubbleRect,
    required this.bubble,
    required this.mine,
    required this.myReactions,
    required this.onReact,
    required this.actions,
    required this.showReactionBar,
  });

  static const barHeight = 48.0;
  static const menuWidth = 220.0;
  static const rowHeight = 48.0;
  static const gap = 8.0;

  final Rect bubbleRect;
  final Widget bubble;
  final bool mine;
  final Set<String> myReactions;
  final ValueChanged<String> onReact;
  final List<MessageMenuAction> actions;
  final bool showReactionBar;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final menuHeight = actions.length * rowHeight + (actions.length - 1);
    final barWidth = allowedReactions.length * 44.0 + 16;

    final top = showReactionBar
        ? bubbleRect.top - barHeight - gap
        : bubbleRect.top;
    final bottom = bubbleRect.bottom + gap + menuHeight;
    final minTop = media.padding.top + 8;
    final maxBottom = size.height - media.padding.bottom - 8;
    var shift = 0.0;
    if (bottom > maxBottom) shift = maxBottom - bottom;
    if (top + shift < minTop) shift = minTop - top;

    double along(double width) {
      final left = mine ? bubbleRect.right - width : bubbleRect.left;
      return left.clamp(8.0, size.width - width - 8);
    }

    final bubbleTop = bubbleRect.top + shift;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),
          Positioned(
            left: bubbleRect.left,
            top: bubbleTop,
            width: bubbleRect.width,
            height: bubbleRect.height,
            child: Transform.scale(
              scale: 1.02,
              child: Align(
                alignment: mine ? Alignment.topRight : Alignment.topLeft,
                child: bubble,
              ),
            ),
          ),
          if (showReactionBar)
            Positioned(
              left: along(barWidth),
              top: bubbleTop - gap - barHeight,
              child: _ReactionBar(
                selected: myReactions,
                onPick: (emoji) {
                  Navigator.of(context).pop();
                  onReact(emoji);
                },
              ),
            ),
          Positioned(
            left: along(menuWidth),
            top: bubbleTop + bubbleRect.height + gap,
            child: _Menu(actions: actions),
          ),
        ],
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({required this.selected, required this.onPick});

  final Set<String> selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('reaction-bar'),
      height: _ActionsPage.barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? AppColors.dividerDark : AppColors.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final emoji in allowedReactions)
            GestureDetector(
              onTapDown: (_) => HapticFeedback.selectionClick(),
              onTap: () => onPick(emoji),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(emoji)
                      ? scheme.surfaceContainer
                      : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 26, height: 1.1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.actions});

  final List<MessageMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: const ValueKey('message-menu'),
      width: _ActionsPage.menuWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.dividerDark : AppColors.hairline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            _MenuRow(action: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});

  final MessageMenuAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? AppColors.error
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        action.onTap();
      },
      child: SizedBox(
        height: _ActionsPage.rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(action.icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(action.label, style: TextStyle(fontSize: 15, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icons of the menu, in one place.
abstract class MenuIcons {
  static const reply = LucideIcons.reply;
  static const copy = LucideIcons.copy;
  static const unsend = LucideIcons.undo2;
  static const report = LucideIcons.flag;
}
