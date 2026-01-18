import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/saved_activities_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/skeletons.dart';

class CoupleActivitiesFeedScreen extends StatefulWidget {
  const CoupleActivitiesFeedScreen({super.key});

  @override
  State<CoupleActivitiesFeedScreen> createState() =>
      _CoupleActivitiesFeedScreenState();
}

class _CoupleActivitiesFeedScreenState extends State<CoupleActivitiesFeedScreen>
    with AutomaticKeepAliveClientMixin {
  final CardSwiperController _controller = CardSwiperController();
  final CoupleApiService _apiService = CoupleApiService();
  final SavedActivitiesService _savedService = SavedActivitiesService();

  List<CoupleActivity> _activities = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

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

  Future<void> _loadActivities({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final activities = await _apiService.getActivities(
        limit: 50,
        category: _selectedCategory,
      );

      setState(() {
        _activities = activities.isNotEmpty ? activities : _getDemoActivities();
        _isLoading = false;
      });
    } catch (e) {
      // Use demo activities when API fails
      debugPrint('CoupleActivities: Using demo data - $e');
      setState(() {
        _activities = _getDemoActivities();
        _isLoading = false;
      });
    }
  }

  List<CoupleActivity> _getDemoActivities() {
    final allActivities = [
      CoupleActivity(
        id: 1,
        title: 'Spa en duo',
        description: 'Moment de détente à deux avec massage, hammam et jacuzzi dans un cadre luxueux. Parfait pour se ressourcer ensemble.',
        category: 'wellness',
        imageUrl: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800',
        priceCents: 12000,
        city: 'Paris',
        rating: 4.8,
        reviewCount: 124,
        isKosher: true,
        isPartner: true,
        discountPercent: 15,
        durationMinutes: 120,
      ),
      CoupleActivity(
        id: 2,
        title: 'Cours de cuisine casher',
        description: 'Apprenez à préparer un repas gastronomique casher ensemble avec un chef professionnel.',
        category: 'gastronomy',
        imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
        priceCents: 8500,
        city: 'Paris',
        rating: 4.9,
        reviewCount: 89,
        isKosher: true,
        durationMinutes: 180,
      ),
      CoupleActivity(
        id: 3,
        title: 'Visite guidée du Marais juif',
        description: 'Découvrez l\'histoire et les secrets du quartier juif de Paris avec un guide passionné.',
        category: 'culture',
        imageUrl: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
        priceCents: 3500,
        city: 'Paris',
        rating: 4.7,
        reviewCount: 256,
        isKosher: true,
        durationMinutes: 120,
      ),
      CoupleActivity(
        id: 4,
        title: 'Dîner romantique casher',
        description: 'Savourez un dîner gastronomique dans un restaurant casher étoilé avec vue sur la Tour Eiffel.',
        category: 'romantic',
        imageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        priceCents: 15000,
        city: 'Paris',
        rating: 4.9,
        reviewCount: 312,
        isKosher: true,
        isPartner: true,
        discountPercent: 10,
        durationMinutes: 150,
      ),
    ];

    if (_selectedCategory != null) {
      return allActivities.where((a) => a.category == _selectedCategory).toList();
    }
    return allActivities;
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
                color: coupleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💑 Couple',
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
          // Saved activities button
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(LucideIcons.bookmark),
              ],
            ),
            tooltip: 'Activités sauvegardées',
            onPressed: () => context.push('/couple/activities/saved'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category filter chips
            _buildCategoryFilter(),

            // Main content
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
                setState(() {
                  _selectedCategory = cat['key'] as String?;
                });
                _loadActivities(isRefresh: true);
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
              onPressed: _loadActivities,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.sparkles, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Plus d\'activités disponibles',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'De nouvelles activités arrivent bientôt !',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadActivities,
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
              cardsCount: _activities.length,
              numberOfCardsDisplayed:
                  _activities.length > 3 ? 3 : _activities.length,
              backCardOffset: const Offset(0, 40),
              padding: EdgeInsets.zero,
              onSwipe: _onSwipe,
              cardBuilder: (context, index, horizontalOffsetPercentage,
                  verticalOffsetPercentage) {
                final activity = _activities[index];
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

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass
              _ActionButton(
                icon: LucideIcons.x,
                color: AppColors.passRed,
                size: 60,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),

              // Save/Bookmark
              _ActionButton(
                icon: LucideIcons.bookmark,
                color: coupleAccent,
                size: 70,
                onPressed: () => _controller.swipe(CardSwiperDirection.top),
              ),

              // Info/Details
              _ActionButton(
                icon: LucideIcons.info,
                color: AppColors.info,
                size: 60,
                onPressed: () {
                  if (_activities.isNotEmpty) {
                    context.push('/couple/activities/${_activities.first.id}');
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
    final activity = _activities[previousIndex];

    if (direction == CardSwiperDirection.left) {
      debugPrint('Passed ${activity.title}');
      // _apiService.passActivity(activity.id); // API not ready yet
    } else if (direction == CardSwiperDirection.top) {
      debugPrint('Saved ${activity.title}');
      // Save locally since API is not ready yet
      _savedService.saveActivity(activity);
      _showSavedSnackbar(activity);
    } else if (direction == CardSwiperDirection.right) {
      // Swipe right = show details (don't remove card)
      return false;
    }

    return true;
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
                '${activity.title} sauvegardé !',
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
            // Activity image
            if (activity.imageUrl != null)
              CachedNetworkImage(
                imageUrl: activity.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: coupleAccent.withOpacity(0.3),
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
                      Colors.black.withOpacity(0.9),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Partner badge
                  if (activity.isPartner) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.9),
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
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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

            // Rating badge
            if (activity.rating != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
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
                      border: Border.all(
                        color: AppColors.passRed,
                        width: 4,
                      ),
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
                      border: Border.all(
                        color: coupleAccent,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.bookmark,
                            color: coupleAccent, size: 28),
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
    );
  }
}
