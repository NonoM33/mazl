import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/data_prefetch_service.dart';
import '../widgets/mazl_nav_bar.dart';
import '../widgets/nav_bar_collapse.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final DataPrefetchService _prefetchService = DataPrefetchService();
  final NavBarCollapseController _navBar = NavBarCollapseController();

  @override
  void initState() {
    super.initState();
    // Initialize data sequentially to avoid socket exhaustion
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    // Prefetch all data for smooth navigation
    await _prefetchService.prefetchAll();
  }

  @override
  void dispose() {
    _navBar.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    _navBar.expand();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  static const _items = [
    MazlNavItem(icon: LucideIcons.layers, label: 'Découvrir'),
    MazlNavItem(icon: LucideIcons.heart, label: 'Matchs'),
    MazlNavItem(icon: LucideIcons.messageCircle, label: 'Messages'),
    MazlNavItem(icon: LucideIcons.calendar, label: 'Événements'),
    MazlNavItem(icon: LucideIcons.user, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Scrolling down a tab folds the bar into its icon; a fast scroll up,
      // the top of the page or a tap on the icon unfolds it.
      body: NotificationListener<ScrollNotification>(
        onNotification: _navBar.handleNotification,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _navBar,
        builder: (context, _) => MazlNavBar(
          items: _items,
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
          collapsed: _navBar.collapsed,
          onExpand: _navBar.expand,
        ),
      ),
    );
  }
}
