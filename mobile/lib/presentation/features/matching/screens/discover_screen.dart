import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/skeletons.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final CardSwiperController _controller = CardSwiperController();
  final DataPrefetchService _prefetchService = DataPrefetchService();
  final ApiService _apiService = ApiService();

  List<Profile> _profiles = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;
  String? _error;
  bool _swipeFromDetail = false; // Flag to prevent duplicate API calls

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Listen to super likes changes to update badge
    PremiumGate.onSuperLikesChanged = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _initializeData() async {
    // Try to use prefetched data first
    final cachedProfiles = _prefetchService.discoverProfiles;
    if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
      setState(() {
        _profiles = cachedProfiles;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } else {
      // Load from API if no cached data
      await _loadProfiles();
    }
  }

  Future<void> _loadProfiles({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final response = await _apiService.getDiscoverProfiles();

    if (response.success && response.data != null) {
      setState(() {
        _profiles = response.data!;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Erreur de chargement';
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    PremiumGate.onSuperLikesChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('MAZL'),
        actions: [
          // Daily Picks button
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.sparkles),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Selections du jour',
            onPressed: () => context.push(RoutePaths.dailyPicks),
          ),
          // Filters button
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Filtres',
            onPressed: () async {
              final result = await context.push<bool>(RoutePaths.filters);
              if (result == true && mounted) {
                // Reload profiles with new filters
                _loadProfiles(isRefresh: true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ProfileCardSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfiles,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.searchX, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Plus de profils disponibles',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviens plus tard!',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfiles,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Cards
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              controller: _controller,
              cardsCount: _profiles.length,
              numberOfCardsDisplayed: _profiles.length > 3 ? 3 : _profiles.length,
              backCardOffset: const Offset(0, 40),
              padding: EdgeInsets.zero,
              onSwipe: _onSwipe,
              onUndo: _onUndo,
              cardBuilder: (context, index, horizontalOffsetPercentage,
                  verticalOffsetPercentage) {
                final profile = _profiles[index];
                return _ProfileCard(
                  profile: profile,
                  swipeProgress: horizontalOffsetPercentage.toDouble(),
                  onTapProfile: () async {
                    final result = await context.push<String>('/discover/profile/${profile.userId}');
                    if (result != null && mounted) {
                      _handleSwipeFromDetail(result);
                    }
                  },
                );
              },
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Undo (Premium)
              _ActionButton(
                icon: LucideIcons.rotateCcw,
                color: AppColors.warning,
                size: 50,
                isPremium: !PremiumGate.isPremium,
                onPressed: () async {
                  if (await PremiumGate.showFeatureGate(context, PremiumFeature.rewind)) {
                    _controller.undo();
                  }
                },
              ),

              // Pass
              _ActionButton(
                icon: LucideIcons.x,
                color: AppColors.passRed,
                size: 60,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),

              // Super Like
              _ActionButton(
                icon: LucideIcons.star,
                color: AppColors.superLikeBlue,
                size: 50,
                badge: PremiumGate.remainingSuperLikes.toString(),
                onPressed: () async {
                  if (PremiumGate.remainingSuperLikes > 0 ||
                      await PremiumGate.showFeatureGate(context, PremiumFeature.superLikes)) {
                    _controller.swipe(CardSwiperDirection.top);
                  }
                },
              ),

              // Like
              _ActionButton(
                icon: LucideIcons.heart,
                color: AppColors.likeGreen,
                size: 60,
                onPressed: () => _controller.swipe(CardSwiperDirection.right),
              ),

              // Boost (Premium)
              _ActionButton(
                icon: LucideIcons.zap,
                color: AppColors.accentGold,
                size: 50,
                isPremium: !PremiumGate.isPremium,
                onPressed: () async {
                  if (await PremiumGate.showFeatureGate(context, PremiumFeature.boost)) {
                    // TODO: Activate boost
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Boost activé ! Tu seras visible en priorité pendant 30 minutes.'),
                        backgroundColor: AppColors.accentGold,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSwipeFromDetail(String action) {
    // Set flag to prevent duplicate API call (already sent from detail page)
    _swipeFromDetail = true;

    // Trigger the swipe animation based on the action from profile detail
    switch (action) {
      case 'like':
        _controller.swipe(CardSwiperDirection.right);
        break;
      case 'pass':
        _controller.swipe(CardSwiperDirection.left);
        break;
      case 'super_like':
        _controller.swipe(CardSwiperDirection.top);
        break;
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final profile = _profiles[previousIndex];

    String action;
    if (direction == CardSwiperDirection.right) {
      debugPrint('Liked ${profile.displayName}');
      action = 'like';
    } else if (direction == CardSwiperDirection.left) {
      debugPrint('Passed ${profile.displayName}');
      action = 'pass';
    } else if (direction == CardSwiperDirection.top) {
      // Check if user has super likes remaining
      if (PremiumGate.remainingSuperLikes <= 0) {
        // Block swipe and show premium modal
        PremiumGate.showFeatureGate(context, PremiumFeature.superLikes);
        return false; // Cancel the swipe - card returns to position
      }
      debugPrint('Super liked ${profile.displayName}');
      action = 'super_like';
      // Decrement super likes counter
      PremiumGate.useSuperLike();
    } else {
      return true;
    }

    // Skip API call if swipe came from detail page (already sent)
    if (_swipeFromDetail) {
      _swipeFromDetail = false;
      return true;
    }

    // Send swipe to backend
    _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: action,
    ).then((response) {
      if (response.success && response.data?['match'] == true) {
        // Show match animation
        _showMatchDialog(profile);
      }
    });

    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint('Undo on ${_profiles[currentIndex].displayName}');
    return true;
  }

  void _showMatchDialog(Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('It\'s a Match! 🎉'),
        content: Text('Tu as matché avec ${profile.displayName}!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer à swiper'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to chat
            },
            child: const Text('Envoyer un message'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.swipeProgress,
    this.onTapProfile,
  });

  final Profile profile;
  final double swipeProgress;
  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.photos.isNotEmpty ? profile.photos.first : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile image
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${profile.displayName ?? 'Anonyme'}, ${profile.age ?? '?'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (profile.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.badgeCheck,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.verificationLevel == 'verified_plus'
                                    ? 'Vérifié+'
                                    : 'Vérifié',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.location ?? 'France',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (profile.denomination != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          '✡ ${profile.denomination}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (profile.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Info button to view profile details
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onTapProfile,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.info,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

            // Like/Pass overlay
            if (swipeProgress != 0)
              Positioned(
                top: 40,
                left: swipeProgress > 0 ? 24 : null,
                right: swipeProgress < 0 ? 24 : null,
                child: Transform.rotate(
                  angle: swipeProgress > 0 ? -0.3 : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: swipeProgress > 0
                            ? AppColors.likeGreen
                            : AppColors.passRed,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      swipeProgress > 0 ? 'LIKE' : 'NOPE',
                      style: TextStyle(
                        color: swipeProgress > 0
                            ? AppColors.likeGreen
                            : AppColors.passRed,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 100.ms),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.user,
          size: 120,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    this.isPremium = false,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;
  final bool isPremium;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: size * 0.5,
            ),
          ),
          // Premium lock badge
          if (isPremium)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.crown,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          // Count badge
          if (badge != null && !isPremium)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
