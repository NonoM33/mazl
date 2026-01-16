import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/couple_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../couple/widgets/couple_request_dialog.dart';

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
  final CoupleService _coupleService = CoupleService();
  bool _hasShownRequest = false;
  bool _isCoupleModeEnabled = false;

  @override
  void initState() {
    super.initState();
    // Prefetch all data for smooth navigation
    _prefetchService.prefetchAll();
    // Check for couple requests
    _checkCoupleRequests();
    // Check couple mode status
    _checkCoupleMode();
  }

  Future<void> _checkCoupleMode() async {
    await _coupleService.initialize();
    if (mounted) {
      setState(() {
        _isCoupleModeEnabled = _coupleService.isCoupleModeEnabled;
      });
    }
  }

  Future<void> _checkCoupleRequests() async {
    await _coupleService.fetchPendingRequests();
    final request = _coupleService.receivedRequest;

    if (request != null && !_hasShownRequest && mounted) {
      setState(() => _hasShownRequest = true);

      // Show the couple request dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CoupleRequestDialog.show(
            context,
            request,
            onAccepted: () {
              // Update couple mode status and navigate to couple dashboard
              setState(() => _isCoupleModeEnabled = true);
              context.go('/couple/dashboard');
            },
            onRejected: () {
              // Just dismiss, stay on current screen
            },
          );
        }
      });
    }
  }

  void _onTap(BuildContext context, int index) {
    // In couple mode, redirect certain tabs
    if (_isCoupleModeEnabled) {
      if (index == 0) {
        // Discover -> Couple Dashboard
        context.go('/couple/dashboard');
        return;
      }
      if (index == 1) {
        // Matches -> Just go to partner's chat
        // For now, go to chat tab
        widget.navigationShell.goBranch(2, initialLocation: false);
        return;
      }
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _isCoupleModeEnabled
                  ? _buildCoupleNavItems()
                  : _buildNormalNavItems(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNormalNavItems() {
    return [
      _NavBarItem(
        icon: LucideIcons.compass,
        activeIcon: LucideIcons.compass,
        label: 'Decouvrir',
        isSelected: widget.navigationShell.currentIndex == 0,
        onTap: () => _onTap(context, 0),
      ),
      _NavBarItem(
        icon: LucideIcons.heart,
        activeIcon: LucideIcons.heart,
        label: 'Matchs',
        isSelected: widget.navigationShell.currentIndex == 1,
        onTap: () => _onTap(context, 1),
      ),
      _NavBarItem(
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: 'Chat',
        isSelected: widget.navigationShell.currentIndex == 2,
        onTap: () => _onTap(context, 2),
        badge: 3, // TODO: Get from state
      ),
      _NavBarItem(
        icon: LucideIcons.calendar,
        activeIcon: LucideIcons.calendar,
        label: 'Events',
        isSelected: widget.navigationShell.currentIndex == 3,
        onTap: () => _onTap(context, 3),
      ),
      _NavBarItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profil',
        isSelected: widget.navigationShell.currentIndex == 4,
        onTap: () => _onTap(context, 4),
      ),
    ];
  }

  List<Widget> _buildCoupleNavItems() {
    return [
      _NavBarItem(
        icon: LucideIcons.heartHandshake,
        activeIcon: LucideIcons.heartHandshake,
        label: 'Couple',
        isSelected: widget.navigationShell.currentIndex == 0,
        onTap: () => context.go('/couple/dashboard'),
        isCoupleModeItem: true,
      ),
      _NavBarItem(
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: 'Messages',
        isSelected: widget.navigationShell.currentIndex == 2,
        onTap: () => _onTap(context, 2),
        isCoupleModeItem: true,
      ),
      _NavBarItem(
        icon: LucideIcons.calendar,
        activeIcon: LucideIcons.calendar,
        label: 'Events',
        isSelected: widget.navigationShell.currentIndex == 3,
        onTap: () => _onTap(context, 3),
      ),
      _NavBarItem(
        icon: LucideIcons.user,
        activeIcon: LucideIcons.user,
        label: 'Profil',
        isSelected: widget.navigationShell.currentIndex == 4,
        onTap: () => _onTap(context, 4),
      ),
    ];
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.isCoupleModeItem = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  final bool isCoupleModeItem;

  // Couple mode uses a pink/rose accent
  static const _coupleAccent = Color(0xFFFF6B9D);

  @override
  Widget build(BuildContext context) {
    final accentColor = isCoupleModeItem ? _coupleAccent : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? accentColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 24,
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCoupleModeItem ? _coupleAccent : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge! > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
