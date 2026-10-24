import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/mazl_nav_bar.dart';

/// The couple shell uses the same frame as the dating shell: one bar
/// component (the floating capsule, or the rail on a regular window), the
/// same 12 pt gap, the same folding while reading down.
class CoupleNavigationScreen extends StatelessWidget {
  const CoupleNavigationScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  List<MazlNavItem> _items(AppLocalizations l10n) => [
    MazlNavItem(icon: LucideIcons.sparkles, label: l10n.coupleSpaceTabActivities),
    MazlNavItem(icon: LucideIcons.calendarHeart, label: l10n.coupleSpaceTabCalendar),
    MazlNavItem(icon: LucideIcons.partyPopper, label: l10n.coupleSpaceTabEvents),
    MazlNavItem(icon: LucideIcons.heart, label: l10n.coupleSpaceTabSpace),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    items: _items(context.l10n),
    currentIndex: navigationShell.currentIndex,
    onSelect: (index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    ),
    body: navigationShell,
  );
}
