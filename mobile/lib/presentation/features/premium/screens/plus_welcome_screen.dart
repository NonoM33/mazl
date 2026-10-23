import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../common/widgets/mazl_components.dart';

/// Écran affiché juste après un achat réussi : trois façons de commencer.
class PlusWelcomeScreen extends StatefulWidget {
  const PlusWelcomeScreen({super.key, this.planLabel, this.loadLikesCount});

  /// Durée de la formule (« 6 mois »). Par défaut, celle de l'abonnement actif.
  final String? planLabel;

  /// Nombre de personnes qui ont aimé le profil. Par défaut, l'API.
  final Future<int?> Function()? loadLikesCount;

  @override
  State<PlusWelcomeScreen> createState() => _PlusWelcomeScreenState();
}

class _PlusWelcomeScreenState extends State<PlusWelcomeScreen> {
  int? _likesCount;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<int?> _fetchLikesCount() async {
    final response = await ApiService().getReceivedLikesCount();
    return response.success ? response.data : null;
  }

  Future<void> _loadLikes() async {
    int? count;
    try {
      count = await (widget.loadLikesCount ?? _fetchLikesCount)();
    } catch (e) {
      debugPrint('PlusWelcome: likes count unavailable - $e');
    }
    if (mounted) setState(() => _likesCount = count);
  }

  String get _likesTitle {
    final count = _likesCount;
    if (count == null || count <= 0) return 'Voir qui vous a aimé';
    return count == 1
        ? '1 personne vous a aimé'
        : '$count personnes vous ont aimé';
  }

  void _later() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(RoutePaths.discover);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plan = widget.planLabel ?? RevenueCatService().activePlanLabel;
    final eyebrow = plan == null
        ? 'Abonnement actif'
        : 'Abonnement actif · $plan';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(eyebrow),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          text: 'Bienvenue dans ',
                          children: [
                            const TextSpan(text: 'mazl'),
                            TextSpan(
                              text: '+',
                              style: TextStyle(color: scheme.primary),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        semanticsLabel: 'Bienvenue dans mazl+.',
                        style: Theme.of(context).textTheme.displayMedium!
                            .copyWith(
                              fontSize: 48,
                              letterSpacing: -2.6,
                              height: 0.98,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tout est déverrouillé. Par où commencer ?',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 17,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _ActionRow(
                        icon: LucideIcons.heart,
                        title: _likesTitle,
                        detail: 'Les voir maintenant',
                        inverted: true,
                        onTap: () => context.push(RoutePaths.likes),
                      ),
                      const SizedBox(height: 10),
                      _ActionRow(
                        icon: LucideIcons.zap,
                        title: 'Lancer votre Boost',
                        detail: 'En tête de pile pendant 30 minutes',
                        onTap: () => context.go(RoutePaths.discover),
                      ),
                      const SizedBox(height: 10),
                      _ActionRow(
                        icon: LucideIcons.slidersHorizontal,
                        title: 'Affiner vos filtres',
                        detail: 'Pratique, communauté, et plus',
                        onTap: () => context.push(RoutePaths.filters),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _later,
                  child: const Text('Plus tard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.inverted = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  /// Rangée d'encre (action principale) plutôt que de brume.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = inverted ? scheme.onSurface : scheme.surfaceContainer;
    final foreground = inverted ? scheme.surface : scheme.onSurface;
    final secondary = inverted
        ? scheme.surface.withValues(alpha: 0.65)
        : scheme.onSurfaceVariant;
    final badge = inverted ? scheme.primary : scheme.surface;
    final badgeIcon = inverted ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: badge,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: badgeIcon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: TextStyle(fontSize: 13, color: secondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
