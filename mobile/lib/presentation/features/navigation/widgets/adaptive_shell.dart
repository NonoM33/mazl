import 'package:flutter/material.dart';

import '../../../../core/layout/content_max_width.dart';
import '../../../../core/layout/fold_state.dart';
import '../../../../core/layout/safe_insets.dart';
import '../../../../core/layout/vertical_bar.dart';
import '../../../../core/layout/window_size.dart';
import 'mazl_nav_bar.dart';
import 'nav_bar_collapse.dart';

/// Share of the content area given to the list of a two-pane tab, and its
/// bounds in points. The detail pane takes the rest.
const double kListPaneFraction = 0.38;
const double kListPaneMinWidth = 260;
const double kListPaneMaxWidth = 400;

/// Widest the bottom capsule grows on a regular window: a phone's width.
const double kBottomBarMaxWidth = 480;

/// Width of the list pane of a two-pane tab whose content area is [region] wide.
double listPaneWidth(double region) => (region * kListPaneFraction)
    .clamp(kListPaneMinWidth, kListPaneMaxWidth)
    .toDouble();

/// The frame around the tabs of the app, whatever the size of the window.
///
/// Where the tabs go follows the system, as Apple's own tab bar does:
/// * A vertical bar (foldable iPhone closed, or held sideways, or half open
///   like a book): the tabs are an icon capsule at the bottom of that column,
///   below the status bar ([MazlNavStrip]); the page takes the rest.
/// * Compact window: the page, and the ink capsule floating at the bottom.
/// * Regular window on iOS (inner display held upright, the one pose where
///   Apple keeps horizontal bars): the capsule stays at the bottom.
/// * Regular window elsewhere (web, desktop): a vertical rail on the leading
///   side.
/// On a regular window a single-column tab is centered in [kContentMaxWidth];
/// a tab for which [paneFor] gives a widget shows its list on the left and
/// that widget, the detail, on the right (list | detail, two levels of the
/// hierarchy). Half open like a book, the fold is the line between them.
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
    final verticalBar = VerticalBarScope.geometryOf(context);
    final regular = isRegularWidth(context);
    if (verticalBar != null) {
      return _buildWithVerticalBar(
        context,
        body,
        verticalBar,
        regular: regular,
      );
    }
    if (!regular) return _buildCompact(body);
    return Theme.of(context).platform == TargetPlatform.iOS
        ? _buildRegularWithBottomBar(context, body)
        : _buildRegular(context, body);
  }

  MazlNavBar _bottomBar() => MazlNavBar(
    items: widget.items,
    currentIndex: widget.currentIndex,
    onTap: _select,
    collapsed: _navBar.collapsed,
    onExpand: _navBar.expand,
  );

  /// The tabs in the system's vertical bar; the page fills the safe area.
  Widget _buildWithVerticalBar(
    BuildContext context,
    Widget body,
    VerticalBarGeometry bar, {
    required bool regular,
  }) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          top: false,
          bottom: false,
          child: regular ? _panes(context, body, bar: bar) : body,
        ),
        VerticalBarPublisher(
          bar: MazlNavStrip(
            items: widget.items,
            currentIndex: widget.currentIndex,
            onTap: _select,
          ),
        ),
      ],
    ),
  );

  /// The inner display held upright: horizontal bars, so the capsule at the
  /// bottom, no wider than a phone's, over the regular content.
  Widget _buildRegularWithBottomBar(BuildContext context, Widget body) =>
      Scaffold(
        extendBody: true,
        body: SafeArea(
          top: false,
          bottom: false,
          child: NotificationListener<ScrollNotification>(
            onNotification: _navBar.handleNotification,
            child: _panes(context, body),
          ),
        ),
        bottomNavigationBar: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kBottomBarMaxWidth),
            child: ListenableBuilder(
              listenable: _navBar,
              builder: (context, _) => _bottomBar(),
            ),
          ),
        ),
      );

  /// The content of a regular window: one readable column, or list | detail.
  /// With a [bar] and a fold down the middle (half open like a book), the list
  /// ends where the fold begins and the detail starts where it ends.
  Widget _panes(BuildContext context, Widget body, {VerticalBarGeometry? bar}) {
    final pane = widget.paneFor?.call(context, widget.currentIndex);
    if (pane == null) return ContentMaxWidth(child: body);
    return LayoutBuilder(
      builder: (context, constraints) {
        final region = constraints.maxWidth;
        final split = bar == null
            ? null
            : _foldSplit(FoldScope.of(context), bar, region);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: split?.list ?? listPaneWidth(region), child: body),
            if (split == null)
              const _PaneDivider()
            else
              SizedBox(width: split.gap),
            Expanded(child: ClipRect(child: pane)),
          ],
        );
      },
    );
  }

  /// Where a vertical fold cuts a content area [region] wide that starts after
  /// the vertical bar when the bar is on the left; `null` without a usable fold.
  static ({double list, double gap})? _foldSplit(
    FoldState fold,
    VerticalBarGeometry bar,
    double region,
  ) {
    final division = fold.activeDivision;
    if (division == null || division.height <= division.width) return null;
    final start = bar.side == VerticalBarSide.left ? bar.strip.width : 0.0;
    final list = division.left - start;
    if (list < kListPaneMinWidth ||
        region - list - division.width < kListPaneMinWidth) {
      return null;
    }
    return (list: list, gap: division.width);
  }

  Widget _buildCompact(Widget body) => Scaffold(
    extendBody: true,
    // Scrolling down a tab folds the bar into its icon; a fast scroll up,
    // the top of the page or a tap on the icon unfolds it.
    body: SafeArea(
      top: false,
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: _navBar.handleNotification,
        child: body,
      ),
    ),
    bottomNavigationBar: ListenableBuilder(
      listenable: _navBar,
      builder: (context, _) => _bottomBar(),
    ),
  );

  Widget _buildRegular(BuildContext context, Widget body) {
    final safe = MediaQuery.paddingOf(context);
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final region =
        MediaQuery.sizeOf(context).width -
        MazlNavRail.reservedWidth(safe, direction) -
        safe.endFor(direction);
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
            child: MazlNavRail(
              items: widget.items,
              currentIndex: widget.currentIndex,
              onTap: _select,
            ),
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
    color:
        Theme.of(context).dividerTheme.color ??
        Theme.of(context).colorScheme.outlineVariant,
  );
}

/// What the detail pane says while nothing is selected in the list.
class EmptyDetailPane extends StatelessWidget {
  const EmptyDetailPane({
    super.key,
    required this.title,
    required this.message,
  });

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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
