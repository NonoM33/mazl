import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Drag a row to the right to reply (docs/design/CHAT.md §6): the row follows
/// the finger up to [threshold], a reply arrow appears in the left margin and
/// turns accent at the threshold with a light haptic; releasing past it replies.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply, this.enabled = true});

  static const threshold = 64.0;

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
    ..addListener(() => setState(() => _dx = _from * (1 - Curves.easeOutCubic.transform(_back.value))));
  double _dx = 0;
  double _from = 0;
  bool _armed = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    // Past the threshold the row resists instead of following one to one.
    final raw = _dx + (_dx >= SwipeToReply.threshold ? d.delta.dx * 0.25 : d.delta.dx);
    final next = raw.clamp(0.0, SwipeToReply.threshold + 24);
    final armed = next >= SwipeToReply.threshold;
    if (armed && !_armed) HapticFeedback.lightImpact();
    setState(() {
      _dx = next;
      _armed = armed;
    });
  }

  void _cancel() {
    _armed = false;
    _end();
  }

  void _end([DragEndDetails? details]) {
    if (_armed) widget.onReply();
    _armed = false;
    _from = _dx;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _dx = 0);
    } else {
      _back.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final progress = (_dx / SwipeToReply.threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _cancel,
      child: Stack(
        children: [
          if (_dx > 0)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * progress,
                      child: Icon(LucideIcons.reply, size: 20, color: _armed ? scheme.primary : scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}
