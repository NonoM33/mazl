import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/plus_widgets.dart';

/// L'offre mazl+ : avantages, choix de la formule, achat.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.loadOffering});

  /// Source de l'offre RevenueCat, remplaçable dans les tests.
  /// Par défaut : l'offre courante du service.
  final Future<Offering?> Function()? loadOffering;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final RevenueCatService _revenueCat = RevenueCatService();
  Offering? _offering;
  int _selectedPlanIndex = 1; // Default to 6 months (best value)
  bool _isLoading = true;
  bool _isPurchasing = false;

  // Default pricing when App Store Connect isn't configured
  final List<_SubscriptionPlan> _defaultPlans = [
    _SubscriptionPlan(
      id: 'monthly',
      duration: '1 mois',
      price: '14,99 €',
      pricePerMonth: '14,99 € par mois',
      savings: null,
    ),
    _SubscriptionPlan(
      id: 'six_month',
      duration: '6 mois',
      price: '59,99 €',
      pricePerMonth: '9,99 € par mois',
      savings: '-33 %',
    ),
    _SubscriptionPlan(
      id: 'yearly',
      duration: '12 mois',
      price: '89,99 €',
      pricePerMonth: '7,49 € par mois',
      savings: '-50 %',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offering =
          await (widget.loadOffering ?? _revenueCat.getCurrentOffering)();
      if (mounted) {
        setState(() {
          _offering = offering;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Silently handle RevenueCat errors - just use default plans
      debugPrint('RevenueCat offerings error (using defaults): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // _offering stays null, so _defaultPlans will be used
        });
      }
    }
  }

  List<_SubscriptionPlan> get _plans {
    if (_offering == null || _offering!.availablePackages.isEmpty) {
      return _defaultPlans;
    }

    final packages = _offering!.availablePackages
        .where((p) => p.packageType != PackageType.custom)
        .toList();

    if (packages.isEmpty) return _defaultPlans;

    // Find monthly price for comparison
    final monthlyPackage = packages.firstWhere(
      (p) => p.packageType == PackageType.monthly,
      orElse: () => packages.first,
    );
    final monthlyPrice = monthlyPackage.storeProduct.price;

    return packages.map((package) {
      final months = _getMonthsFromPackage(package);
      final price = package.storeProduct.price;
      final pricePerMonth = months > 0 ? price / months : price;
      final normalCost = monthlyPrice * months;
      final savingsPercent = months > 1 && normalCost > 0
          ? ((normalCost - price) / normalCost * 100).round()
          : 0;

      return _SubscriptionPlan(
        id: package.identifier,
        duration: _getPackageLabel(package),
        price: package.storeProduct.priceString,
        pricePerMonth:
            '${pricePerMonth.toStringAsFixed(2).replaceAll('.', ',')} € par mois',
        savings: savingsPercent > 0 ? '-$savingsPercent %' : null,
        package: package,
      );
    }).toList()..sort((a, b) {
      // Sort by duration
      final aMonths = _getMonthsFromId(a.id);
      final bMonths = _getMonthsFromId(b.id);
      return aMonths.compareTo(bMonths);
    });
  }

  int _getMonthsFromId(String id) {
    if (id.contains('monthly') || id == 'monthly') return 1;
    if (id.contains('two_month')) return 2;
    if (id.contains('three_month')) return 3;
    if (id.contains('six_month')) return 6;
    if (id.contains('yearly') || id.contains('annual')) return 12;
    return 1;
  }

  int _getMonthsFromPackage(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return 1;
      case PackageType.twoMonth:
        return 2;
      case PackageType.threeMonth:
        return 3;
      case PackageType.sixMonth:
        return 6;
      case PackageType.annual:
        return 12;
      default:
        return 1;
    }
  }

  String _getPackageLabel(Package package) {
    switch (package.packageType) {
      case PackageType.monthly:
        return '1 mois';
      case PackageType.twoMonth:
        return '2 mois';
      case PackageType.threeMonth:
        return '3 mois';
      case PackageType.sixMonth:
        return '6 mois';
      case PackageType.annual:
        return '12 mois';
      default:
        return package.storeProduct.title;
    }
  }

  Future<void> _handlePurchase() async {
    final plans = _plans;
    if (plans.isEmpty) return;
    final selectedPlan = plans[_selectedPlanIndex.clamp(0, plans.length - 1)];

    // If we have a real package, purchase it
    if (selectedPlan.package != null) {
      setState(() => _isPurchasing = true);
      try {
        final result = await _revenueCat.purchasePackage(selectedPlan.package!);
        // Une annulation par l'utilisateur n'est ni un succès ni une erreur.
        if (result.isCancelled) return;
        if (mounted) {
          context.pushReplacement(RoutePaths.plusWelcome);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
    try {
      await _revenueCat.restorePurchases();
      if (!mounted) return;
      if (_revenueCat.isMazlPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement restauré'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun abonnement trouvé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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
                              onPressed: _isPurchasing ? null : _handlePurchase,
                              child: _isPurchasing
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
  final Package? package;

  const _SubscriptionPlan({
    required this.id,
    required this.duration,
    required this.price,
    required this.pricePerMonth,
    required this.savings,
    this.package,
  });
}
