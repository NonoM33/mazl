import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/store/credits_service.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/plus_text.dart';
import '../widgets/plus_widgets.dart';
import 'package:mazl/core/layout/bar_navigation.dart';

/// Ce que l'écran « Abonnement » affiche.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.isActive,
    this.planMonths,
    this.price,
    this.renewalDate,
    this.willRenew = true,
    this.superLikesLeft = 0,
    this.superLikesMax = 0,
    this.boostAvailable = false,
  });

  /// Lit l'état courant de l'abonnement et du compteur quotidien.
  factory SubscriptionSnapshot.current({
    String? price,
    SubscriptionService? service,
  }) {
    final subscriptions = service ?? SubscriptionService();
    return SubscriptionSnapshot(
      isActive: subscriptions.isMazlPro,
      planMonths: subscriptions.activePlanMonths,
      price: price,
      renewalDate: subscriptions.expirationDate,
      willRenew: subscriptions.willRenew,
      // « Aujourd'hui » : l'inclus du jour que le serveur annonce, pas les
      // crédits achetés (qui n'expirent pas).
      superLikesLeft: CreditsService().balance?.superLike.dailyRemaining ?? 0,
      superLikesMax: PremiumGate.superLikesPerDay,
      boostAvailable: PremiumGate.remainingBoosts > 0,
    );
  }

  final bool isActive;

  /// Durée de la formule, en mois ; null si inconnue.
  final int? planMonths;

  /// Prix de la formule tel que le store l'écrit (« 59,99 € »).
  final String? price;
  final DateTime? renewalDate;
  final bool willRenew;
  final int superLikesLeft;
  final int superLikesMax;
  final bool boostAvailable;

  /// « 6 mois · 59,99 € », ou ce qu'on en sait.
  String formula(AppLocalizations l10n) {
    final months = planMonths;
    final cost = price;
    if (months != null && cost != null) {
      return l10n.plusPlanAndPrice(l10n.plusMonths(months), cost);
    }
    if (months != null) return l10n.plusMonths(months);
    return cost ?? '—';
  }

  String renewalValue(AppLocalizations l10n) {
    final date = renewalDate;
    return date == null ? '—' : plusDateText(l10n, date.toLocal());
  }
}

/// Gestion de l'abonnement mazl+ : formule, échéance, avantages du jour.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.snapshot,
    this.onManage,
    this.service,
  });

  /// Données fixes (tests). Absentes : lues en direct puis rafraîchies.
  final SubscriptionSnapshot? snapshot;

  /// Ouvre la gestion de l'abonnement dans le store. Par défaut : la page
  /// d'abonnements du store.
  final VoidCallback? onManage;

  /// Service d'abonnement, remplaçable dans les tests.
  final SubscriptionService? service;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final SubscriptionService _subscriptions =
      widget.service ?? SubscriptionService();
  late SubscriptionSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot =
        widget.snapshot ??
        SubscriptionSnapshot.current(service: widget.service);
    // Après la première image : le service prévient ses écouteurs, ce qui est
    // interdit pendant la construction.
    if (widget.snapshot == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    await _subscriptions.refresh();
    await CreditsService().refresh();
    final price = await _subscriptions.activePlanPrice();
    if (mounted) {
      setState(
        () => _snapshot = SubscriptionSnapshot.current(
          price: price,
          service: widget.service,
        ),
      );
    }
  }

  Future<void> _manage() async {
    if (widget.onManage != null) {
      widget.onManage!();
      return;
    }
    final opened = await _subscriptions.manageSubscriptions();
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.plusManageFailed)));
    }
  }

  Future<void> _restore() async {
    final result = await _subscriptions.restore();
    if (!mounted) return;
    setState(
      () => _snapshot = SubscriptionSnapshot.current(service: widget.service),
    );
    final l10n = context.l10n;
    final message = switch (result) {
      RestoreFound() => l10n.plusPurchasesRestored,
      RestoreNothing() => l10n.plusNothingToRestore,
      RestoreFailed(:final problem) => purchaseProblemText(l10n, problem),
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Its own `onPressed` on this page's context: with a vertical bar the
    // button is drawn above the navigator.
    Widget back() => RoundIconButton(
      icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
      tooltip: l10n.commonBack,
      onPressed: () => context.pop(),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarNavigation(
                buttons: [back()],
                inline: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [back(), const SizedBox(height: 24)],
                ),
              ),
              Text(
                l10n.plusSubscriptionTitle,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall!.copyWith(letterSpacing: -2),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: snapshot.isActive
                      ? _ActiveBody(snapshot: snapshot)
                      : const _InactiveBody(),
                ),
              ),
              FoldSafeActions(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (snapshot.isActive) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _manage,
                          child: Text(
                            Theme.of(context).platform == TargetPlatform.android
                                ? l10n.plusManageGooglePlay
                                : l10n.plusManageAppStore,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _restore,
                        child: Text(l10n.plusRestorePurchases),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBody extends StatelessWidget {
  const _ActiveBody({required this.snapshot});

  final SubscriptionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final onInk = scheme.surface;
    final labelColor = Theme.of(context).brightness == Brightness.light
        ? AppColors.iconOnInk
        : scheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.onSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlusWord(
                    size: 34,
                    color: onInk,
                    plusColor: plusAccentOnInk(context),
                  ),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: onInk,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      snapshot.willRenew
                          ? l10n.plusStatusActive
                          : l10n.plusStatusCancelled,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CardFact(
                      label: l10n.plusFactPlan,
                      value: snapshot.formula(l10n),
                      labelColor: labelColor,
                      valueColor: onInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardFact(
                      label: snapshot.willRenew
                          ? l10n.plusFactRenewal
                          : l10n.plusFactExpiration,
                      value: snapshot.renewalValue(l10n),
                      labelColor: labelColor,
                      valueColor: onInk,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SectionLabel(l10n.commonToday),
        const SizedBox(height: 6),
        FactRow(
          label: l10n.plusFeatureSuperLikesTitle,
          value: l10n.plusSuperLikesOf(
            snapshot.superLikesLeft,
            snapshot.superLikesMax,
          ),
        ),
        FactRow(
          label: l10n.plusFeatureBoostTitle,
          value: snapshot.boostAvailable
              ? l10n.plusBoostAvailable
              : l10n.plusBoostUsed,
        ),
        FactRow(
          label: l10n.plusLikesLabel,
          value: l10n.plusLikesUnlimited,
          last: true,
        ),
      ],
    );
  }
}

class _CardFact extends StatelessWidget {
  const _CardFact({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(labelColor).copyWith(fontSize: 10),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InactiveBody extends StatelessWidget {
  const _InactiveBody();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.plusNoActiveSubscription,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FoldSafeActions(
            child: PlusCtaButton(
              label: l10n.plusDiscover,
              onPressed: () => context.push(RoutePaths.premium),
            ),
          ),
        ],
      ),
    );
  }
}
