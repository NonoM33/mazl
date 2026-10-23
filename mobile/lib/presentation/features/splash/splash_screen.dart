import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/couple_service.dart';
import '../../common/widgets/mazl_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check auth state and navigate accordingly
    final authService = AuthService();
    if (authService.isAuthenticated) {
      // Initialize couple service and check couple mode status
      final coupleService = CoupleService();
      await coupleService.initialize();

      if (!mounted) return;

      if (coupleService.isCoupleModeEnabled) {
        // User is in couple mode - go to couple activities
        debugPrint('SplashScreen: Navigating to couple mode');
        context.go('/couple/activities');
      } else {
        // User is in dating mode - go to discover
        debugPrint('SplashScreen: Navigating to discover');
        context.go(RoutePaths.discover);
      }
    } else {
      // User is not logged in - go to onboarding
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: MazlWordmark(size: 56)),
    );
  }
}
