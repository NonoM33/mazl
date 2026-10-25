import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/likes/like_allowance.dart';
import '../../../../core/models/swipe_result.dart';
import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/store/credit_models.dart';
import '../../../../core/services/store/credits_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/l10n/api_error_text.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../chat/conversation_lookup.dart';
import '../widgets/match_sheet.dart';

/// Daily Picks Screen - Curated profiles for the user each day
class DailyPicksScreen extends StatefulWidget {
  const DailyPicksScreen({super.key, this.apiService});

  /// Injected by tests; the app uses the real service.
  final ApiService? apiService;

  @override
  State<DailyPicksScreen> createState() => _DailyPicksScreenState();
}

class _DailyPicksScreenState extends State<DailyPicksScreen> {
  late final ApiService _apiService = widget.apiService ?? ApiService();
  final CreditsService _credits = CreditsService();
  List<Profile> _dailyPicks = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  ApiErrorKind? _errorKind;
  DateTime? _nextRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadDailyPicks();
  }

  Future<void> _loadDailyPicks() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    // Try daily-picks endpoint first, fallback to discover profiles
    var response = await _apiService.getDailyPicks();

    // Fallback to discover profiles if daily-picks fails
    if (!response.success || response.data == null || response.data!.isEmpty) {
      final discoverResponse = await _apiService.getDiscoverProfiles(limit: 5);
      if (discoverResponse.success && discoverResponse.data != null) {
        response = ApiResponse.success(discoverResponse.data!);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _dailyPicks = response.data!;
          // Set next refresh time to midnight
          final now = DateTime.now();
          _nextRefreshTime = DateTime(now.year, now.month, now.day + 1);
        } else {
          _loadFailed = true;
          _errorKind = response.errorKind;
        }
      });
    }
  }

  /// Time left before the next picks (midnight), as whole hours and minutes.
  ({int hours, int minutes}) _timeUntilRefresh() {
    final next = _nextRefreshTime;
    if (next == null) return (hours: 0, minutes: 0);
    final diff = next.difference(DateTime.now());
    return (hours: diff.inHours, minutes: diff.inMinutes % 60);
  }

  Future<void> _handleLike(Profile profile) async {
    final response = await _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: 'like',
    );

    if (response.isLikesExhausted) {
      // The server counts the day's likes: it took none, the pick stays.
      if (!mounted) return;
      final allowance = response.exhaustedAllowance;
      await PremiumGate.showDailyLimitSheet(
        context,
        freeLikesPerDay: allowance?.dailyAllowance,
        resetsAt: allowance?.resetsAt,
      );
      return;
    }

    if (response.success && swipeMatched(response.data) && mounted) {
      _showMatchDialog(profile);
    }

    setState(() {
      _dailyPicks.removeWhere((p) => p.userId == profile.userId);
    });
  }

  Future<void> _handleSuperLike(Profile profile) async {
    // An unknown balance is not « none »: ask the server before refusing.
    if (!_credits.isLoaded) await _credits.refresh();
    if (!mounted) return;
    if (PremiumGate.remainingSuperLikes <= 0) {
      final bought = await PremiumGate.offerCredits(
        context,
        CreditKind.superLike,
      );
      if (!bought || !mounted) return;
    }

    final response = await _apiService.sendSwipe(
      targetUserId: profile.userId,
      action: 'super_like',
    );
    if (response.isCreditsExhausted) {
      // The server's balance (read from its answer) says none is left.
      if (mounted) {
        await PremiumGate.offerCredits(context, CreditKind.superLike);
      }
      return;
    }

    if (response.success && swipeMatched(response.data) && mounted) {
      _showMatchDialog(profile);
    }

    setState(() {
      _dailyPicks.removeWhere((p) => p.userId == profile.userId);
    });
  }

  Future<void> _showMatchDialog(Profile profile) async {
    final choice = await showMatchSheet(context, matched: profile);
    if (choice != MatchSheetChoice.message || !mounted) return;
    final route = await conversationRouteWith(_apiService, profile.userId);
    if (mounted) context.go(route);
  }

  /// The profile page sends the choice itself and leaves with it: the pick
  /// it was about leaves the grid.
  Future<void> _openProfile(Profile profile) async {
    final action = await context.push<String>(
      RoutePaths.profileViewPath(profile.userId.toString()),
    );
    if (action == null || !mounted) return;
    setState(() => _dailyPicks.removeWhere((p) => p.userId == profile.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.matchingDiscoverDailyPicks),
        leading: IconButton(
          icon: const DirectionalIcon(LucideIcons.arrowLeft),
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

    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              apiErrorText(context.l10n, _errorKind),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyPicks,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_dailyPicks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.matchingPicksSeenAll,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.matchingPicksNextIn(
                _timeUntilRefresh().hours,
                _timeUntilRefresh().minutes,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(RoutePaths.discover),
              icon: const Icon(LucideIcons.compass),
              label: Text(context.l10n.matchingPicksDiscoverMore),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.accentGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Wraps instead of overflowing with a large text size.
                  Flexible(
                    child: Text(
                      context.l10n.matchingPicksCount(_dailyPicks.length),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.matchingPicksUpdatedIn(
                  _timeUntilRefresh().hours,
                  _timeUntilRefresh().minutes,
                ),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Picks grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _dailyPicks.length,
            itemBuilder: (context, index) {
              final pick = _dailyPicks[index];
              final card = _DailyPickCard(
                profile: pick,
                onTap: () => _openProfile(pick),
                onLike: () => _handleLike(pick),
                onSuperLike: () => _handleSuperLike(pick),
              );
              // Reduced motion: the grid is simply there, no staggered pop.
              if (MazlMotion.reduced(context)) return card;
              return card.animate(delay: (index * 100).ms).fadeIn().scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _DailyPickCard extends StatelessWidget {
  const _DailyPickCard({
    required this.profile,
    required this.onTap,
    required this.onLike,
    required this.onSuperLike,
  });

  final Profile profile;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;

  @override
  Widget build(BuildContext context) {
    final imageUrl = profile.photos.isNotEmpty ? profile.photos.first : null;
    final name = profile.displayName ?? context.l10n.matchingCardAnonymous;
    final age = profile.age?.toString() ?? '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.user,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Daily pick badge
              PositionedDirectional(
                top: 8,
                start: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.matchingPicksBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Verified badge
              if (profile.isVerified)
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.badgeCheck,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Profile info
              Positioned(
                bottom: 60,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name, $age',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.location != null)
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.location!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Action buttons
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.heart,
                        label: context.l10n.matchingCardLike,
                        color: AppColors.likeGreen,
                        onPressed: onLike,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: LucideIcons.star,
                        label: context.l10n.matchingDiscoverSuperLike,
                        color: AppColors.superLikeBlue,
                        onPressed: onSuperLike,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;

  /// Read by VoiceOver and shown on long press: the button is an icon only.
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
