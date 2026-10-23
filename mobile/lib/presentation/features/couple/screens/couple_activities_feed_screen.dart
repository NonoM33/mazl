import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../widgets/skeletons.dart';
import '../widgets/activity_visual.dart';
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

  static const categories = [
    (key: null, label: 'Tout'),
    (key: 'wellness', label: 'Bien-être'),
    (key: 'gastronomy', label: 'Gastro'),
    (key: 'culture', label: 'Culture'),
    (key: 'sport', label: 'Sport'),
    (key: 'romantic', label: 'Romantique'),
    (key: 'travel', label: 'Voyage'),
    (key: 'spiritual', label: 'Spirituel'),
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
        title: const Text('Activités'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: RoundIconButton(
                icon: LucideIcons.bookmark,
                tooltip: 'Activités sauvegardées',
                size: 40,
                iconSize: 18,
                onPressed: () => context.push('/couple/activities/saved'),
              ),
            ),
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
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryChip(
            label: cat.label,
            selected: _selectedCategory == cat.key,
            onTap: () {
              setState(() => _selectedCategory = cat.key);
              _loadActivities();
            },
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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
                    // Only the card on top carries text: the ones stacked
                    // behind are bare, opaque shells.
                    if (index != _topIndex) return const _CardBack();
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoundIconButton(
                icon: LucideIcons.x,
                tooltip: 'Passer',
                size: 60,
                iconSize: 26,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),
              RoundIconButton(
                icon: LucideIcons.bookmark,
                tooltip: 'Enregistrer',
                size: 72,
                iconSize: 30,
                style: RoundButtonStyle.ink,
                onPressed: () => _controller.swipe(CardSwiperDirection.top),
              ),
              RoundIconButton(
                icon: LucideIcons.info,
                tooltip: 'Voir le détail',
                size: 60,
                iconSize: 26,
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
    final onSnack = Theme.of(context).colorScheme.onInverseSurface;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.bookmark, color: onSnack, size: 18),
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
        action: SnackBarAction(
          label: 'Voir',
          textColor: onSnack,
          onPressed: () => context.push('/couple/activities/saved'),
        ),
      ),
    );
  }
}

/// Puce de catégorie : brume au repos, encre pleine quand elle est choisie.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = selected ? scheme.onSurface : scheme.surfaceContainer;
    final foreground = selected ? scheme.surface : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card waiting behind the one on top: opaque and empty, so nothing of its
/// text shows through where the stack is offset.
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final city = activity.city;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image zone: nothing of the text zone is ever drawn over it.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ActivityVisual(activity: activity),
                  if (activity.rating != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: TagPill(
                        _ratingLabel(activity),
                        icon: LucideIcons.star,
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: RoundIconButton(
                      icon: LucideIcons.info,
                      tooltip: 'Voir le détail',
                      size: 40,
                      iconSize: 18,
                      onPressed: onTapDetails,
                    ),
                  ),
                  if (swipeProgress < -10)
                    Positioned(
                      top: 64,
                      right: 24,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: _Stamp(label: 'PASSER', color: scheme.onSurface),
                      ).animate().fadeIn(duration: 100.ms),
                    ),
                  if (verticalProgress < -10)
                    Positioned(
                      top: 64,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _Stamp(
                          label: 'GARDER',
                          color: scheme.primary,
                          icon: LucideIcons.bookmark,
                        ),
                      ).animate().fadeIn(duration: 100.ms),
                    ),
                ],
              ),
            ),
            // Text zone: a plain, opaque colour.
            ColoredBox(
              color: scheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TagPill(
                      activity.categoryLabel,
                      icon: activityCategoryIcon(activity.category),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      activity.title,
                      style: textTheme.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (city != null) ...[
                          Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              city,
                              style: textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          activity.formattedPrice,
                          style: textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity.isPartner || activity.isKosher) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (activity.isPartner)
                            AccentPill(
                              activity.discountPercent != null
                                  ? '-${activity.discountPercent} % Partenaire MAZL'
                                  : 'Partenaire MAZL',
                              icon: LucideIcons.badgePercent,
                            ),
                          if (activity.isKosher) const TagPill('Casher'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(CoupleActivity activity) {
    final rating = activity.rating!.toStringAsFixed(1);
    final count = activity.reviewCount;
    return count == null ? rating : '$rating ($count)';
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
