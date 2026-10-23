import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart' hide ProfilePhoto;
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../widgets/skeletons.dart';
import '../../likes/widgets/like_widgets.dart';
import '../widgets/avatar_ring.dart';

/// Nombre maximal de likes aperçus sur l'écran des matchs.
const int _likesPreviewCount = 4;

/// Un match est « nouveau » pendant sa première semaine.
const int _newMatchDays = 7;

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with AutomaticKeepAliveClientMixin {
  final DataPrefetchService _prefetchService = DataPrefetchService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _matches = [];
  LikesData? _likesData;
  bool _isLoading = true;
  String? _error;
  bool _coupleModeBannerDismissed = false;

  static const String _coupleModeBannerDismissedKey =
      'couple_mode_banner_dismissed';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadBannerDismissedState();
    _loadLikes();
  }

  Future<void> _loadBannerDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _coupleModeBannerDismissed =
            prefs.getBool(_coupleModeBannerDismissedKey) ?? false;
      });
    }
  }

  Future<void> _dismissCoupleBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coupleModeBannerDismissedKey, true);
    if (mounted) {
      setState(() {
        _coupleModeBannerDismissed = true;
      });
    }
  }

  Future<void> _initializeData() async {
    // Try to use prefetched data first
    final cachedMatches = _prefetchService.matches;
    if (cachedMatches != null && cachedMatches.isNotEmpty) {
      setState(() {
        _matches = cachedMatches;
        _isLoading = false;
      });
    } else {
      // Load from API if no cached data
      await _loadMatches();
    }
  }

  Future<void> _loadMatches({bool isRefresh = false}) async {
    if (!isRefresh && _matches.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await _apiService.getMatches();
      if (response.success && response.data != null) {
        setState(() {
          _matches = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          if (_matches.isEmpty) {
            _error = response.error ?? 'Erreur inconnue';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (_matches.isEmpty) {
          _error = e.toString();
        }
        _isLoading = false;
      });
    }
  }

  /// Les likes sont un aperçu : un échec les masque, sans bloquer les matchs.
  Future<void> _loadLikes() async {
    try {
      final result = await _apiService.getReceivedLikes();
      if (mounted && result.success && result.data != null) {
        setState(() => _likesData = result.data);
      }
    } catch (e) {
      debugPrint('Aperçu des likes indisponible: $e');
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadMatches(isRefresh: true), _loadLikes()]);
  }

  bool _isNewMatch(String? matchedAt) {
    final date = matchedAt == null ? null : DateTime.tryParse(matchedAt);
    if (date == null) return false;
    return DateTime.now().difference(date).inDays < _newMatchDays;
  }

  String _formatMatchedAt(String? matchedAt) {
    final date = matchedAt == null ? null : DateTime.tryParse(matchedAt);
    if (date == null) return '';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return "Aujourd'hui";
    if (days == 1) return 'Hier';
    if (days < 7) return 'Il y a $days jours';
    if (days < 30) {
      final weeks = (days / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    }
    final months = (days / 30).floor();
    return 'Il y a $months mois';
  }

  void _openChat(Map<String, dynamic> match) {
    final conversationId = match['conversationId'];
    if (conversationId != null) {
      context.go('/chat/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              ..._buildMatchesContent(),
              ..._buildLikesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Matchs',
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        RoundIconButton(
          icon: LucideIcons.heart,
          tooltip: 'Qui vous a aimé',
          onPressed: () => context.push(RoutePaths.likes),
        ),
      ],
    );
  }

  List<Widget> _buildMatchesContent() {
    if (_isLoading) {
      return [for (var i = 0; i < 6; i++) const ListItemSkeleton()];
    }
    if (_error != null) return [_buildError()];
    if (_matches.isEmpty) return [_buildEmpty()];

    final matches = _matches
        .where((m) => m['profile'] is Map<String, dynamic>)
        .toList(growable: false);
    final newCount = matches
        .where((m) => _isNewMatch(m['matchedAt'] as String?))
        .length;
    final showBanner =
        !CoupleService().isCoupleModeEnabled && !_coupleModeBannerDismissed;

    return [
      if (showBanner) ...[
        _CoupleModePromoBanner(
          onActivate: () => context.push('/couple/setup'),
          onDismiss: _dismissCoupleBanner,
        ),
        const SizedBox(height: 24),
      ],
      SectionLabel('Nouveaux · $newCount'),
      const SizedBox(height: 16),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final match = matches[index];
            final profile = match['profile'] as Map<String, dynamic>;
            return AvatarRing(
              name: profile['display_name'] as String? ?? 'Inconnu',
              pictureUrl: profile['picture'] as String?,
              seed: (profile['user_id'] as int?) ?? index,
              isNew: _isNewMatch(match['matchedAt'] as String?),
              onTap: () => _openChat(match),
            );
          },
        ),
      ),
      const SizedBox(height: 24),
      SectionLabel('Conversations · ${matches.length}'),
      const SizedBox(height: 8),
      for (var i = 0; i < matches.length; i++) _buildMatchRow(matches[i], i),
    ];
  }

  Widget _buildMatchRow(Map<String, dynamic> match, int index) {
    final profile = match['profile'] as Map<String, dynamic>;
    final userId = profile['user_id'] as int?;
    return _MatchRow(
      name: profile['display_name'] as String? ?? 'Inconnu',
      age: profile['age']?.toString(),
      location: profile['location'] as String?,
      picture: profile['picture'] as String?,
      seed: userId ?? index,
      isVerified: profile['is_verified'] == true,
      matchedAt: _formatMatchedAt(match['matchedAt'] as String?),
      onChat: () => _openChat(match),
      onViewProfile: userId != null
          ? () => context.push(RoutePaths.matchProfilePath(userId.toString()))
          : null,
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
            'Impossible de charger les matchs',
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadMatches, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(LucideIcons.heart, size: 32, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Pas encore de match',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Continuez à découvrir des profils.',
            style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLikesSection() {
    final data = _likesData;
    if (data == null || data.likes.isEmpty) return const [];

    final preview = data.likes.take(_likesPreviewCount).toList(growable: false);
    final remaining = data.totalCount - preview.length;
    final isPremium = data.isPremium;

    return [
      const SizedBox(height: 32),
      SectionLabel('Ils vous ont aimé · ${data.totalCount}'),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: isPremium ? 200 : 120,
        ),
        itemCount: preview.length,
        itemBuilder: (context, index) {
          final like = preview[index];
          if (!isPremium) {
            return LockedLikeTile(
              onTap: () => context.push(RoutePaths.premium),
            );
          }
          return LikeCard(
            name: like.displayName ?? 'Anonyme',
            age: like.age,
            pictureUrl: like.photoUrl,
            isVerified: like.isVerified,
            seed: like.userId,
            onTap: () => context.push(RoutePaths.likes),
          );
        },
      ),
      if (!isPremium) ...[
        const SizedBox(height: 16),
        MazlPlusPill(
          prefix: remaining > 0
              ? 'Voir les $remaining autres avec '
              : 'Voir qui vous a aimé avec ',
          onPressed: () => context.push(RoutePaths.premium),
        ),
      ] else if (remaining > 0) ...[
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push(RoutePaths.likes),
            child: Text('Voir les $remaining autres'),
          ),
        ),
      ],
    ];
  }
}

