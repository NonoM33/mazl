import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/duo_tutorial/duo_tutorial_policy.dart';
import '../../../core/layout/fold_cut.dart';
import '../../../core/layout/fold_state.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/couple_service.dart';
import '../../../core/services/profile_completeness_service.dart';
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
    final String destination;
    if (authService.isAuthenticated) {
      // The couple state must be known before the router decides: the guard
      // then sends a member in a couple to /couple/activities by itself.
      await CoupleService().initialize();
      // Same for a profile without gender / looking-for: the guard needs the
      // answer before the first screen, or Discover would flash up.
      await ProfileCompletenessService().refresh();
      destination = RoutePaths.discover;
    } else {
      // User is not logged in - go to onboarding
      destination = RoutePaths.onboarding;
    }
    if (!mounted) return;
    // The iPhone Duo tutorial comes first, once, on a foldable iPhone only.
    final showTutorial = await decideDuoTutorialLaunch(
      fold: FoldScope.of(context),
      store: SharedPreferencesDuoTutorialStore(),
    );
    if (!mounted) return;
    context.go(
      showTutorial ? duoTutorialLocation(next: destination) : destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SplashBrand());
  }
}

/// The logo of the splash screen. Flat it sits in the middle of the page;
/// half open the fold would run through it, so it moves to the middle of the
/// reading-start page (above the fold when set down like a laptop, beside it
/// when held like a book); the other page stays empty for these two seconds.
class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  static const _logo = MazlWordmark(size: 56);

  @override
  Widget build(BuildContext context) => FoldCutBuilder(
    builder: (context, cut) {
      if (cut == null) return const Center(child: _logo);
      final lead = SizedBox(
        width: cut.axis == FoldSplitAxis.vertical ? cut.leadExtent : null,
        height: cut.axis == FoldSplitAxis.horizontal ? cut.leadExtent : null,
        child: const Center(child: _logo),
      );
      final gap = SizedBox(
        width: cut.axis == FoldSplitAxis.vertical ? cut.gap : null,
        height: cut.axis == FoldSplitAxis.horizontal ? cut.gap : null,
      );
      return switch (cut.axis) {
        FoldSplitAxis.vertical => Row(
          children: [
            lead,
            gap,
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        FoldSplitAxis.horizontal => Column(
          children: [
            lead,
            gap,
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      };
    },
  );
}
