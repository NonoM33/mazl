import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_grid.dart';
import '../../../../core/models/swipe_result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/back_icon.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../chat/conversation_lookup.dart';
import '../../matching/widgets/match_sheet.dart';
import '../widgets/like_widgets.dart';
import '../../../common/widgets/mazl_sheet.dart';
import 'package:mazl/core/layout/bar_navigation.dart';
import '../../../common/widgets/star_refresh/star_refresh.dart';

/// Screen showing users who have liked the current user
/// Free users see blurred photos, premium users see clear photos
class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();

  bool _isLoading = true;
  LikesData? _likesData;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    final result = await _apiService.getReceivedLikes();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _likesData = result.data;
        } else {
          _loadFailed = true;
        }
      });
    }
  }

  /// The count shown to a free member, by bands (« 10+ »), and the number
  /// that picks the plural form of the sentence around it.
  ({String label, int plural}) _likesBand(int count) {
    if (count <= 10) return (label: '$count', plural: count);
    if (count <= 25) return (label: '10+', plural: 10);
    if (count <= 50) return (label: '25+', plural: 25);
    if (count <= 99) return (label: '50+', plural: 50);
    return (label: '99+', plural: 99);
  }

  Future<void> _handleLike(LikeProfile profile) async {
    final result = await _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: 'like',
    );

    if (mounted) {
      if (result.success) {
        // Remove from list
        setState(() {
          _likesData?.likes.removeWhere((l) => l.userId == profile.userId);
        });

        if (swipeMatched(result.data)) {
          await _showMatch(profile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.likesYouLiked(profile.displayName ?? ''),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showMatch(LikeProfile like) async {
    final matched = Profile(
      id: like.userId,
      userId: like.userId,
      displayName: like.displayName,
      age: like.age,
      photos: [if (like.picture != null) like.picture!],
      isVerified: like.isVerified,
    );
    final choice = await showMatchSheet(context, matched: matched);
    if (choice != MatchSheetChoice.message || !mounted) return;
    final route = await conversationRouteWith(_apiService, like.userId);
    if (mounted) context.go(route);
  }

  /// The profile page sends the choice itself and leaves with it.
  Future<void> _openProfile(LikeProfile profile) async {
    final action = await context.push<String>(
      RoutePaths.profileViewPath(profile.userId.toString()),
    );
    if (action == null || !mounted) return;
    setState(() {
      _likesData?.likes.removeWhere((l) => l.userId == profile.userId);
    });
  }

  Future<void> _handlePass(LikeProfile profile) async {
    final result = await _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: 'pass',
    );

    if (mounted && result.success) {
      setState(() {
        _likesData?.likes.removeWhere((l) => l.userId == profile.userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(bottom: false, child: _buildBody()));
  }

  Widget _buildHeader() {
    final data = _likesData;
    final hasLikes = data != null && data.totalCount > 0;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final band = hasLikes ? _likesBand(data.totalCount) : null;
    // Own `onPressed` on this page's context: with a vertical bar the button
    // is drawn above the navigator.
    Widget back() => RoundIconButton(
      icon: backArrowIcon(context),
      tooltip: l10n.commonBack,
      onPressed: () => context.pop(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BarNavigation(
          buttons: [back()],
          inline: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [back(), const SizedBox(height: 24)],
          ),
        ),
        Text(l10n.likesTitle, style: Theme.of(context).textTheme.displaySmall),
        if (band != null) ...[
          const SizedBox(height: 12),
          SectionLabel(l10n.likesSection(band.label)),
        ],
        if (data != null && band != null && !data.isPremium) ...[
          const SizedBox(height: 8),
          Text(
            l10n.likesWaiting(band.plural, band.label),
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  static const _pagePadding = 24.0;

  /// [child] kept on the reading-start page while a fold runs down the
  /// screen: the title, the sentences and the buttons around the grid never
  /// reach the curve. Flat, it is left as it is.
  Widget _onFirstPage(FoldCut? cut, Widget child) {
    if (cut == null || cut.axis != FoldSplitAxis.vertical) return child;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: cut.leadExtent - _pagePadding, child: child),
    );
  }

  Widget _scrollable(List<Widget> Function(FoldCut? cut) children) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return FoldCutBuilder(
      builder: (context, cut) => StarRefresh(
        onRefresh: _loadLikes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            _pagePadding,
            16,
            _pagePadding,
            bottom + 24,
          ),
          children: [_onFirstPage(cut, _buildHeader()), ...children(cut)],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _scrollable(
        (_) => const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_loadFailed) {
      return _scrollable((cut) => [_onFirstPage(cut, _buildError())]);
    }

    if (_likesData == null || _likesData!.likes.isEmpty) {
      return _scrollable((cut) => [_onFirstPage(cut, _buildEmptyState())]);
    }

    final data = _likesData!;
    final isPremium = data.isPremium;
    final likes = data.likes;

    return _scrollable(
      (cut) => [
        LayoutBuilder(
          builder: (context, box) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            // Two columns flat; held like a book, the columns fall on either
            // side of the fold.
            gridDelegate: FoldGridDelegate(
              cut: cut,
              crossAxisStart: _pagePadding,
              maxCrossAxisExtent: (box.maxWidth - 10) / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: isPremium ? 200 + LikeCard.actionsExtent : 120,
            ),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final like = likes[index];
              if (!isPremium) {
                return LockedLikeTile(onTap: _showPremiumPrompt);
              }
              return LikeCard(
                name: like.displayName ?? context.l10n.matchingCardAnonymous,
                age: like.age,
                pictureUrl: like.photoUrl,
                isVerified: like.isVerified,
                seed: like.userId,
                onTap: () => _showProfilePreview(like),
                onLike: () => _handleLike(like),
                onPass: () => _handlePass(like),
              );
            },
          ),
        ),
        if (!isPremium) ...[
          const SizedBox(height: 24),
          _onFirstPage(
            cut,
            MazlPlusPill(
              label: context.l10n.likesSeeWhoWithPlus,
              onPressed: () => context.push(RoutePaths.premium),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.commonLoadError,
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadLikes,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(LucideIcons.heart, size: 32, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            context.l10n.likesEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.likesEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.discover),
            child: Text(context.l10n.likesEmptyAction),
          ),
        ],
      ),
    );
  }

  void _showProfilePreview(LikeProfile profile) {
    showMazlSheet<void>(
      context,
      isScrollControlled: true,
      builder: (context) => _ProfilePreviewSheet(
        profile: profile,
        onLike: () {
          Navigator.pop(context);
          _handleLike(profile);
        },
        onPass: () {
          Navigator.pop(context);
          _handlePass(profile);
        },
        onViewProfile: () {
          Navigator.pop(context);
          _openProfile(profile);
        },
      ),
    );
  }

  void _showPremiumPrompt() {
    showMazlSheet<void>(
      context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'mazl',
                children: [
                  TextSpan(
                    // A left-to-right mark keeps the plus glued to « mazl » in Hebrew.
                    text: '+\u200E',
                    style: TextStyle(color: scheme.primary),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.likesPremiumBody,
              style: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(RoutePaths.premium);
                },
                child: Text(context.l10n.likesPremiumOffers),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonLater),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfilePreviewSheet extends StatelessWidget {
  const _ProfilePreviewSheet({
    required this.profile,
    required this.onLike,
    required this.onPass,
    required this.onViewProfile,
  });

  final LikeProfile profile;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = profile.displayName ?? context.l10n.matchingCardAnonymous;
    final title = profile.age != null ? '$name, ${profile.age}' : name;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ProfilePhoto(
                      url: profile.photoUrl,
                      seed: profile.userId,
                      radius: 24,
                      iconSize: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.badgeCheck,
                        size: 22,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
                if (profile.distance != null) ...[
                  const SizedBox(height: 8),
                  TagPill(
                    context.l10n.likesDistance(profile.distance!.round()),
                    icon: LucideIcons.mapPin,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPass,
                    child: Text(context.l10n.matchingCardPass),
                  ),
                ),
                const SizedBox(width: 12),
                RoundIconButton(
                  icon: LucideIcons.user,
                  tooltip: context.l10n.matchingCardViewProfile,
                  size: 56,
                  onPressed: onViewProfile,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onLike,
                    child: Text(context.l10n.matchingCardLike),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