class _CoupleModePromoBanner extends StatelessWidget {
  const _CoupleModePromoBanner({
    required this.onActivate,
    required this.onDismiss,
  });

  final VoidCallback onActivate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ça y est, vous avez matché ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Masquer',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: onDismiss,
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              'Questions quotidiennes, étapes, calendrier juif partagé : construisez votre relation avec mazl.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActivate,
                child: const Text('Activer le mode couple'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne de conversation : photo ronde de 56, nom, une ligne discrète et
/// l'ancienneté à droite. Toucher la ligne ouvre le chat, la photo le profil.
class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.name,
    this.age,
    this.location,
    this.picture,
    this.seed = 0,
    this.isVerified = false,
    required this.matchedAt,
    this.onViewProfile,
    required this.onChat,
  });

  final String name;
  final String? age;
  final String? location;
  final String? picture;
  final int seed;
  final bool isVerified;
  final String matchedAt;
  final VoidCallback? onViewProfile;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = age != null ? '$name, $age' : name;
    final subtitle = (location != null && location!.isNotEmpty)
        ? location!
        : 'Écrivez-lui';
    return InkWell(
      onTap: onChat,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Semantics(
              button: onViewProfile != null,
              label: 'Voir le profil de $name',
              child: GestureDetector(
                onTap: onViewProfile,
                child: SizedBox.square(
                  dimension: 56,
                  child: ProfilePhoto(
                    url: picture,
                    seed: seed,
                    radius: 28,
                    iconSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (matchedAt.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                matchedAt,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
