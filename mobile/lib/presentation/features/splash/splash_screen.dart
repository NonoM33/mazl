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
      // The couple state must be known before the router decides: the guard
      // then sends a member in a couple to /couple/activities by itself.
      await CoupleService().initialize();
      if (!mounted) return;
      context.go(RoutePaths.discover);
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
