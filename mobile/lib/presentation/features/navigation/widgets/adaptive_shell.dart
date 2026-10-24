import 'package:flutter/material.dart';

import '../../../../core/layout/content_max_width.dart';
import '../../../../core/layout/safe_insets.dart';
import '../../../../core/layout/window_size.dart';
import 'mazl_nav_bar.dart';
import 'nav_bar_collapse.dart';

/// Share of the content area given to the list of a two-pane tab, and its
/// bounds in points. The detail pane takes the rest.
const double kListPaneFraction = 0.38;
const double kListPaneMinWidth = 260;
const double kListPaneMaxWidth = 400;

/// Width of the list pane of a two-pane tab whose content area is [region] wide.
double listPaneWidth(double region) =>
    (region * kListPaneFraction).clamp(kListPaneMinWidth, kListPaneMaxWidth).toDouble();

/// The frame around the tabs of the app, whatever the size of the window.
///
/// * Compact: the page, and the ink capsule floating at the bottom.
/// * Regular: the capsule turns into a vertical rail on the leading side; a
///   single-column tab is centered in [kContentMaxWidth]; a tab for which
///   [paneFor] gives a widget shows its list on the left and that widget, the
///   detail, on the right (list | detail, two levels of the hierarchy).
///
/// The screens are the same in both: [body] is only moved, never rebuilt, so
/// folding or unfolding the device keeps every tab as it was.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
    this.paneFor,
  });

  final List<MazlNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// The tab pages (the branches' navigators).
  final Widget body;

  /// The detail pane of tab [index] on a regular window, or `null` for a
  /// single-column tab.
  final Widget? Function(BuildContext context, int index)? paneFor;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final NavBarCollapseController _navBar = NavBarCollapseController();
  // The body moves between the compact and the regular frame in one frame
  // without being rebuilt from scratch.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'adaptive-shell-body');

  @override
  void dispose() {
    _navBar.dispose();
    super.dispose();
  }

  void _select(int index) {
    _navBar.expand();
    widget.onSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    return isRegularWidth(context) ? _buildRegular(context, body) : _buildCompact(body);
  }

  Widget _buildCompact(Widget body) => Scaffold(
    extendBody: true,
    // Scrolling down a tab folds the bar into its icon; a fast scroll up,
    // the top of the page or a tap on the icon unfolds it.
    body: SafeArea(
      top: false,
      bottom: false,
      child: NotificationListener<ScrollNotification>(onNotification: _navBar.handleNotification, child: body),
    ),
    bottomNavigationBar: ListenableBuilder(
      listenable: _navBar,
      builder: (context, _) => MazlNavBar(
        items: widget.items,
        currentIndex: widget.currentIndex,
        onTap: _select,
        collapsed: _navBar.collapsed,
        onExpand: _navBar.expand,
      ),
    ),
  );

  Widget _buildRegular(BuildContext context, Widget body) {
    final safe = MediaQuery.paddingOf(context);
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final region =
        MediaQuery.sizeOf(context).width - MazlNavRail.reservedWidth(safe, direction) - safe.endFor(direction);
    final pane = widget.paneFor?.call(context, widget.currentIndex);
    final railWidth = MazlNavRail.reservedWidth(safe, direction);
    // The rail comes AFTER the pages in paint order, like the bottom capsule in
    // the Scaffold: the barrier of a page blocks the semantics (VoiceOver) of
    // everything painted before it, which would hide a rail drawn first.
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: railWidth),
              // The rail already took the leading inset (left, or right when
              // reading right to left); the trailing one is left free for the
              // system controls on that edge.
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: !rtl,
                removeRight: rtl,
                child: SafeArea(
                  left: rtl,
                  right: !rtl,
                  top: false,
                  bottom: false,
                  child: pane == null
                      ? ContentMaxWidth(child: body)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: listPaneWidth(region), child: body),
                            const _PaneDivider(),
                            Expanded(child: ClipRect(child: pane)),
                          ],
                        ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: railWidth,
            child: MazlNavRail(items: widget.items, currentIndex: widget.currentIndex, onTap: _select),
          ),
        ],
      ),
    );
  }
}

class _PaneDivider extends StatelessWidget {
  const _PaneDivider();

  @override
  Widget build(BuildContext context) => VerticalDivider(
    width: 1,
    thickness: 1,
    color: Theme.of(context).dividerTheme.color ?? Theme.of(context).colorScheme.outlineVariant,
  );
}

/// What the detail pane says while nothing is selected in the list.
class EmptyDetailPane extends StatelessWidget {
  const EmptyDetailPane({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.4, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
