import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/services/subscription_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/plus_widgets.dart';

/// Ce que l'écran « Abonnement » affiche.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.isActive,
    this.planLabel,
    this.price,
    this.renewalDate,
    this.willRenew = true,
    this.superLikesLeft = 0,
    this.superLikesMax = 0,
    this.boostAvailable = false,
  });

  /// Lit l'état courant de RevenueCat et du compteur quotidien.
  factory SubscriptionSnapshot.current({String? price}) {
    final revenueCat = RevenueCatService();
    return SubscriptionSnapshot(
      isActive: revenueCat.isMazlPro,
      planLabel: revenueCat.activePlanLabel,
      price: price,
      renewalDate: revenueCat.mazlProExpirationDate,
      willRenew: revenueCat.willRenew,
      superLikesLeft: PremiumGate.remainingSuperLikes,
      superLikesMax: PremiumGate.superLikesPerDay,
      boostAvailable: PremiumGate.remainingBoosts > 0,
    );
  }

  final bool isActive;
  final String? planLabel;
  final String? price;
  final DateTime? renewalDate;
  final bool willRenew;
  final int superLikesLeft;
  final int superLikesMax;
  final bool boostAvailable;

  /// « 6 mois · 59,99 € », ou ce qu'on en sait.
  String get formula {
    final parts = [?planLabel, ?price];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String get renewalValue {
    final date = renewalDate;
    return date == null ? '—' : formatFrenchDate(date.toLocal());
  }
}

/// Gestion de l'abonnement mazl+ : formule, échéance, avantages du jour.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.snapshot, this.onManage});

  /// Données fixes (tests). Absentes : lues en direct puis rafraîchies.
  final SubscriptionSnapshot? snapshot;

  /// Ouvre la gestion de l'abonnement dans le store. Par défaut : l'URL de
  /// gestion de RevenueCat, sinon la page d'abonnements du store.
  final VoidCallback? onManage;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final RevenueCatService _revenueCat = RevenueCatService();
  late SubscriptionSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.snapshot ?? SubscriptionSnapshot.current();
    if (widget.snapshot == null) _refresh();
  }

  Future<void> _refresh() async {
    try {
      await _revenueCat.refreshCustomerInfo();
    } catch (e) {
      debugPrint('Subscription: refresh failed - $e');
    }
    final price = await _revenueCat.activePlanPrice();
    if (mounted) {
      setState(() => _snapshot = SubscriptionSnapshot.current(price: price));
    }
  }

  Future<void> _manage() async {
    if (widget.onManage != null) {
      widget.onManage!();
      return;
    }
    final android = Theme.of(context).platform == TargetPlatform.android;
    final fallback = android
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    final uri = Uri.parse(_revenueCat.managementUrl ?? fallback);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la gestion de l’abonnement.'),
        ),
      );
    }
  }

  Future<void> _restore() async {
    try {
      await _revenueCat.restorePurchases();
      if (!mounted) return;
      setState(() => _snapshot = SubscriptionSnapshot.current());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _revenueCat.isMazlPro
                ? 'Achats restaurés.'
                : 'Aucun abonnement trouvé.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RoundIconButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 24),
              Text(
                'Abonnement',
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
              if (snapshot.isActive) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _manage,
                    child: Text(
                      Theme.of(context).platform == TargetPlatform.android
                          ? 'Gérer dans Google Play'
                          : 'Gérer dans l’App Store',
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
                  child: const Text('Restaurer mes achats'),
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
                      snapshot.willRenew ? 'Actif' : 'Résilié',
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
                      label: 'Formule',
                      value: snapshot.formula,
                      labelColor: labelColor,
                      valueColor: onInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardFact(
                      label: snapshot.willRenew
                          ? 'Renouvellement'
                          : 'Expiration',
                      value: snapshot.renewalValue,
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
        const SectionLabel('Aujourd\'hui'),
        const SizedBox(height: 6),
        FactRow(
          label: 'Super Likes',
          value: '${snapshot.superLikesLeft} sur ${snapshot.superLikesMax}',
        ),
        FactRow(
          label: 'Boost',
          value: snapshot.boostAvailable ? 'Disponible' : 'Utilisé aujourd’hui',
        ),
        const FactRow(label: 'Likes', value: 'Illimités', last: true),
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
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aucun abonnement actif.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          PlusCtaButton(
            prefix: 'Découvrir ',
            onPressed: () => context.push(RoutePaths.premium),
          ),
        ],
      ),
    );
  }
}
