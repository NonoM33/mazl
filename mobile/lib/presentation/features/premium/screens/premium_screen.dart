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
  Package? _selectedPackage;
  bool _isLoading = true;
  bool _isPurchasing = false;

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
          // Select yearly by default (best value)
          _selectedPackage = offering?.annual ?? offering?.availablePackages.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() => _isPurchasing = true);
    try {
      await _revenueCat.purchasePackage(_selectedPackage!);
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
  }

  String _formatPrice(Package package) {
    return package.storeProduct.priceString;
  }

  String _formatPricePerMonth(Package package) {
    final price = package.storeProduct.price;
    final months = _getMonthsFromPackage(package);
    if (months <= 1) return '';
    final perMonth = price / months;
    return '${perMonth.toStringAsFixed(2)}€/mois';
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

  int _getSavingsPercent(Package package) {
    final monthlyPackage = _offering?.monthly;
    if (monthlyPackage == null) return 0;

    final monthlyPrice = monthlyPackage.storeProduct.price;
    final packagePrice = package.storeProduct.price;
    final months = _getMonthsFromPackage(package);

    if (months <= 1) return 0;

    final normalCost = monthlyPrice * months;
    final savings = ((normalCost - packagePrice) / normalCost * 100).round();
    return savings > 0 ? savings : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white70),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await _revenueCat.restorePurchases();
                        if (mounted && _revenueCat.isMazlPro) {
                          context.pop(true);
                        }
                      },
                      child: const Text(
                        'Restaurer',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Crown icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.premiumGradient,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentGold.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.crown,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            const Text(
                              'Mazl Pro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trouve ton mazal plus vite',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Features
                            _FeatureItem(
                              icon: LucideIcons.heart,
                              title: 'Likes illimités',
                              subtitle: 'Swipe autant que tu veux',
                            ),
                            _FeatureItem(
                              icon: LucideIcons.eye,
                              title: 'Voir qui t\'aime',
                              subtitle: 'Découvre tes admirateurs',
                            ),
                            _FeatureItem(
                              icon: LucideIcons.star,
                              title: '5 Super Likes/jour',
                              subtitle: 'Fais-toi remarquer',
                            ),
                            _FeatureItem(
                              icon: LucideIcons.zap,
                              title: '1 Boost/semaine',
                              subtitle: 'Sois vu en premier',
                            ),
                            _FeatureItem(
                              icon: LucideIcons.undo2,
                              title: 'Rewind illimité',
                              subtitle: 'Annule tes swipes',
                            ),
                            _FeatureItem(
                              icon: LucideIcons.checkCheck,
                              title: 'Confirmations de lecture',
                              subtitle: 'Sache quand tes messages sont lus',
                            ),
                            const SizedBox(height: 32),

                            // Packages
                            if (_offering != null)
                              ..._buildPackageOptions(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),

              // Purchase button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPurchasing ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.accentGold.withOpacity(0.5),
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
                            : Text(
                                _selectedPackage != null
                                    ? 'Continuer - ${_formatPrice(_selectedPackage!)}'
                                    : 'Continuer',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Annule à tout moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
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

  List<Widget> _buildPackageOptions() {
    final packages = _offering!.availablePackages
        .where((p) => p.packageType != PackageType.custom)
        .toList();

    // Sort by duration (longest first)
    packages.sort((a, b) => _getMonthsFromPackage(b).compareTo(_getMonthsFromPackage(a)));

    return packages.map((package) {
      final isSelected = _selectedPackage?.identifier == package.identifier;
      final savings = _getSavingsPercent(package);
      final isPopular = package.packageType == PackageType.annual;

      return GestureDetector(
        onTap: () => setState(() => _selectedPackage = package),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentGold.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentGold
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentGold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getPackageLabel(package),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'POPULAIRE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_formatPricePerMonth(package).isNotEmpty)
                      Text(
                        _formatPricePerMonth(package),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Price & savings
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(package),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (savings > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$savings%',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.check,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}
