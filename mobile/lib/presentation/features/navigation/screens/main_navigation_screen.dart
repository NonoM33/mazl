import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/couple_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../couple/widgets/couple_request_dialog.dart';
import '../widgets/mazl_nav_bar.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize data sequentially to avoid socket exhaustion
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    // Prefetch all data for smooth navigation
    await _prefetchService.prefetchAll();
    // Check couple mode status and redirect if needed
    await _checkCoupleMode();
    // Check for couple requests
    await _checkCoupleRequests();
  }

  Future<void> _checkCoupleMode() async {
    await _coupleService.initialize();
    if (mounted && _coupleService.isCoupleModeEnabled) {
      // Auto-redirect to couple dashboard if couple mode is enabled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/couple/activities');
        }
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
              // Navigate to couple dashboard
              context.go('/couple/activities');
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
      body: widget.navigationShell,
      bottomNavigationBar: MazlNavBar(
        items: _items,
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}
