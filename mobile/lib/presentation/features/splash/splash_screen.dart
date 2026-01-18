import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/couple_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/widgets/mazl_logo.dart';

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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo MAZL
              const MazlLogoContainer(
                size: 80,
                padding: 20,
                borderRadius: 30,
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // App name
              const Text(
                'MAZL',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Trouve ton mazal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
