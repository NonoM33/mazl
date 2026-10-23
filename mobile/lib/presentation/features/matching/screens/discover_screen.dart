import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../widgets/skeletons.dart';
import '../widgets/discover_card.dart';

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
      });
    } else {
      setState(() {
        _error = response.error ?? 'Erreur de chargement';
        _isLoading = false;
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
      // SafeArea réserve aussi la place de la barre d'onglets flottante.
      body: SafeArea(
        child: Column(
          children: [
            _buildTopRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const MazlWordmark(size: 26),
          const Spacer(),
          RoundIconButton(
            icon: LucideIcons.sparkles,
            tooltip: 'Sélections du jour',
            onPressed: () => context.push(RoutePaths.dailyPicks),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: LucideIcons.slidersHorizontal,
            tooltip: 'Filtres',
            onPressed: _openFilters,
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await context.push<bool>(RoutePaths.filters);
    if (result == true && mounted) {
      // Reload profiles with new filters
      _loadProfiles(isRefresh: true);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ProfileCardSkeleton();
    }
    if (_error != null) {
      return _buildError();
    }
    if (_profiles.isEmpty) {
      return _buildEmpty();
    }
    return _buildSwiper();
  }

  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleAlert, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfiles,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez tout vu.',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Revenez plus tard ou élargissez vos filtres pour voir de nouveaux profils.',
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: _openFilters,
              child: const Text('Ouvrir les filtres'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _loadProfiles,
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CardSwiper(
        controller: _controller,
        cardsCount: _profiles.length,
        numberOfCardsDisplayed: _profiles.length > 2 ? 2 : _profiles.length,
        backCardOffset: const Offset(0, 20),
        padding: EdgeInsets.zero,
        onSwipe: _onSwipe,
        onUndo: _onUndo,
        cardBuilder: (context, index, horizontalOffsetPercentage,
            verticalOffsetPercentage) {
          final profile = _profiles[index];
          return DiscoverCard(
            profile: profile,
            swipeProgress: horizontalOffsetPercentage.toDouble(),
            onPass: () => _controller.swipe(CardSwiperDirection.left),
            onLike: () => _controller.swipe(CardSwiperDirection.right),
            onTapProfile: () async {
              final result = await context
                  .push<String>('/discover/profile/${profile.userId}');
              if (result != null && mounted) {
                _handleSwipeFromDetail(result);
              }
            },
            secondaryActions: _buildSecondaryActions(),
          );
        },
      ),
    );
  }

  List<Widget> _buildSecondaryActions() {
    return [
      // Undo (Premium)
      DiscoverMiniAction(
        icon: LucideIcons.rotateCcw,
        tooltip: 'Annuler',
        locked: !PremiumGate.isPremium,
        onPressed: () async {
          if (await PremiumGate.showFeatureGate(context, PremiumFeature.rewind)) {
            _controller.undo();
          }
        },
      ),
      // Super Like
      DiscoverMiniAction(
        icon: LucideIcons.star,
        tooltip: 'Super like',
        badge: PremiumGate.remainingSuperLikes.toString(),
        onPressed: () async {
          if (PremiumGate.remainingSuperLikes > 0 ||
              await PremiumGate.showFeatureGate(context, PremiumFeature.superLikes)) {
            _controller.swipe(CardSwiperDirection.top);
          }
        },
      ),
      // Boost (Premium)
      DiscoverMiniAction(
        icon: LucideIcons.zap,
        tooltip: 'Boost',
        locked: !PremiumGate.isPremium,
        onPressed: () async {
          if (await PremiumGate.showFeatureGate(context, PremiumFeature.boost)) {
            await _activateBoost();
          }
        },
      ),
    ];
  }

  Future<void> _activateBoost() async {
    final response = await _apiService.activateBoost();
    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boost activé ! Tu seras visible en priorité pendant 30 minutes.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Impossible d\'activer le boost'),
        ),
      );
    }
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
        title: const Text('C\'est un match.'),
        content: Text('Tu as matché avec ${profile.displayName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer à swiper'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RoutePaths.matches);
            },
            child: const Text('Envoyer un message'),
          ),
        ],
      ),
    );
  }
}
