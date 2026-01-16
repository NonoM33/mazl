import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/glass_container.dart';
import '../../../common/widgets/mazl_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bienvenue sur MAZL',
      description:
          'L\'application de rencontre pensée pour la communauté juive',
      icon: LucideIcons.star,
      gradient: [AppColors.primary, AppColors.primaryDark],
    ),
    OnboardingPage(
      title: 'Trouve ton mazal',
      description:
          'Découvre des profils compatibles avec tes valeurs et ta pratique',
      icon: LucideIcons.heartHandshake,
      gradient: [AppColors.secondary, AppColors.secondaryDark],
    ),
    OnboardingPage(
      title: 'Shabbat Mode',
      description:
          'Profite d\'une pause automatique pendant Shabbat et les fêtes',
      icon: LucideIcons.moonStar,
      gradient: [AppColors.accentGold, AppColors.shabbatBackground],
    ),
    OnboardingPage(
      title: 'AI Shadchan',
      description:
          'Notre intelligence artificielle t\'aide à trouver la bonne personne',
      icon: LucideIcons.sparkles,
      gradient: [AppColors.accent, AppColors.primary],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pages[_currentPage].gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Page content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: const Text(
                      'Passer',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon or Logo
                            if (index == 0)
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
                                  .fadeIn()
                            else
                              GlassContainer(
                                width: 120,
                                height: 120,
                                borderRadius: 30,
                                opacity: 0.2,
                                child: Center(
                                  child: Icon(
                                    page.icon,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                                  .animate()
                                  .scale(
                                    duration: 600.ms,
                                    curve: Curves.elasticOut,
                                  )
                                  .fadeIn(),

                            const SizedBox(height: 48),

                            // Title
                            Text(
                              page.title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 200.ms).slideY(
                                  begin: 0.3,
                                  end: 0,
                                ),

                            const SizedBox(height: 16),

                            // Description
                            Text(
                              page.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page indicator and button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _currentPage == index ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next/Get Started button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              context.go(RoutePaths.login);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].gradient[0],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Suivant'
                                : 'Commencer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
