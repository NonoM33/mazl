import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/skeletons.dart';

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
  bool _isLoading = true;
  String? _error;
  bool _coupleModeBannerDismissed = false;

  static const String _coupleModeBannerDismissedKey = 'couple_mode_banner_dismissed';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadBannerDismissedState();
  }

  Future<void> _loadBannerDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _coupleModeBannerDismissed = prefs.getBool(_coupleModeBannerDismissedKey) ?? false;
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

  String _formatMatchedAt(String? matchedAt) {
    if (matchedAt == null) return '';
    try {
      final date = DateTime.parse(matchedAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return "Aujourd'hui";
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays} jours';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
      } else {
        final months = (diff.inDays / 30).floor();
        return 'Il y a $months mois';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => const ListItemSkeleton(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les matchs',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMatches,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Pas encore de match',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue à découvrir des profils !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final coupleService = CoupleService();
    final isCoupleModeEnabled = coupleService.isCoupleModeEnabled;
    final showBanner = !isCoupleModeEnabled && !_coupleModeBannerDismissed;

    return RefreshIndicator(
      onRefresh: () => _loadMatches(isRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length + (showBanner ? 1 : 0),
        itemBuilder: (context, index) {
          // Show couple mode promotion banner at the top
          if (showBanner && index == 0) {
            return _CoupleModePromoBanner(
              onActivate: () => context.push('/couple/setup'),
              onDismiss: _dismissCoupleBanner,
            );
          }

          final matchIndex = showBanner ? index - 1 : index;
          final match = _matches[matchIndex];
          final profile = match['profile'] as Map<String, dynamic>?;

          if (profile == null) return const SizedBox.shrink();

          final userId = profile['user_id'] as int?;
          return _MatchCard(
            name: profile['display_name'] as String? ?? 'Inconnu',
            age: profile['age']?.toString(),
            location: profile['location'] as String?,
            picture: profile['picture'] as String?,
            isVerified: profile['is_verified'] == true,
            matchedAt: _formatMatchedAt(match['matchedAt'] as String?),
            onViewProfile: userId != null
                ? () => context.push(RoutePaths.matchProfilePath(userId.toString()))
                : null,
            onChat: () {
              final conversationId = match['conversationId'];
              if (conversationId != null) {
                context.go('/chat/$conversationId');
              }
            },
          );
        },
      ),
    );
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          // Close button
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.heartHandshake, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ca y est, tu as match ?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Active le mode couple !',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24), // Space for close button
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Questions quotidiennes, milestones, calendrier juif partage... Construis ta relation avec Mazl !',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onActivate,
                  icon: const Icon(LucideIcons.heart, size: 18),
                  label: const Text('Activer le mode couple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.name,
    this.age,
    this.location,
    this.picture,
    this.isVerified = false,
    required this.matchedAt,
    this.onViewProfile,
    required this.onChat,
  });

  final String name;
  final String? age;
  final String? location;
  final String? picture;
  final bool isVerified;
  final String matchedAt;
  final VoidCallback? onViewProfile;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: picture != null
                      ? CachedNetworkImageProvider(picture!)
                      : null,
                  child: picture == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            age != null ? '$name, $age' : name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            location!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      matchedAt,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat button
              ElevatedButton(
                onPressed: onChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(90, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Écrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
