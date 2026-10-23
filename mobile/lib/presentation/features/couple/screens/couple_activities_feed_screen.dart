import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/skeletons.dart';
import '../widgets/couple_message_view.dart';

class CoupleActivitiesFeedScreen extends StatefulWidget {
  const CoupleActivitiesFeedScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleActivitiesFeedScreen> createState() =>
      _CoupleActivitiesFeedScreenState();
}

class _CoupleActivitiesFeedScreenState extends State<CoupleActivitiesFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final CardSwiperController _controller = CardSwiperController();
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();

  /// The deck as the swiper sees it. Only replaced by a (re)load or a rollback,
  /// together with [_deckGeneration], so the swiper never sees its count change.
  List<CoupleActivity> _deck = [];
  int _deckGeneration = 0;

  /// Index in [_deck] of the card on top.
  int _topIndex = 0;
  bool _deckDone = false;

  bool _isLoading = true;
  CoupleFailure? _failure;
  String? _selectedCategory;
  int _loadToken = 0;

  // Couple mode accent color
  static const coupleAccent = Color(0xFFFF6B9D);

  // Categories with emojis
  static const categories = [
    {'key': null, 'label': 'Tout', 'emoji': '✨'},
    {'key': 'wellness', 'label': 'Bien-être', 'emoji': '🧖‍♀️'},
    {'key': 'gastronomy', 'label': 'Gastro', 'emoji': '🍷'},
    {'key': 'culture', 'label': 'Culture', 'emoji': '🎭'},
    {'key': 'sport', 'label': 'Sport', 'emoji': '💃'},
    {'key': 'romantic', 'label': 'Romantique', 'emoji': '💕'},
    {'key': 'travel', 'label': 'Voyage', 'emoji': '✈️'},
    {'key': 'spiritual', 'label': 'Spirituel', 'emoji': '📖'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _apiService.getActivities(
      limit: 50,
      category: _selectedCategory,
    );
    // A newer load (another category) owns the screen now.
    if (!mounted || token != _loadToken) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case CoupleOk(:final value):
          _deck = value;
          _deckGeneration++;
          _topIndex = 0;
          _deckDone = value.isEmpty;
        case CoupleFailed(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Activités'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: coupleAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Couple',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: coupleAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bookmark),
            tooltip: 'Activités sauvegardées',
            onPressed: () => context.push('/couple/activities/saved'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '${cat['emoji']} ${cat['label']}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              selectedColor: coupleAccent,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() => _selectedCategory = cat['key']);
                _loadActivities();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ProfileCardSkeleton();
    }

    final failure = _failure;
    if (failure != null) {
      return CoupleMessageView.failure(failure, onRetry: _loadActivities);
    }

    if (_deckDone) {
      return CoupleMessageView(
        title: 'Aucune activité pour le moment',
        line: 'De nouvelles idées arrivent bientôt.',
        actionLabel: 'Actualiser',
        onAction: _loadActivities,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              key: ValueKey(_deckGeneration),
              controller: _controller,
              cardsCount: _deck.length,
              numberOfCardsDisplayed: _deck.length > 3 ? 3 : _deck.length,
              backCardOffset: const Offset(0, 40),
              padding: EdgeInsets.zero,
              isLoop: false,
              // Left = pass, up = save. A right swipe has no meaning here.
              allowedSwipeDirection: const AllowedSwipeDirection.only(
                left: true,
                up: true,
              ),
              onSwipe: _onSwipe,
              cardBuilder:
                  (
                    context,
                    index,
                    horizontalOffsetPercentage,
                    verticalOffsetPercentage,
                  ) {
                    final activity = _deck[index];
                    return _ActivityCard(
                      activity: activity,
                      swipeProgress: horizontalOffsetPercentage.toDouble(),
                      verticalProgress: verticalOffsetPercentage.toDouble(),
                      onTapDetails: () =>
                          context.push('/couple/activities/${activity.id}'),
                    );
                  },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: LucideIcons.x,
                color: AppColors.passRed,
                size: 60,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),
              _ActionButton(
                icon: LucideIcons.bookmark,
                color: coupleAccent,
                size: 70,
                onPressed: () => _controller.swipe(CardSwiperDirection.top),
              ),
              _ActionButton(
                icon: LucideIcons.info,
                color: AppColors.info,
                size: 60,
                onPressed: () {
                  if (_topIndex < _deck.length) {
                    context.push('/couple/activities/${_deck[_topIndex].id}');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final activity = _deck[previousIndex];
    _topIndex = currentIndex ?? _deck.length;

    if (direction == CardSwiperDirection.left) {
      _commit(activity, save: false);
    } else if (direction == CardSwiperDirection.top) {
      _commit(activity, save: true);
    } else {
      return false;
    }

    if (currentIndex == null) {
      // After the swiper finished its own bookkeeping for this swipe.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _topIndex >= _deck.length) {
          setState(() => _deckDone = true);
        }
      });
    }
    return true;
  }

  /// The card is already gone (optimistic); the server decides if it stays so.
  Future<void> _commit(CoupleActivity activity, {required bool save}) async {
    final result = save
        ? await _apiService.saveActivity(activity.id)
        : await _apiService.passActivity(activity.id);
    if (!mounted) return;

    switch (result) {
      case CoupleOk():
        if (save) _showSavedSnackbar(activity);
      case CoupleFailed():
        _restore(activity);
        showCoupleError(
          context,
          save
              ? 'Impossible de sauvegarder « ${activity.title} ». Réessayez.'
              : 'Impossible de passer « ${activity.title} ». Réessayez.',
        );
    }
  }

  /// Puts a card back on top of the deck after a failed call.
  void _restore(CoupleActivity activity) {
    setState(() {
      _deck = [activity, ..._deck.sublist(_topIndex.clamp(0, _deck.length))];
      _deckGeneration++;
      _topIndex = 0;
      _deckDone = false;
    });
  }

  void _showSavedSnackbar(CoupleActivity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.bookmark, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${activity.title} sauvegardé',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.swipeProgress,
    required this.verticalProgress,
    this.onTapDetails,
  });

  final CoupleActivity activity;
  final double swipeProgress;
  final double verticalProgress;
  final VoidCallback? onTapDetails;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            // Activity image
            if (activity.imageUrl != null)
              CachedNetworkImage(
                imageUrl: activity.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: coupleAccent.withValues(alpha: 0.3),
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
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Activity info
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: coupleAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activity.categoryEmoji} ${activity.categoryLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location & Price
                  Row(
                    children: [
                      if (activity.city != null) ...[
                        const Icon(
                          LucideIcons.mapPin,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activity.city!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.formattedPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description preview
                  Text(
                    activity.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Partner badge
                  if (activity.isPartner) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.badgePercent,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activity.discountPercent != null
                                ? '-${activity.discountPercent}% Partenaire MAZL'
                                : 'Partenaire MAZL',
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

                  // Kosher badge
                  if (activity.isKosher) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✡️', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 6),
                          Text(
                            'Casher',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Info button to view details
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onTapDetails,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
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

            // Rating badge
            if (activity.rating != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.star,
                        color: AppColors.accentGold,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (activity.reviewCount != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${activity.reviewCount})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Swipe overlay indicators
            if (swipeProgress < -10)
              Positioned(
                top: 60,
                right: 24,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.passRed, width: 4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PASS',
                      style: TextStyle(
                        color: AppColors.passRed,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 100.ms),
              ),

            if (verticalProgress < -10)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: coupleAccent, width: 4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bookmark,
                          color: coupleAccent,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SAVE',
                          style: TextStyle(
                            color: coupleAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
          colors: [coupleAccent, coupleAccent.withValues(alpha: 0.7)],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
