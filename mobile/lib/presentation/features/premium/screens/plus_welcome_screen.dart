import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/plus_widgets.dart';

/// Écran affiché juste après un achat réussi : trois façons de commencer.
class PlusWelcomeScreen extends StatefulWidget {
  const PlusWelcomeScreen({super.key, this.planMonths, this.loadLikesCount});

  /// Durée de la formule, en mois. Par défaut, celle de l'abonnement actif.
  final int? planMonths;

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

  String _likesTitle(AppLocalizations l10n) {
    final count = _likesCount;
    if (count == null || count <= 0) {
      return l10n.plusFeatureSeeWhoLikesYouTitle;
    }
    return l10n.plusWelcomeLikesCount(count);
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
    final l10n = context.l10n;
    final months = widget.planMonths ?? SubscriptionService().activePlanMonths;
    final eyebrow = months == null
        ? l10n.plusActiveSubscription
        : l10n.plusActiveSubscriptionPlan(l10n.plusMonths(months));

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(eyebrow),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: brandPhraseSpans(l10n.plusWelcomeTitle, [
              const TextSpan(text: 'mazl'),
              TextSpan(
                text: '+',
                style: TextStyle(color: scheme.primary),
              ),
            ]),
          ),
          semanticsLabel: l10n.plusWelcomeTitle,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            fontSize: 48,
            letterSpacing: -2.6,
            height: 0.98,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.plusWelcomeSubtitle,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 17,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionRow(
          icon: LucideIcons.heart,
          title: _likesTitle(l10n),
          detail: l10n.plusWelcomeLikesDetail,
          inverted: true,
          onTap: () => context.push(RoutePaths.likes),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: LucideIcons.zap,
          title: l10n.plusWelcomeBoostTitle,
          detail: l10n.plusWelcomeBoostDetail,
          onTap: () => context.go(RoutePaths.discover),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: LucideIcons.slidersHorizontal,
          title: l10n.plusWelcomeFiltersTitle,
          detail: l10n.plusWelcomeFiltersDetail,
          onTap: () => context.push(RoutePaths.filters),
        ),
      ],
    );
    final later = FoldSafeActions(
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: TextButton(onPressed: _later, child: Text(l10n.commonLater)),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: FoldCutBuilder(
          builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
              // Held like a book: the greeting on the reading-start page,
              // the three ways to begin and "later" on the other.
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: cut!.leadExtent,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                        child: intro,
                      ),
                    ),
                    SizedBox(width: cut.gap),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(child: actions),
                            ),
                            later,
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              intro,
                              const SizedBox(height: 36),
                              actions,
                            ],
                          ),
                        ),
                      ),
                      later,
                    ],
                  ),
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
    final badge = inverted ? scheme.primaryContainer : scheme.surface;
    final badgeIcon = inverted ? scheme.onPrimaryContainer : scheme.onSurface;

    return Semantics(
      button: true,
      label: context.l10n.plusTitleDetail(title, detail),
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
                  DirectionalIcon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: foreground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
