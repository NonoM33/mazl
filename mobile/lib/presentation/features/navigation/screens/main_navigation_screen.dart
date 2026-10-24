import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/adaptive_detail.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/mazl_nav_bar.dart';

/// Builds the screen of a detail (a conversation, a match's profile). Given by
/// the router, which owns the screens.
typedef DetailScreenBuilder = Widget Function(BuildContext context, DetailTarget target);

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
    this.buildDetail,
    this.prefetch,
  });

  /// Index of the tabs that split into a list and a detail on a regular window.
  static const matchesTab = 1;
  static const messagesTab = 2;

  final StatefulNavigationShell navigationShell;
  /// Without it the detail pane stays empty (tests of the frame only).
  final DetailScreenBuilder? buildDetail;

  /// Warms the caches when the app opens; the data prefetch service by default.
  final Future<void> Function()? prefetch;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data sequentially to avoid socket exhaustion
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    // Prefetch all data for smooth navigation
    await (widget.prefetch ?? DataPrefetchService().prefetchAll)();
  }

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<MazlNavItem> _items(AppLocalizations l10n) => [
    MazlNavItem(icon: LucideIcons.layers, label: l10n.navigationDiscover),
    MazlNavItem(icon: LucideIcons.heart, label: l10n.navigationMatches),
    MazlNavItem(icon: LucideIcons.messageCircle, label: l10n.navigationMessages),
    MazlNavItem(icon: LucideIcons.calendar, label: l10n.navigationEvents),
    MazlNavItem(icon: LucideIcons.user, label: l10n.navigationProfile),
  ];

  /// The right-hand pane of the tab, on a regular window: the detail that the
  /// location opens (the URL is the only truth), or an invitation to pick one.
  Widget? _paneFor(BuildContext context, int index) {
    final l10n = context.l10n;
    final target = DetailTarget.fromUri(GoRouter.of(context).routerDelegate.state.uri);
    switch (index) {
      case MainNavigationScreen.matchesTab:
        return target is MatchProfileDetail && widget.buildDetail != null
            ? _detail(context, target)
            : EmptyDetailPane(title: l10n.layoutPaneProfileTitle, message: l10n.layoutPaneProfileMessage);
      case MainNavigationScreen.messagesTab:
        return target is ChatDetail && widget.buildDetail != null
            ? _detail(context, target)
            : EmptyDetailPane(title: l10n.layoutPaneChatTitle, message: l10n.layoutPaneChatMessage);
    }
    return null;
  }

  Widget _detail(BuildContext context, DetailTarget target) =>
      KeyedSubtree(key: DetailKeys.keyFor(target), child: widget.buildDetail!(context, target));

  @override
  Widget build(BuildContext context) {
    final items = _items(context.l10n);
    return ListenableBuilder(
      listenable: GoRouter.of(context).routerDelegate,
      builder: (context, _) => AdaptiveShell(
        items: items,
        currentIndex: widget.navigationShell.currentIndex,
        onSelect: _onSelect,
        body: widget.navigationShell,
        paneFor: _paneFor,
      ),
    );
  }
}
