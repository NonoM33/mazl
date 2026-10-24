import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../core/services/subscription_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/plus_widgets.dart';

/// L'offre mazl+ : avantages, choix de la formule, achat.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.loadPlans, this.service});

  /// Source des formules du store, remplaçable dans les tests.
  /// Par défaut : les formules du service d'abonnement.
  final Future<List<SubscriptionPlan>> Function()? loadPlans;

  /// Service d'abonnement, remplaçable dans les tests.
  final SubscriptionService? service;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final SubscriptionService _subscriptions =
      widget.service ?? SubscriptionService();
  List<SubscriptionPlan> _storePlans = const [];
  int _selectedPlanIndex = 1; // 3 mois, la formule mise en avant
  bool _isLoading = true;
  bool _isPurchasing = false;

  // Default pricing when App Store Connect isn't configured
  final List<_SubscriptionPlan> _defaultPlans = [
    _SubscriptionPlan(
      id: 'monthly',
      duration: '1 mois',
      price: '19,99 €',
      pricePerMonth: '19,99 € par mois',
      savings: null,
    ),
    _SubscriptionPlan(
      id: 'three_month',
      duration: '3 mois',
      price: '44,99 €',
      pricePerMonth: '15,00 € par mois',
      savings: '-25 %',
    ),
    _SubscriptionPlan(
      id: 'six_month',
      duration: '6 mois',
      price: '69,99 €',
      pricePerMonth: '11,67 € par mois',
      savings: '-42 %',
    ),
    _SubscriptionPlan(
      id: 'yearly',
      duration: '12 mois',
      price: '99,99 €',
      pricePerMonth: '8,33 € par mois',
      savings: '-58 %',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await (widget.loadPlans ?? _subscriptions.loadPlans)();
      if (mounted) {
        setState(() {
          _storePlans = plans;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      // Le store ne répond pas : on affiche les formules par défaut.
      debugPrint('Subscription plans error (using defaults): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // _storePlans reste vide : _defaultPlans est utilisé.
        });
      }
    }
  }

  List<_SubscriptionPlan> get _plans {
    if (_storePlans.isEmpty) return _defaultPlans;

    // Prix mensuel de référence pour calculer l'économie des formules longues.
    final monthly = _storePlans.firstWhere(
      (p) => p.months == 1,
      orElse: () => _storePlans.first,
    );
    final monthlyPrice = monthly.price / monthly.months;

    return [
      for (final plan in _storePlans)
        _SubscriptionPlan(
          id: plan.productId,
          duration: monthsLabel(plan.months),
          price: planTotalLabel(
            price: plan.price,
            currencyCode: plan.currencyCode,
          ),
          pricePerMonth: planMonthlyLabel(
            price: plan.price,
            months: plan.months,
            currencyCode: plan.currencyCode,
          ),
          savings: _savings(monthlyPrice, plan),
          storePlan: plan,
        ),
    ];
  }

  String? _savings(double monthlyPrice, SubscriptionPlan plan) {
    final normalCost = monthlyPrice * plan.months;
    if (plan.months <= 1 || normalCost <= 0) return null;
    final percent = ((normalCost - plan.price) / normalCost * 100).round();
    return percent > 0 ? '-$percent %' : null;
  }

  void _showMessage(String message, {Color? background}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
  }

  Future<void> _handlePurchase() async {
    final plans = _plans;
    if (plans.isEmpty) return;
    final selectedPlan = plans[_selectedPlanIndex.clamp(0, plans.length - 1)];

    final storePlan = selectedPlan.storePlan;
    if (storePlan != null) {
      setState(() => _isPurchasing = true);
      try {
        final result = await _subscriptions.purchase(storePlan);
        if (!mounted) return;
        switch (result) {
          case PurchaseSucceeded():
            context.pushReplacement(RoutePaths.plusWelcome);
          case PurchaseCancelled():
            // Une annulation par l'utilisateur n'est ni un succès ni une erreur.
            break;
          case PurchasePending():
            _showMessage(
              'Achat en attente d’approbation. Votre abonnement s’activera dès qu’il sera validé.',
            );
          case PurchaseFailed(:final message):
            _showMessage(message);
        }
      } finally {
        if (mounted) {
          setState(() => _isPurchasing = false);
        }
      }
    } else {
      // Products not configured - show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les abonnements seront disponibles prochainement.'),
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final result = await _subscriptions.restore();
    if (!mounted) return;
    switch (result) {
      case RestoreFound():
        _showMessage('Abonnement restauré', background: AppColors.success);
        context.pop(true);
      case RestoreNothing():
        _showMessage('Aucun abonnement trouvé');
      case RestoreFailed(:final message):
        _showMessage(message);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    final selected = _selectedPlanIndex.clamp(0, plans.length - 1);
    // Seul iOS achète pour l'instant : le serveur ne vérifie pas Google Play.
    final canBuy = Theme.of(context).platform != TargetPlatform.android;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: LucideIcons.x,
                    tooltip: 'Fermer',
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: _handleRestore,
                    child: const Text('Restaurer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        32 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PlusWord(size: 72),
                          const SizedBox(height: 16),
                          Text(
                            'Rencontrez sans compter.',
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.45,
                                ),
                          ),
                          const SizedBox(height: 28),
                          for (final perk in _perks) _PerkRow(perk: perk),
                          const SizedBox(height: 28),
                          const SectionLabel('Votre formule'),
                          const SizedBox(height: 12),
                          for (var i = 0; i < plans.length; i++) ...[
                            _PlanRow(
                              plan: plans[i],
                              selected: i == selected,
                              onTap: () =>
                                  setState(() => _selectedPlanIndex = i),
                            ),
                            if (i < plans.length - 1)
                              const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPurchasing || !canBuy
                                  ? null
                                  : _handlePurchase,
                              child: !canBuy
                                  ? const Text(
                                      SubscriptionService.androidSoonMessage,
                                    )
                                  : _isPurchasing
                                  ? SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                    )
                                  : Text(
                                      'Continuer · ${plans[selected].price}',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _LegalLine(onOpenUrl: _openUrl),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perk {
  const _Perk(this.title, this.detail);

  final String title;
  final String detail;
}

const _perks = [
  _Perk('Likes illimités', 'Fini les 10 par jour.'),
  _Perk('Voir qui vous a aimé', 'Avant même de les croiser.'),
  _Perk('5 Super Likes par jour', 'Au lieu d’un seul.'),
  _Perk('Un Boost par jour', 'En tête de pile pendant 30 minutes.'),
  _Perk('Revenir en arrière', 'Rattrapez un « Passer » trop rapide.'),
  _Perk('Filtres avancés', 'Pratique, communauté, et plus.'),
];

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk});

  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.check, size: 16, color: scheme.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perk.detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final saving = plan.savings;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label:
          '${plan.duration}, ${plan.price}, ${plan.pricePerMonth}'
          '${saving == null ? '' : ', économie $saving'}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? ink : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? ink
                            : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        width: selected ? 6 : 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.duration,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.pricePerMonth,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (saving != null) ...[
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        saving,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _LegalLine extends StatelessWidget {
  const _LegalLine({required this.onOpenUrl});

  final Future<void> Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = Theme.of(context).platform == TargetPlatform.android
        ? 'Google Play'
        : 'l’App Store';
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
    return Column(
      children: [
        Text(
          'Renouvellement automatique, résiliable à tout moment dans les réglages de $store.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.family,
            fontSize: 12,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              style: linkStyle,
              onPressed: () => onOpenUrl('https://mazl.app/terms'),
              child: const Text('Conditions'),
            ),
            Text('·', style: TextStyle(color: scheme.onSurfaceVariant)),
            TextButton(
              style: linkStyle,
              onPressed: () => onOpenUrl('https://mazl.app/privacy'),
              child: const Text('Confidentialité'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubscriptionPlan {
  final String id;
  final String duration;
  final String price;
  final String pricePerMonth;
  final String? savings;

  /// La formule du store derrière cette ligne ; null pour les formules par
  /// défaut, affichées quand le store ne répond pas.
  final SubscriptionPlan? storePlan;

  const _SubscriptionPlan({
    required this.id,
    required this.duration,
    required this.price,
    required this.pricePerMonth,
    required this.savings,
    this.storePlan,
  });
}
