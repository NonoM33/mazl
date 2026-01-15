import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentGold, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.dinner_dining,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Shabbat Dinner - Communauté Paris 16',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Info cards
                  _InfoCard(
                    icon: Icons.calendar_today,
                    title: 'Date & Heure',
                    subtitle: 'Vendredi 24 Janvier à 19:00',
                  ),
                  _InfoCard(
                    icon: Icons.location_on,
                    title: 'Lieu',
                    subtitle: '12 Rue de la Pompe, 75016 Paris',
                  ),
                  _InfoCard(
                    icon: Icons.people,
                    title: 'Participants',
                    subtitle: '24 / 30 places',
                  ),
                  _InfoCard(
                    icon: Icons.euro,
                    title: 'Prix',
                    subtitle: '35€ par personne',
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez-nous pour un magnifique Shabbat dinner dans une ambiance chaleureuse et conviviale. '
                    'Au programme : prières, repas traditionnel et rencontres entre célibataires de la communauté.\n\n'
                    'Menu casher supervisé.\n'
                    'Dress code : élégant décontracté.',
                  ),

                  const SizedBox(height: 24),

                  // Organizer
                  Text(
                    'Organisateur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        'D',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: const Text('David L.'),
                    subtitle: const Text('Organisateur vérifié'),
                    trailing: TextButton(
                      onPressed: () {
                        // TODO: Contact organizer
                      },
                      child: const Text('Contacter'),
                    ),
                  ),

                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              // TODO: RSVP to event
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inscription confirmée !'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('S\'inscrire - 35€'),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
