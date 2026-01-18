import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

class CoupleActivityDetailScreen extends StatefulWidget {
  const CoupleActivityDetailScreen({
    super.key,
    required this.activityId,
  });

  final String activityId;

  @override
  State<CoupleActivityDetailScreen> createState() =>
      _CoupleActivityDetailScreenState();
}

class _CoupleActivityDetailScreenState
    extends State<CoupleActivityDetailScreen> {
  final CoupleApiService _apiService = CoupleApiService();
  CoupleActivity? _activity;
  bool _isLoading = true;
  bool _isSaved = false;
  String? _error;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activity =
          await _apiService.getActivity(int.parse(widget.activityId));
      setState(() {
        _activity = activity;
        _isLoading = false;
        _isSaved = activity?.savedAt != null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaved() async {
    if (_activity == null) return;

    final wassSaved = _isSaved;
    setState(() => _isSaved = !_isSaved);

    final success = _isSaved
        ? await _apiService.saveActivity(_activity!.id)
        : await _apiService.removeSavedActivity(_activity!.id);

    if (!success) {
      setState(() => _isSaved = wassSaved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'opération'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else if (_isSaved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Activité sauvegardée !'),
          backgroundColor: coupleAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () => context.push('/couple/activities/saved'),
          ),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyDiscountCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copié !'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _activity == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Activité introuvable',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final activity = _activity!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (activity.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: activity.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: coupleAccent.withOpacity(0.3),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildPlaceholder(activity),
                    )
                  else
                    _buildPlaceholder(activity),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Share button
              IconButton(
                icon: const Icon(LucideIcons.share2, color: Colors.white),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
              // Save button
              IconButton(
                icon: Icon(
                  _isSaved ? LucideIcons.bookMarked : LucideIcons.bookmark,
                  color: _isSaved ? coupleAccent : Colors.white,
                ),
                onPressed: _toggleSaved,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: coupleAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${activity.categoryEmoji} ${activity.categoryLabel}',
                          style: TextStyle(
                            color: coupleAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (activity.rating != null) ...[
                        const Icon(LucideIcons.star,
                            color: AppColors.accentGold, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          activity.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (activity.reviewCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${activity.reviewCount} avis)',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle (location + price)
                  Row(
                    children: [
                      if (activity.city != null) ...[
                        Icon(
                          LucideIcons.mapPin,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.city!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (activity.durationMinutes != null) ...[
                        Icon(
                          LucideIcons.clock,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.formattedDuration,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Badges row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Partner badge
                      if (activity.isPartner)
                        _Badge(
                          icon: LucideIcons.badgePercent,
                          label: activity.discountPercent != null
                              ? '-${activity.discountPercent}% Partenaire'
                              : 'Partenaire MAZL',
                          color: AppColors.accentGold,
                        ),
                      // Kosher badge
                      if (activity.isKosher)
                        const _Badge(
                          icon: null,
                          label: '✡️ Casher',
                          color: AppColors.info,
                        ),
                      // Price badge
                      _Badge(
                        icon: LucideIcons.euro,
                        label: activity.formattedPrice,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Partner discount code
                  if (activity.isPartner && activity.discountCode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.gift,
                              color: AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Code promo MAZL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity.discountCode!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: AppColors.accentGold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.copy),
                            color: AppColors.accentGold,
                            onPressed: () =>
                                _copyDiscountCode(activity.discountCode!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  if (activity.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activity.tags
                          .map((tag) => Chip(
                                label: Text(
                                  '#$tag',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: coupleAccent.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Address section
                  if (activity.address != null || activity.location != null) ...[
                    const Text(
                      'Adresse',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity.location != null) ...[
                            Text(
                              activity.location!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (activity.address != null)
                            Text(
                              activity.address!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          if (activity.city != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              activity.city!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Contact section
                  if (activity.phone != null || activity.website != null) ...[
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (activity.phone != null)
                          Expanded(
                            child: _ContactButton(
                              icon: LucideIcons.phone,
                              label: 'Appeler',
                              onPressed: () => _makeCall(activity.phone!),
                            ),
                          ),
                        if (activity.phone != null && activity.website != null)
                          const SizedBox(width: 12),
                        if (activity.website != null)
                          Expanded(
                            child: _ContactButton(
                              icon: LucideIcons.globe,
                              label: 'Site web',
                              onPressed: () => _openUrl(activity.website!),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom spacing for button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À partir de',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.formattedPrice,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Book button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: activity.bookingUrl != null
                      ? () => _openUrl(activity.bookingUrl!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coupleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.externalLink, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Réserver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CoupleActivity activity) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            coupleAccent,
            coupleAccent.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Text(
          activity.categoryEmoji,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  final IconData? icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
