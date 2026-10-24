import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_activity.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/swipe_deck/swipe_deck.dart';
import '../../../widgets/skeletons.dart';
import '../l10n/couple_feed_labels.dart';
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
  final SwipeDeckController _swipeDeck = SwipeDeckController();
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();

  /// The deck as the swipe deck sees it. Only replaced by a (re)load or a
  /// rollback, together with [_deckGeneration], so the deck never sees its
  /// count change.
  List<CoupleActivity> _deck = [];
  int _deckGeneration = 0;

  /// Index in [_deck] of the card on top.
  int _topIndex = 0;
  bool _deckDone = false;

  bool _isLoading = true;
  CoupleFailure? _failure;
  String? _selectedCategory;
  int _loadToken = 0;

  static const categories = <String?>[
    null,
    'wellness',
    'gastronomy',
    'culture',
    'sport',
    'romantic',
    'travel',
    'spiritual',
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
    _swipeDeck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.coupleFeedActivitiesTitle,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        height: 1.05,
                      ),
                    ),
                  ),
                  RoundIconButton(
                    icon: LucideIcons.bookmark,
                    tooltip: context.l10n.coupleFeedSavedTitle,
                    onPressed: () => context.push('/couple/activities/saved'),
                  ),
                ],
              ),
            ),
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
            label: activityFilterLabel(context.l10n, cat),
            selected: _selectedCategory == cat,
            onTap: () {
              setState(() => _selectedCategory = cat);
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
      return coupleFailureView(context, failure, onRetry: _loadActivities);
    }

    if (_deckDone) {
      final l10n = context.l10n;
      return CoupleMessageView(
        title: l10n.coupleFeedActivitiesEmptyTitle,
        line: l10n.coupleFeedActivitiesEmptyLine,
        actionLabel: l10n.coupleFeedRefresh,
        onAction: _loadActivities,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: SwipeDeck(
              key: ValueKey(_deckGeneration),
              controller: _swipeDeck,
              itemCount: _deck.length,
              // Left = pass, up = save. A right swipe has no meaning here.
              allowed: const {SwipeDirection.left, SwipeDirection.up},
              intents: {
                SwipeDirection.left: const SwipeIntent(
                  icon: LucideIcons.x,
                  color: AppColors.muted,
                ),
                SwipeDirection.up: SwipeIntent(
                  icon: LucideIcons.bookmark,
                  color: Theme.of(context).colorScheme.primary,
                ),
              },
              onSwiped: _onSwiped,
              onEnd: _onDeckEnd,
              cardBuilder: (context, index, isTop) {
                // Only the card on top carries text: the one behind is a bare,
                // opaque shell.
                if (!isTop) return const _CardBack();
                final activity = _deck[index];
                return _ActivityCard(
                  activity: activity,
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
              SwipeProgressScale(
                progress: _swipeDeck.progress,
                direction: SwipeDirection.left,
                child: RoundIconButton(
                  icon: LucideIcons.x,
                  tooltip: context.l10n.commonSkip,
                  size: 60,
                  iconSize: 26,
                  onPressed: () => _swipeDeck.swipe(SwipeDirection.left),
                ),
              ),
              SwipeProgressScale(
                progress: _swipeDeck.progress,
                direction: SwipeDirection.up,
                child: RoundIconButton(
                  icon: LucideIcons.bookmark,
                  tooltip: context.l10n.commonSave,
                  size: 72,
                  iconSize: 30,
                  style: RoundButtonStyle.ink,
                  onPressed: () => _swipeDeck.swipe(SwipeDirection.up),
                ),
              ),
              RoundIconButton(
                icon: LucideIcons.info,
                tooltip: context.l10n.coupleFeedSeeDetail,
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

  void _onSwiped(int index, SwipeDirection direction) {
    _topIndex = index + 1;
    _commit(_deck[index], save: direction == SwipeDirection.up);
  }

  void _onDeckEnd() {
    if (mounted && _topIndex >= _deck.length) {
      setState(() => _deckDone = true);
    }
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
              ? context.l10n.coupleFeedActivitySaveCardError(activity.title)
              : context.l10n.coupleFeedActivityPassCardError(activity.title),
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
                context.l10n.coupleFeedActivitySavedSnack(activity.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.l10n.commonSee,
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
    this.onTapDetails,
  });

  final CoupleActivity activity;
  final VoidCallback? onTapDetails;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
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
                    PositionedDirectional(
                      top: 16,
                      start: 16,
                      child: TagPill(
                        activity.ratingLabel(l10n),
                        icon: LucideIcons.star,
                      ),
                    ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: RoundIconButton(
                      icon: LucideIcons.info,
                      tooltip: l10n.coupleFeedSeeDetail,
                      size: 40,
                      iconSize: 18,
                      onPressed: onTapDetails,
                    ),
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
                      activity.categoryName(l10n),
                      icon: activityCategoryIcon(activity.category),
                      onCard: true,
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
                          activity.priceLabel(l10n),
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
                                  ? l10n.coupleFeedPartnerDiscountMazl(
                                      activity.discountPercent!,
                                    )
                                  : l10n.coupleFeedPartnerMazl,
                              icon: LucideIcons.badgePercent,
                            ),
                          if (activity.isKosher)
                            TagPill(l10n.coupleFeedKosher, onCard: true),
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
}
