import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

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
              content: Text('Match avec ${profile.displayName} !'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Message',
                textColor: Colors.white,
                onPressed: () => context.push(RoutePaths.chat),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tu as like ${profile.displayName}'),
              backgroundColor: AppColors.primary,
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Qui t\'a like'),
            if (_likesData != null && _likesData!.totalCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatLikesCount(_likesData!.totalCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadLikes,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_likesData == null || _likesData!.likes.isEmpty) {
      return _buildEmptyState();
    }

    final isPremium = _likesData!.isPremium;

    return RefreshIndicator(
      onRefresh: _loadLikes,
      child: Column(
        children: [
          // Premium upsell banner for free users
          if (!isPremium)
            _buildPremiumBanner(),

          // Likes grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _likesData!.likes.length,
              itemBuilder: (context, index) {
                final like = _likesData!.likes[index];
                return _LikeCard(
                  profile: like,
                  isPremium: isPremium,
                  onTap: isPremium
                      ? () => _showProfilePreview(like)
                      : () => _showPremiumPrompt(),
                  onLike: isPremium ? () => _handleLike(like) : null,
                  onPass: isPremium ? () => _handlePass(like) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.heart,
                size: 48,
                color: AppColors.secondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pas encore de likes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue a swiper et complete ton profil pour attirer plus de likes !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(RoutePaths.discover),
              icon: const Icon(LucideIcons.compass),
              label: const Text('Decouvrir des profils'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFa29bfe)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.crown,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Decouvre qui t\'aime',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatLikesCount(_likesData!.totalCount)} personnes attendent ta reponse',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push(RoutePaths.premium),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C5CE7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Voir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePreview(LikeProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFa29bfe)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.crown,
                color: Colors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Passe Premium',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Decouvre qui t\'a like et match instantanement avec les personnes qui te plaisent !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Voir les offres Premium',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.profile,
    required this.isPremium,
    required this.onTap,
    this.onLike,
    this.onPass,
  });

  final LikeProfile profile;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo (blurred for free users)
              _buildPhoto(),

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
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Name and info
              Positioned(
                left: 12,
                right: 12,
                bottom: isPremium ? 60 : 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isPremium
                                ? '${profile.displayName}${profile.age != null ? ', ${profile.age}' : ''}'
                                : profile.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.badgeCheck,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    if (isPremium && profile.distance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.distance!.round()} km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Lock icon for free users
              if (!isPremium)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

              // Action buttons for premium users
              if (isPremium && onLike != null && onPass != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.x,
                          color: Colors.grey,
                          onTap: onPass!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: LucideIcons.heart,
                          color: AppColors.secondary,
                          onTap: onLike!,
                        ),
                      ),
                    ],
                  ),
                ),

              // Time badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatLikedAt(profile.likedAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (profile.photoUrl == null) {
      return Container(
        color: AppColors.primary.withOpacity(0.3),
        child: Center(
          child: Text(
            profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: profile.photoUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.primary.withOpacity(0.3),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.primary.withOpacity(0.3),
        child: const Icon(LucideIcons.user, color: Colors.white, size: 48),
      ),
    );

    // Apply blur for free users
    if (!isPremium) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  String _formatLikedAt(DateTime likedAt) {
    final now = DateTime.now();
    final diff = now.difference(likedAt);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${likedAt.day}/${likedAt.month}';
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Photo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (profile.photoUrl != null)
                      CachedNetworkImage(
                        imageUrl: profile.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: AppColors.primary.withOpacity(0.3),
                        child: Center(
                          child: Text(
                            profile.displayName.isNotEmpty
                                ? profile.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    // Info
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${profile.displayName}${profile.age != null ? ', ${profile.age}' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (profile.isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.badgeCheck,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                          if (profile.distance != null) ...[
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
                                  '${profile.distance!.round()} km',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                // Pass button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPass,
                    icon: const Icon(LucideIcons.x),
                    label: const Text('Passer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View profile button
                IconButton(
                  onPressed: onViewProfile,
                  icon: const Icon(LucideIcons.user),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(width: 12),
                // Like button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onLike,
                    icon: const Icon(LucideIcons.heart),
                    label: const Text('J\'aime'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
