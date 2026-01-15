import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({
    super.key,
    this.userId,
    this.isOwnProfile = false,
  });

  final String? userId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image placeholder
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white54,
                      ),
                    ),
                  ),
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
                            const Text(
                              'Sarah, 25',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                    Icons.verified,
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
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Paris',
                              style: TextStyle(color: Colors.white70),
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
                      icon: const Icon(Icons.settings),
                      onPressed: () => context.go(RoutePaths.settings),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
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
                  const Text(
                    'Amoureuse de la vie, des voyages et de la bonne cuisine. '
                    'À la recherche d\'une relation sérieuse avec quelqu\'un qui partage mes valeurs.',
                  ),

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
                  _InfoChip(icon: '✡', label: 'Modern Orthodox'),
                  _InfoChip(icon: '🍽️', label: 'Casher à la maison'),
                  _InfoChip(icon: '🕯️', label: 'Shabbat observant'),
                  _InfoChip(icon: '🏛️', label: 'Synagogue chaque semaine'),

                  const SizedBox(height: 24),

                  // Basic info
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoChip(icon: '📏', label: '165 cm'),
                  _InfoChip(icon: '💼', label: 'Designer'),
                  _InfoChip(icon: '🎓', label: 'Master'),
                  _InfoChip(icon: '🌍', label: 'Français, Anglais, Hébreu'),

                  const SizedBox(height: 24),

                  // Interests
                  const Text(
                    'Intérêts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InterestChip(label: 'Voyages'),
                      _InterestChip(label: 'Cuisine'),
                      _InterestChip(label: 'Musique'),
                      _InterestChip(label: 'Yoga'),
                      _InterestChip(label: 'Lecture'),
                      _InterestChip(label: 'Randonnée'),
                    ],
                  ),

                  if (isOwnProfile) ...[
                    const SizedBox(height: 32),

                    // Quick actions for own profile
                    ListTile(
                      leading: const Icon(Icons.auto_awesome, color: AppColors.accent),
                      title: const Text('AI Shadchan'),
                      subtitle: const Text('Voir les suggestions personnalisées'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(RoutePaths.aiShadchan),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user, color: AppColors.success),
                      title: const Text('Vérification'),
                      subtitle: const Text('Vérifier mon profil'),
                      trailing: const Icon(Icons.chevron_right),
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: BorderSide.none,
    );
  }
}
