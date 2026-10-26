import 'package:flutter/material.dart';

import 'vertical_bar.dart';
import 'window_size.dart';

/// A screen that is the "detail" of a list: an open conversation, the profile
/// of a match. Its URL stays the single source of truth: on a compact window
/// the route is a full-screen page, on a regular window the same route opens
/// the detail pane of the tab shell. Folding or unfolding the device only
/// changes where the screen is drawn, never which one is open.
@immutable
sealed class DetailTarget {
  const DetailTarget();

  /// The detail a location opens, or `null` when it opens none:
  /// `/chat/:conversationId` and `/matches/profile/:userId`.
  static DetailTarget? fromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length == 2 &&
        segments[0] == 'chat' &&
        segments[1].isNotEmpty) {
      return ChatDetail(segments[1]);
    }
    if (segments.length == 3 &&
        segments[0] == 'matches' &&
        segments[1] == 'profile' &&
        segments[2].isNotEmpty) {
      return MatchProfileDetail(segments[2]);
    }
    return null;
  }
}

final class ChatDetail extends DetailTarget {
  const ChatDetail(this.conversationId);

  final String conversationId;

  @override
  bool operator ==(Object other) =>
      other is ChatDetail && other.conversationId == conversationId;

  @override
  int get hashCode => Object.hash(ChatDetail, conversationId);
}

final class MatchProfileDetail extends DetailTarget {
  const MatchProfileDetail(this.userId);

  final String userId;

  @override
  bool operator ==(Object other) =>
      other is MatchProfileDetail && other.userId == userId;

  @override
  int get hashCode => Object.hash(MatchProfileDetail, userId);
}

/// Lets a detail screen move between its two homes (the full-screen route and
/// the shell's pane) without losing its state: the half-typed message, the
/// scroll position. Both homes put the screen under the key of its target; at
/// any width only one of them builds it.
abstract final class DetailKeys {
  static final Map<DetailTarget, GlobalKey> _keys = {};
  static final Set<DetailTarget> _claimed = {};

  static GlobalKey keyFor(DetailTarget target) =>
      _keys.putIfAbsent(target, () => GlobalKey(debugLabel: '$target'));

  /// Called by a page route while it lives. A second page for the same target
  /// (it should not happen) gets `null` and simply builds without the key,
  /// so two widgets never share a [GlobalKey].
  static GlobalKey? claim(DetailTarget target) =>
      _claimed.add(target) ? keyFor(target) : null;

  static void release(DetailTarget target) {
    _claimed.remove(target);
  }

  @visibleForTesting
  static void reset() {
    _keys.clear();
    _claimed.clear();
  }
}

/// Page of a root-level detail route. See [DetailTarget].
class AdaptiveDetailPage<T> extends Page<T> {
  const AdaptiveDetailPage({
    required super.key,
    required this.target,
    required this.child,
    required this.transitionsBuilder,
  });

  final DetailTarget target;

  /// The full-screen screen, used on a compact window.
  final Widget child;
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) => _AdaptiveDetailRoute<T>(this);
}

class _AdaptiveDetailRoute<T> extends PageRoute<T> {
  _AdaptiveDetailRoute(AdaptiveDetailPage<T> page) : super(settings: page);

  AdaptiveDetailPage<T> get _page => settings as AdaptiveDetailPage<T>;

  // The tab shell below must stay alive and visible: on a regular window it
  // draws the detail itself, this route then draws nothing.
  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  /// A full-screen page hides and blocks what is under it; the empty page of a
  /// regular window must let touches and VoiceOver through to the shell.
  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    return Builder(
      builder: (context) =>
          isRegularWidth(context) ? const SizedBox.shrink() : barrier,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _DetailPageBody(target: _page.target, child: _page.child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _page.transitionsBuilder(context, animation, secondaryAnimation, child);
}

class _DetailPageBody extends StatefulWidget {
  const _DetailPageBody({required this.target, required this.child});

  final DetailTarget target;
  final Widget child;

  @override
  State<_DetailPageBody> createState() => _DetailPageBodyState();
}

class _DetailPageBodyState extends State<_DetailPageBody> {
  GlobalKey? _key;

  @override
  void initState() {
    super.initState();
    _key = DetailKeys.claim(widget.target);
  }

  @override
  void dispose() {
    if (_key != null) DetailKeys.release(widget.target);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The shell draws the detail in its pane and keeps its tabs.
    if (isRegularWidth(context)) return const VerticalBarPassThrough();
    // Full screen: the sides belong to the safe area, which is not symmetric
    // on every display.
    return SafeArea(
      top: false,
      bottom: false,
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}
