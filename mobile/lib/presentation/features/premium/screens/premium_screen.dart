import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/services/revenuecat_service.dart';
import '../../../../core/theme/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final RevenueCatService _revenueCat = RevenueCatService();
  Offering? _offering;
  int _selectedPlanIndex = 1; // Default to 6 months (best value)
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  // Default pricing when App Store Connect isn't configured
  final List<_SubscriptionPlan> _defaultPlans = [
    _SubscriptionPlan(
      id: 'monthly',
      duration: '1 mois',
      price: '14,99 €',
      pricePerMonth: '14,99 €/mois',
      savings: null,
      isBestValue: false,
    ),
    _SubscriptionPlan(
      id: 'six_month',
      duration: '6 mois',
      price: '59,99 €',
      pricePerMonth: '9,99 €/mois',
      savings: '-33%',
      isBestValue: true,
    ),
    _SubscriptionPlan(
      id: 'yearly',
      duration: '12 mois',
      price: '89,99 €',
      pricePerMonth: '7,49 €/mois',
      savings: '-50%',
      isBestValue: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offering = await _revenueCat.getCurrentOffering();
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
        pricePerMonth: '${pricePerMonth.toStringAsFixed(2)} €/mois',
        savings: savingsPercent > 0 ? '-$savingsPercent%' : null,
        isBestValue: package.packageType == PackageType.sixMonth ||
            package.packageType == PackageType.annual,
        package: package,
      );
    }).toList()
      ..sort((a, b) {
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
    if (_selectedPlanIndex >= plans.length) return;

    final selectedPlan = plans[_selectedPlanIndex];

    // If we have a real package, purchase it
    if (selectedPlan.package != null) {
      setState(() => _isPurchasing = true);
      try {
        await _revenueCat.purchasePackage(selectedPlan.package!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bienvenue dans Mazl Pro !'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
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
          content: Text('Les abonnements seront disponibles prochainement !'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        try {
                          await _revenueCat.restorePurchases();
                          if (mounted && _revenueCat.isMazlPro) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Abonnement restaure !'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            context.pop(true);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Aucun abonnement trouve'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Restaurer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Crown icon with glow
                            _buildCrownIcon(),
                            const SizedBox(height: 24),

                            // Title
                            const Text(
                              'Mazl Pro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Multiplie tes chances de trouver l\'amour',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Subscription plans
                            _buildSubscriptionPlans(plans),
                            const SizedBox(height: 24),

                            // Features
                            _buildFeaturesCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),

              // Bottom CTA
              _buildBottomCTA(plans),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrownIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Inner circle with icon
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.crown,
            size: 44,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlans(List<_SubscriptionPlan> plans) {
    return Column(
      children: List.generate(plans.length, (index) {
        final plan = plans[index];
        final isSelected = _selectedPlanIndex == index;

        return GestureDetector(
          onTap: () => setState(() => _selectedPlanIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 16),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.duration,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (plan.isBestValue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.star, size: 10, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'TOP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.pricePerMonth,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF6B7280)
                              : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and savings
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.savings != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : const Color(0xFF10B981).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan.savings!,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildFeatureRow(LucideIcons.heart, 'Likes illimites'),
          _buildFeatureRow(LucideIcons.eye, 'Voir qui t\'aime'),
          _buildFeatureRow(LucideIcons.star, '5 Super Likes par jour'),
          _buildFeatureRow(LucideIcons.zap, '1 Boost par semaine'),
          _buildFeatureRow(LucideIcons.undo2, 'Rewind illimite'),
          _buildFeatureRow(LucideIcons.sparkles, 'Compatibilite IA', isLast: true),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            LucideIcons.check,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(List<_SubscriptionPlan> plans) {
    final selectedPlan = _selectedPlanIndex < plans.length
        ? plans[_selectedPlanIndex]
        : plans.first;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'S\'abonner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '- ${selectedPlan.price}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Terms
          Text(
            'Renouvellement automatique. Annule a tout moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Open terms
                },
                child: Text(
                  'Conditions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              TextButton(
                onPressed: () {
                  // TODO: Open privacy
                },
                child: Text(
                  'Confidentialite',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPlan {
  final String id;
  final String duration;
  final String price;
  final String pricePerMonth;
  final String? savings;
  final bool isBestValue;
  final Package? package;

  _SubscriptionPlan({
    required this.id,
    required this.duration,
    required this.price,
    required this.pricePerMonth,
    this.savings,
    this.isBestValue = false,
    this.package,
  });
}
