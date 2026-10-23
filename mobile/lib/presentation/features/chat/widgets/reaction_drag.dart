import 'package:flutter/widgets.dart';

/// Carries the finger of a long press to the reaction bar (docs/design/CHAT.md
/// §5). The press began on the bubble, so only the row's gesture recognizer
/// keeps receiving that pointer: the row forwards what it sees here, and the
/// bar, once on screen, [attach]es to turn positions into a hovered emoji.
class ReactionDragController {
  ValueChanged<Offset>? _onMove;
  ValueChanged<Offset>? _onRelease;
  Offset? _lastPosition;

  /// The finger moved, in global coordinates.
  void move(Offset global) {
    _lastPosition = global;
    _onMove?.call(global);
  }

  /// The finger lifted, in global coordinates.
  void release(Offset global) => _onRelease?.call(global);

  /// Called by the bar. Catches up with the finger if it moved before the bar
  /// was built.
  void attach({
    required ValueChanged<Offset> onMove,
    required ValueChanged<Offset> onRelease,
  }) {
    _onMove = onMove;
    _onRelease = onRelease;
    final last = _lastPosition;
    if (last != null) onMove(last);
  }

  void detach() {
    _onMove = null;
    _onRelease = null;
  }
}
