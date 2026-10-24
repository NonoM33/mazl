import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../widgets/mazl_nav_bar.dart';
import '../widgets/nav_bar_collapse.dart';

/// The couple shell uses the same floating capsule as the dating shell: one
/// bar component, the same 12 pt gap, the same folding while reading down.
class CoupleNavigationScreen extends StatefulWidget {
  const CoupleNavigationScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<CoupleNavigationScreen> createState() => _CoupleNavigationScreenState();
}

class _CoupleNavigationScreenState extends State<CoupleNavigationScreen> {
  final NavBarCollapseController _navBar = NavBarCollapseController();

  List<MazlNavItem> _items(AppLocalizations l10n) => [
    MazlNavItem(icon: LucideIcons.sparkles, label: l10n.coupleSpaceTabActivities),
    MazlNavItem(icon: LucideIcons.calendarHeart, label: l10n.coupleSpaceTabCalendar),
    MazlNavItem(icon: LucideIcons.partyPopper, label: l10n.coupleSpaceTabEvents),
    MazlNavItem(icon: LucideIcons.heart, label: l10n.coupleSpaceTabSpace),
  ];

  @override
  void dispose() {
    _navBar.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _navBar.expand();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _navBar.handleNotification,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _navBar,
        builder: (context, _) => MazlNavBar(
          items: _items(context.l10n),
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
          collapsed: _navBar.collapsed,
          onExpand: _navBar.expand,
        ),
      ),
    );
  }
}
