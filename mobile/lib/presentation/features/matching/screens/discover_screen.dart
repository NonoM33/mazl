import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/swipe_deck/swipe_deck.dart';
import '../../../widgets/skeletons.dart';
import '../../chat/conversation_lookup.dart';
import '../widgets/discover_card.dart';
import '../widgets/match_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  final SwipeDeckController _deck = SwipeDeckController();
  final DataPrefetchService _prefetchService = DataPrefetchService();
  late final ApiService _apiService = widget.apiService ?? ApiService();

  List<Profile> _profiles = [];
  bool _isLoading = true;
  String? _error;
  bool _swipeFromDetail = false; // Flag to prevent duplicate API calls

  /// Bumped with each new list so the deck starts again from its first card.
  int _deckGeneration = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Charge les compteurs quotidiens avant le premier like.
    PremiumGate.ensureInitialized();
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
        _deckGeneration++;
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
        _deckGeneration++;
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
    _deck.dispose();
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SwipeDeck(
        key: ValueKey(_deckGeneration),
        controller: _deck,
        itemCount: _profiles.length,
        allowed: const {
          SwipeDirection.left,
          SwipeDirection.right,
          SwipeDirection.up,
        },
        intents: {
          SwipeDirection.right: SwipeIntent(
            icon: LucideIcons.heart,
            color: scheme.primary,
          ),
          SwipeDirection.left: const SwipeIntent(
            icon: LucideIcons.x,
            color: AppColors.muted,
          ),
          SwipeDirection.up: SwipeIntent(
            icon: LucideIcons.star,
            color: scheme.primary,
          ),
        },
        heavyHapticOn: const {SwipeDirection.up},
        onWillSwipe: _willSwipe,
        onRefused: _onRefused,
        onSwiped: _onSwiped,
        onUndone: _onUndone,
        onEnd: _onDeckEnd,
        cardBuilder: (context, index, isTop) {
          final profile = _profiles[index];
          return DiscoverCard(
            profile: profile,
            swipeProgress: isTop ? _deck.progress : null,
            onPass: () => _deck.swipe(SwipeDirection.left),
            onLike: () => _deck.swipe(SwipeDirection.right),
            onTapProfile: () async {
              final result = await context
                  .push<String>('/discover/profile/${profile.userId}');
              if (result != null && mounted) {
                _handleSwipeFromDetail(result);
              }
            },
            secondaryActions: _buildSecondaryActions(followsSwipe: isTop),
          );
        },
      ),
    );
  }

  List<Widget> _buildSecondaryActions({required bool followsSwipe}) {
    final superLike = DiscoverMiniAction(
      icon: LucideIcons.star,
      tooltip: 'Super like',
      badge: PremiumGate.remainingSuperLikes.toString(),
      // Refused (none left): the card stays, then the gate opens.
      onPressed: () => _deck.swipe(SwipeDirection.up),
    );
    return [
      // Undo (Premium)
      DiscoverMiniAction(
        icon: LucideIcons.rotateCcw,
        tooltip: 'Annuler',
        locked: !PremiumGate.isPremium,
        onPressed: () async {
          if (await PremiumGate.showFeatureGate(context, PremiumFeature.rewind)) {
            _deck.undo();
          }
        },
      ),
      // Super Like
      if (followsSwipe)
        SwipeProgressScale(
          progress: _deck.progress,
          direction: SwipeDirection.up,
          child: superLike,
        )
      else
        superLike,
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
          content: Text('Boost activé. Vous êtes en tête de pile pendant 30 minutes.'),
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
    final direction = switch (action) {
      'like' => SwipeDirection.right,
      'pass' => SwipeDirection.left,
      'super_like' => SwipeDirection.up,
      _ => null,
    };
    if (direction == null) {
      _swipeFromDetail = false;
      return;
    }
    _deck.swipe(direction).then((left) {
      if (!left) _swipeFromDetail = false;
    });
  }

  /// Asked before the card moves: a like or a super like that is not allowed
  /// keeps the card, which springs back, and the gate opens in [_onRefused].
  bool _willSwipe(int index, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.right:
        // Les likes gratuits du jour sont comptés ici. Un like venu de la fiche
        // profil a déjà été contrôlé et décompté là-bas.
        return _swipeFromDetail || PremiumGate.tryConsumeFreeLike();
      case SwipeDirection.up:
        // Check if user has super likes remaining
        return PremiumGate.remainingSuperLikes > 0;
      case SwipeDirection.left:
        return true;
    }
  }

  /// The card is back in place: now the premium gate may open.
  void _onRefused(int index, SwipeDirection direction) {
    _swipeFromDetail = false;
    if (direction == SwipeDirection.right) {
      unawaited(PremiumGate.showDailyLimitSheet(context));
    } else if (direction == SwipeDirection.up) {
      unawaited(_offerSuperLikes());
    }
  }

  Future<void> _offerSuperLikes() async {
    final granted = await PremiumGate.showFeatureGate(
      context,
      PremiumFeature.superLikes,
    );
    if (granted && mounted && PremiumGate.remainingSuperLikes > 0) {
      unawaited(_deck.swipe(SwipeDirection.up));
    }
  }

  void _onSwiped(int index, SwipeDirection direction) {
    final profile = _profiles[index];

    String action;
    if (direction == SwipeDirection.right) {
      debugPrint('Liked ${profile.displayName}');
      action = 'like';
    } else if (direction == SwipeDirection.left) {
      debugPrint('Passed ${profile.displayName}');
      action = 'pass';
    } else {
      debugPrint('Super liked ${profile.displayName}');
      action = 'super_like';
      // Decrement super likes counter
      PremiumGate.useSuperLike();
    }

    // Skip API call if swipe came from detail page (already sent)
    if (_swipeFromDetail) {
      _swipeFromDetail = false;
      return;
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
  }

  void _onUndone(int index) {
    debugPrint('Undo on ${_profiles[index].displayName}');
  }

  /// Every profile has been seen: the empty state offers to look again.
  void _onDeckEnd() {
    if (!mounted) return;
    setState(() => _profiles = const []);
  }

  Future<void> _showMatchDialog(Profile profile) async {
    final choice = await showMatchSheet(context, matched: profile);
    if (choice == MatchSheetChoice.message && mounted) {
      await _openConversationWith(profile.userId);
    }
  }

  /// Le serveur crée la conversation au match sans renvoyer son id : on la
  /// retrouve par la personne, et à défaut on ouvre Messages.
  Future<void> _openConversationWith(int userId) async {
    final response = await _apiService.getConversations();
    if (!mounted) return;
    final id = response.success ? conversationIdWith(response.data ?? const [], userId) : null;
    context.go(id == null ? RoutePaths.chat : '/chat/$id');
  }
}
