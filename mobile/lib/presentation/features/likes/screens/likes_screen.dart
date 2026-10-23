import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../common/widgets/mazl_components.dart';
import '../widgets/like_widgets.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Screen showing users who have liked the current user
/// Free users see blurred photos, premium users see clear photos
class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  LikesData? _likesData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getReceivedLikes();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _likesData = result.data;
        } else {
          _error = result.error;
        }
      });
    }
  }

  String _formatLikesCount(int count) {
    if (count <= 10) return '$count';
    if (count <= 25) return '10+';
    if (count <= 50) return '25+';
    if (count <= 99) return '50+';
    return '99+';
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

        // Check if it's a match
        if (result.data?['matched'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Match avec ${profile.displayName}'),
              action: SnackBarAction(
                label: 'Message',
                onPressed: () => context.push(RoutePaths.chat),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vous avez liké ${profile.displayName}')),
          );
        }
      }
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoundIconButton(
          icon: LucideIcons.arrowLeft,
          tooltip: 'Retour',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: 24),
        Text('Likes', style: Theme.of(context).textTheme.displaySmall),
        if (hasLikes) ...[
          const SizedBox(height: 12),
          SectionLabel(
            'Ils vous ont aimé · ${_formatLikesCount(data.totalCount)}',
          ),
        ],
        if (hasLikes && !data.isPremium) ...[
          const SizedBox(height: 8),
          Text(
            '${_formatLikesCount(data.totalCount)} personnes attendent votre réponse.',
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _scrollable(List<Widget> children) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: _loadLikes,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
        children: [_buildHeader(), ...children],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _scrollable(const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]);
    }

    if (_error != null) return _scrollable([_buildError()]);

    if (_likesData == null || _likesData!.likes.isEmpty) {
      return _scrollable([_buildEmptyState()]);
    }

    final data = _likesData!;
    final isPremium = data.isPremium;
    final likes = data.likes;

    return _scrollable([
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
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
            name: like.displayName ?? 'Anonyme',
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
      if (!isPremium) ...[
        const SizedBox(height: 24),
        MazlPlusPill(
          prefix: 'Voir qui vous a aimé avec ',
          onPressed: () => context.push(RoutePaths.premium),
        ),
      ],
    ]);
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
            'Erreur de chargement',
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _loadLikes, child: const Text('Réessayer')),
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
            'Pas encore de likes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Continuez à découvrir des profils et complétez votre profil pour attirer plus de likes.',
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
            child: const Text('Découvrir des profils'),
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
          context.push(RoutePaths.profileViewPath(profile.userId.toString()));
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
                    text: '+',
                    style: TextStyle(color: scheme.primary),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Découvrez qui vous a aimé et matchez tout de suite avec les personnes qui vous plaisent.',
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
                child: const Text('Voir les offres'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Plus tard'),
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
    final name = profile.displayName ?? 'Anonyme';
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
                    '${profile.distance!.round()} km',
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
                    child: const Text('Passer'),
                  ),
                ),
                const SizedBox(width: 12),
                RoundIconButton(
                  icon: LucideIcons.user,
                  tooltip: 'Voir le profil',
                  size: 56,
                  onPressed: onViewProfile,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onLike,
                    child: const Text("J'aime"),
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
