import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({
    super.key,
    this.userId,
    this.isOwnProfile = false,
  });

  final String? userId;
  final bool isOwnProfile;

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  UserProfile? _userProfile;
  Profile? _otherProfile;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.isOwnProfile || widget.userId == null) {
      // Load current user's profile
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null && mounted) {
        setState(() {
          _userProfile = response.data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      // Load another user's profile
      final userId = int.tryParse(widget.userId!);
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _apiService.getProfileById(userId);
      if (response.success && response.data != null && mounted) {
        setState(() {
          _otherProfile = response.data;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // Determine if viewing own profile or other user's profile
    final isOwnProfile = widget.isOwnProfile || _otherProfile == null;

    // Use profile data from API
    String userName;
    String userAge;
    String userLocation;
    String? userPicture;
    String userBio;
    bool isVerified;
    String? denomination;
    String? kashrut;
    String? shabbatObservance;
    List<String> photos;

    if (_otherProfile != null) {
      // Viewing another user's profile
      userName = _otherProfile!.displayName ?? 'Utilisateur';
      userAge = _otherProfile!.age?.toString() ?? '';
      userLocation = _otherProfile!.location ?? 'Non défini';
      userPicture = _otherProfile!.photos.isNotEmpty ? _otherProfile!.photos.first : null;
      userBio = _otherProfile!.bio ?? 'Aucune description';
      isVerified = _otherProfile!.isVerified;
      denomination = _otherProfile!.denomination;
      kashrut = _otherProfile!.kashrut;
      shabbatObservance = _otherProfile!.shabbatObservance;
      photos = _otherProfile!.photos;
    } else {
      // Viewing own profile
      final profile = _userProfile?.profile;
      userName = profile?.displayName ?? _userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
      userAge = profile?.age?.toString() ?? '';
      userLocation = profile?.location ?? 'Non défini';
      userPicture = _userProfile?.picture ?? currentUser?.photoUrl;
      userBio = profile?.bio ?? 'Aucune description';
      isVerified = profile?.isVerified ?? false;
      denomination = profile?.denomination;
      kashrut = profile?.kashrut;
      shabbatObservance = profile?.shabbatObservance;
      photos = profile?.photos ?? [];
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Profile header
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Profile image
                        if (userPicture != null)
                          CachedNetworkImage(
                            imageUrl: userPicture,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholder(),
                          )
                        else
                          _buildPlaceholder(),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Profile info
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    userAge.isNotEmpty ? '$userName, $userAge' : userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            LucideIcons.badgeCheck,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Vérifié',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    userLocation,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: isOwnProfile
                      ? [
                          IconButton(
                            icon: const Icon(LucideIcons.settings),
                            onPressed: () => context.go(RoutePaths.settings),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.pencil),
                            onPressed: () => context.go(RoutePaths.editProfile),
                          ),
                        ]
                      : null,
                ),

                // Profile content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bio
                        const Text(
                          'À propos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(userBio),

                        const SizedBox(height: 24),

                        // Jewish info
                        const Text(
                          'Ma pratique',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (denomination != null)
                          _InfoChip(icon: LucideIcons.star, label: denomination),
                        if (kashrut != null)
                          _InfoChip(icon: LucideIcons.utensilsCrossed, label: kashrut),
                        if (shabbatObservance != null)
                          _InfoChip(icon: LucideIcons.moonStar, label: shabbatObservance),

                        if (isOwnProfile) ...[
                          const SizedBox(height: 32),

                          // Quick actions for own profile
                          ListTile(
                            leading: const Icon(LucideIcons.sparkles, color: AppColors.accent),
                            title: const Text('AI Shadchan'),
                            subtitle: const Text('Voir les suggestions personnalisées'),
                            trailing: const Icon(LucideIcons.chevronRight),
                            onTap: () => context.go(RoutePaths.aiShadchan),
                          ),
                          ListTile(
                            leading: const Icon(LucideIcons.shieldCheck, color: AppColors.success),
                            title: const Text('Vérification'),
                            subtitle: const Text('Vérifier mon profil'),
                            trailing: const Icon(LucideIcons.chevronRight),
                            onTap: () => context.go(RoutePaths.verification),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.user,
          size: 120,
          color: Colors.white54,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
