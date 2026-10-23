import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'reaction_bar.dart';
import 'reaction_drag.dart';

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

/// Long press on a bubble (docs/design/CHAT.md §5): the screen goes under a
/// blurred black veil, the bubble stays where it is, sharp, a reaction bar
/// floats above it and a menu below. Inserted in the ROOT overlay so it covers
/// the tab bar and the composer.
///
/// [drag] carries the finger that is still down from the long press, so it can
/// slide onto an emoji and lift there. That is why this is not a pushed route:
/// pushing one cancels every pointer in progress (Navigator does it on
/// purpose), and the finger would go dead. The system back button still closes
/// the menu first, through a local history entry of the current route.
Future<void> showMessageActions(
  BuildContext context, {
  required Rect bubbleRect,
  required Widget bubble,
  required bool mine,
  required Set<String> myReactions,
  required ValueChanged<String> onReact,
  required List<MessageMenuAction> actions,
  bool showReactionBar = true,
  double? minTop,
  double? maxBottom,
  ReactionDragController? drag,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = navigator.overlay;
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  final host = GlobalKey<_ActionsHostState>();
  LocalHistoryEntry? history;
  late final OverlayEntry entry;

  void dismissed() {
    entry.remove();
    entry.dispose();
    if (!done.isCompleted) done.complete();
  }

  entry = OverlayEntry(
    builder: (context) => _ActionsHost(
      key: host,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      onDismissed: dismissed,
      onClosing: () {
        final pending = history;
        history = null;
        pending?.remove();
      },
      builder: (animation, close) => _ActionsPage(
        animation: animation,
        close: close,
        bubbleRect: bubbleRect,
        bubble: bubble,
        mine: mine,
        myReactions: myReactions,
        onReact: onReact,
        actions: actions,
        showReactionBar: showReactionBar,
        minTop: minTop,
        maxBottom: maxBottom,
        drag: drag,
      ),
    ),
  );
  overlay.insert(entry);

  // The back button (or the back swipe) closes the menu before it leaves the
  // screen: the route under it keeps a local history entry while it is up.
  Route<dynamic>? top;
  navigator.popUntil((route) {
    top = route;
    return true;
  });
  final route = top;
  if (route is LocalHistoryRoute<dynamic>) {
    history = LocalHistoryEntry(
      onRemove: () {
        history = null;
        host.currentState?.close();
      },
    );
    route.addLocalHistoryEntry(history!);
  }
  return done.future;
}

/// Owns the 150 ms in / out animation of the menu and removes it when done.
class _ActionsHost extends StatefulWidget {
  const _ActionsHost({
    super.key,
    required this.duration,
    required this.onDismissed,
    required this.onClosing,
    required this.builder,
  });

  final Duration duration;
  final VoidCallback onDismissed;
  final VoidCallback onClosing;
  final Widget Function(Animation<double> animation, VoidCallback close)
  builder;

  @override
  State<_ActionsHost> createState() => _ActionsHostState();
}

class _ActionsHostState extends State<_ActionsHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _closing = false;

  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    widget.onClosing();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_animation, close);
}

class _ActionsPage extends StatelessWidget {
  const _ActionsPage({
    required this.animation,
    required this.close,
    required this.bubbleRect,
    required this.bubble,
    required this.mine,
    required this.myReactions,
    required this.onReact,
    required this.actions,
    required this.showReactionBar,
    required this.minTop,
    required this.maxBottom,
    required this.drag,
  });

  static const barHeight = ReactionBar.height;
  static const menuWidth = 220.0;
  static const rowHeight = 48.0;
  static const gap = 8.0;
  static const blurSigma = 16.0;

  final Animation<double> animation;
  final VoidCallback close;
  final Rect bubbleRect;
  final Widget bubble;
  final bool mine;
  final Set<String> myReactions;
  final ValueChanged<String> onReact;
  final List<MessageMenuAction> actions;
  final bool showReactionBar;
  final ReactionDragController? drag;

  /// Free band of the screen, in global coordinates: the reaction bar stays
  /// below [minTop] (the header) and the menu above [maxBottom] (the composer).
  final double? minTop;
  final double? maxBottom;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    // Rows, the hairlines between them, and the 1 px border around the card.
    final menuHeight = actions.length * rowHeight + (actions.length - 1) + 2;
    final barWidth = ReactionBar.width;

    final low = minTop ?? media.padding.top + 8;
    final high = maxBottom ?? size.height - media.padding.bottom - 8;
    final barSpace = showReactionBar ? barHeight + gap : 0.0;
    // A bubble taller than what is left is trimmed (clipped) so the bar and
    // the menu always fit in the free band.
    final room = high - low - barSpace - gap - menuHeight;
    final bubbleHeight = bubbleRect.height <= room
        ? bubbleRect.height
        : room.clamp(48.0, bubbleRect.height);
    final top = bubbleRect.top - barSpace;
    final bottom = bubbleRect.top + bubbleHeight + gap + menuHeight;
    var shift = 0.0;
    if (bottom > high) shift = high - bottom;
    if (top + shift < low) shift = low - top;

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
              onTap: close,
              child: Semantics(
                label: 'Fermer le menu',
                button: true,
                child: _Veil(animation: animation),
              ),
            ),
          ),
          Positioned(
            left: bubbleRect.left,
            top: bubbleTop,
            width: bubbleRect.width,
            height: bubbleHeight,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
              child: ClipRect(
                child: OverflowBox(
                  alignment: mine ? Alignment.topRight : Alignment.topLeft,
                  minHeight: 0,
                  maxHeight: bubbleRect.height,
                  maxWidth: bubbleRect.width,
                  child: bubble,
                ),
              ),
            ),
          ),
          if (showReactionBar)
            Positioned(
              left: along(barWidth),
              top: bubbleTop - gap - barHeight,
              child: FadeTransition(
                opacity: animation,
                child: ReactionBar(
                  selected: myReactions,
                  mine: mine,
                  drag: drag,
                  onPick: (emoji) {
                    close();
                    onReact(emoji);
                  },
                ),
              ),
            ),
          Positioned(
            left: along(menuWidth),
            top: bubbleTop + bubbleHeight + gap,
            child: FadeTransition(
              opacity: animation,
              child: _Menu(actions: actions, close: close),
            ),
          ),
        ],
      ),
    );
  }
}

/// The black veil (20 % in light, 40 % in dark) over a blur of the screen: the
/// one blur of the app. Without animations there is no blur, the veil alone at
/// 40 %.
class _Veil extends StatelessWidget {
  const _Veil({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final alpha = noMotion || dark ? 0.4 : 0.2;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final veil = ColoredBox(
          key: const ValueKey('overlay-veil'),
          color: Colors.black.withValues(
            alpha: noMotion ? alpha : alpha * animation.value,
          ),
        );
        if (noMotion) return veil;
        final sigma = _ActionsPage.blurSigma * animation.value;
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: veil,
          ),
        );
      },
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.actions, required this.close});

  final List<MessageMenuAction> actions;
  final VoidCallback close;

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
            _MenuRow(action: actions[i], close: close),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action, required this.close});

  final MessageMenuAction action;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final color = action.destructive
        ? AppColors.error
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () {
        close();
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
