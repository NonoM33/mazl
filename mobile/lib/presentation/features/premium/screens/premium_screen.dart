import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../core/services/store/subscription_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/plan_price.dart';
import '../l10n/plus_text.dart';
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

  /// Les formules du store ; à défaut (App Store Connect pas configuré, store
  /// injoignable), les formules de secours en euros.
  List<_PlanOffer> get _plans => _storePlans.isEmpty
      ? _fallbackPlans
      : [
          for (final plan in _storePlans)
            _PlanOffer(
              months: plan.months,
              price: plan.price,
              currencyCode: plan.currencyCode,
              storePlan: plan,
            ),
        ];

  /// L'économie d'une formule longue par rapport au prix du mois seul, en
  /// pourcents entiers ; null s'il n'y en a pas.
  int? _savingsPercent(List<_PlanOffer> plans, _PlanOffer plan) {
    // Prix mensuel de référence pour calculer l'économie des formules longues.
    final monthly = plans.firstWhere(
      (p) => p.months == 1,
      orElse: () => plans.first,
    );
    final normalCost = monthly.price / monthly.months * plan.months;
    if (plan.months <= 1 || normalCost <= 0) return null;
    final percent = ((normalCost - plan.price) / normalCost * 100).round();
    return percent > 0 ? percent : null;
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
        final l10n = context.l10n;
        switch (result) {
          case PurchaseSucceeded():
            context.pushReplacement(RoutePaths.plusWelcome);
          case PurchaseCancelled():
            // Une annulation par l'utilisateur n'est ni un succès ni une erreur.
            break;
          case PurchasePending():
            _showMessage(l10n.plusPendingApproval);
          case PurchaseFailed(:final problem):
            _showMessage(purchaseProblemText(l10n, problem));
        }
      } finally {
        if (mounted) {
          setState(() => _isPurchasing = false);
        }
      }
    } else {
      // Products not configured - show message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.plusPlansSoon)));
    }
  }

  Future<void> _handleRestore() async {
    final result = await _subscriptions.restore();
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case RestoreFound():
        _showMessage(l10n.plusOfferRestored, background: AppColors.success);
        context.pop(true);
      case RestoreNothing():
        _showMessage(l10n.plusOfferNothingFound);
      case RestoreFailed(:final problem):
        _showMessage(purchaseProblemText(l10n, problem));
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
    final l10n = context.l10n;
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
                    tooltip: l10n.commonClose,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    onPressed: _handleRestore,
                    child: Text(l10n.plusRestore),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PlusWord(size: 72),
                          const SizedBox(height: 16),
                          Text(
                            l10n.plusOfferTagline,
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.45,
                                ),
                          ),
                          const SizedBox(height: 28),
                          for (final perk in _perks(l10n)) _PerkRow(perk: perk),
                          const SizedBox(height: 28),
                          SectionLabel(l10n.plusYourPlan),
                          const SizedBox(height: 12),
                          for (var i = 0; i < plans.length; i++) ...[
                            _PlanRow(
                              plan: plans[i],
                              savingsPercent: _savingsPercent(plans, plans[i]),
                              selected: i == selected,
                              onTap: () =>
                                  setState(() => _selectedPlanIndex = i),
                            ),
                            if (i < plans.length - 1)
                              const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 16),
                          _LegalLine(onOpenUrl: _openUrl),
                        ],
                      ),
                    ),
            ),
            if (!_isLoading)
              FoldSafeActions(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    16 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing || !canBuy
                          ? null
                          : _handlePurchase,
                      child: !canBuy
                          ? Text(l10n.plusAndroidSoon)
                          : _isPurchasing
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            )
                          : Text(
                              l10n.plusContinuePrice(
                                planTotalLabel(
                                  price: plans[selected].price,
                                  currencyCode: plans[selected].currencyCode,
                                  locale: l10n.localeName,
                                ),
                              ),
                            ),
                    ),
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

List<_Perk> _perks(AppLocalizations l10n) => [
  _Perk(l10n.plusFeatureUnlimitedLikesTitle, l10n.plusPerkUnlimitedLikesDetail),
  _Perk(l10n.plusFeatureSeeWhoLikesYouTitle, l10n.plusPerkSeeWhoDetail),
  _Perk(l10n.plusPerkSuperLikesTitle, l10n.plusPerkSuperLikesDetail),
  _Perk(l10n.plusPerkBoostTitle, l10n.plusPerkBoostDetail),
  _Perk(l10n.plusFeatureAdvancedFiltersTitle, l10n.plusPerkFiltersDetail),
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
    required this.savingsPercent,
    required this.selected,
    required this.onTap,
  });

  final _PlanOffer plan;
  final int? savingsPercent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final ink = scheme.onSurface;
    final duration = l10n.plusMonths(plan.months);
    final price = planTotalLabel(
      price: plan.price,
      currencyCode: plan.currencyCode,
      locale: l10n.localeName,
    );
    final perMonth = planMonthlyLabel(
      l10n,
      price: plan.price,
      months: plan.months,
      currencyCode: plan.currencyCode,
    );
    final percent = savingsPercent;
    final saving = percent == null ? null : l10n.plusPlanSavings(percent);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: saving == null
          ? l10n.plusPlanSemantics(duration, price, perMonth)
          : l10n.plusPlanSemanticsSaving(duration, price, perMonth, saving),
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
                          duration,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perMonth,
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
                    price,
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
    final l10n = context.l10n;
    final legal = Theme.of(context).platform == TargetPlatform.android
        ? l10n.plusLegalGooglePlay
        : l10n.plusLegalAppStore;
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
    return Column(
      children: [
        Text(
          legal,
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
              child: Text(l10n.plusTerms),
            ),
            Text('·', style: TextStyle(color: scheme.onSurfaceVariant)),
            TextButton(
              style: linkStyle,
              onPressed: () => onOpenUrl('https://mazl.app/privacy'),
              child: Text(l10n.plusPrivacy),
            ),
          ],
        ),
      ],
    );
  }
}

/// Une ligne de l'offre : une durée, un prix, dans la devise du store.
class _PlanOffer {
  const _PlanOffer({
    required this.months,
    required this.price,
    required this.currencyCode,
    this.storePlan,
  });

  final int months;
  final double price;
  final String currencyCode;

  /// La formule du store derrière cette ligne ; null pour les formules de
  /// secours, affichées quand le store ne répond pas.
  final SubscriptionPlan? storePlan;
}

/// Les formules affichées avant la réponse du store (ou sans store), en euros :
/// 1, 3, 6 et 12 mois, comme les produits `com.mazl.app.plus.<n>m`.
const List<_PlanOffer> _fallbackPlans = [
  _PlanOffer(months: 1, price: 19.99, currencyCode: 'EUR'),
  _PlanOffer(months: 3, price: 44.99, currencyCode: 'EUR'),
  _PlanOffer(months: 6, price: 69.99, currencyCode: 'EUR'),
  _PlanOffer(months: 12, price: 99.99, currencyCode: 'EUR'),
];
