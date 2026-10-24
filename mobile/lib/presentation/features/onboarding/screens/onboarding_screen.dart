import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../common/widgets/mazl_components.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Bienvenue sur MAZL',
      description: "L'application de rencontres pensée pour la communauté juive.",
    ),
    OnboardingPage(
      title: 'Trouvez votre mazal',
      description:
          'Découvrez des profils compatibles avec vos valeurs et votre pratique.',
    ),
    OnboardingPage(
      title: 'Mode Couple',
      description:
          "Une fois l'amour trouvé, MAZL vous accompagne : trouvez l'amour, et gardez-le.",
      features: [
        'Questions quotidiennes',
        'Milestones de couple',
        'Calendrier juif partagé',
        'Activités et suggestions',
      ],
    ),
    OnboardingPage(
      title: 'Mode Shabbat',
      description:
          'Une pause automatique pendant Shabbat et les fêtes, sans rien à régler.',
    ),
    OnboardingPage(
      title: 'AI Shadchan',
      description:
          "Notre intelligence artificielle vous aide à trouver la bonne personne.",
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) {
      context.go(RoutePaths.login);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                child: TextButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: Text(
                    'Passer',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingPageView(
                  page: _pages[index],
                  index: index,
                  total: _pages.length,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressBars(current: _currentPage, total: _pages.length),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_isLastPage ? 'Commencer' : 'Continuer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.page,
    required this.index,
    required this.total,
  });

  final OnboardingPage page;
  final int index;
  final int total;

  String get _step =>
      '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(_step),
          const SizedBox(height: 16),
          Text(page.title, style: theme.textTheme.displaySmall),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              page.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (page.features.isNotEmpty) ...[
            const SizedBox(height: 32),
            for (var i = 0; i < page.features.length; i++)
              _FeatureLine(
                text: page.features[i],
                last: i == page.features.length - 1,
              ),
          ],
        ],
      ),
    );
  }
}

/// Une ligne de la liste du mode Couple, séparée par un filet.
class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text, required this.last});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface),
      ),
    );
  }
}

/// Progression : barre d'encre pour la page courante, filet pour les autres.
class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Page ${current + 1} sur $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Container(
              width: i == current ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: i == current ? scheme.onSurface : scheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final List<String> features;

  const OnboardingPage({
    required this.title,
    required this.description,
    this.features = const [],
  });
}
