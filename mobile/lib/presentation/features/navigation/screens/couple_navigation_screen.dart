import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/mazl_nav_bar.dart';

/// The couple shell uses the same frame as the dating shell: one bar
/// component (the floating capsule, or the rail on a regular window), the
/// same 12 pt gap, the same folding while reading down. Five tabs, in this
/// order (docs/couple/ESPACE-COUPLE.md §0.3): today, agenda, outings,
/// concierge, us.
class CoupleNavigationScreen extends StatelessWidget {
  const CoupleNavigationScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  List<MazlNavItem> _items(AppLocalizations l10n) => [
    MazlNavItem(icon: LucideIcons.sun, label: l10n.coupleTabToday),
    MazlNavItem(icon: LucideIcons.calendar, label: l10n.coupleTabAgenda),
    MazlNavItem(icon: LucideIcons.mapPin, label: l10n.coupleTabOutings),
    MazlNavItem(
      icon: LucideIcons.conciergeBell,
      label: l10n.coupleTabConcierge,
    ),
    MazlNavItem(icon: LucideIcons.heart, label: l10n.coupleTabUs),
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
