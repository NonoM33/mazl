import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';

class CoupleEventsScreen extends StatefulWidget {
  const CoupleEventsScreen({super.key});

  @override
  State<CoupleEventsScreen> createState() => _CoupleEventsScreenState();
}

class _CoupleEventsScreenState extends State<CoupleEventsScreen>
    with SingleTickerProviderStateMixin {
  final CoupleApiService _apiService = CoupleApiService();
  late TabController _tabController;

  List<CoupleEvent> _allEvents = [];
  List<CoupleEvent> _registeredEvents = [];
  bool _isLoading = true;
  String? _selectedCategory;

  static const coupleAccent = Color(0xFFFF6B9D);

  // Event categories
  static const categories = [
    {'key': null, 'label': 'Tout', 'emoji': '📅'},
    {'key': 'dinner', 'label': 'Dîner', 'emoji': '🍽️'},
    {'key': 'tasting', 'label': 'Dégustation', 'emoji': '🍷'},
    {'key': 'party', 'label': 'Soirée', 'emoji': '🎉'},
    {'key': 'workshop', 'label': 'Atelier', 'emoji': '🎨'},
    {'key': 'brunch', 'label': 'Brunch', 'emoji': '🥐'},
    {'key': 'spiritual', 'label': 'Spirituel', 'emoji': '✡️'},
    {'key': 'travel', 'label': 'Week-end', 'emoji': '✈️'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getEvents(limit: 50, category: _selectedCategory),
        _apiService.getRegisteredEvents(),
      ]);

      setState(() {
        _allEvents = results[0];
        _registeredEvents = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Événements'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: coupleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '💑 Couples',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: coupleAccent,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: coupleAccent,
          labelColor: coupleAccent,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendar, size: 18),
                  const SizedBox(width: 6),
                  const Text('À venir'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle, size: 18),
                  const SizedBox(width: 6),
                  Text('Inscrits (${_registeredEvents.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(_allEvents, showRegisterButton: true),
                _buildEventsList(_registeredEvents, showRegisterButton: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '${cat['emoji']} ${cat['label']}',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              selectedColor: coupleAccent,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = cat['key'] as String?;
                });
                _loadEvents();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList(List<CoupleEvent> events,
      {required bool showRegisterButton}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendar, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              showRegisterButton
                  ? 'Aucun événement disponible'
                  : 'Vous n\'êtes inscrit à aucun événement',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (!showRegisterButton) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text('Découvrir les événements'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(
            event: event,
            showRegisterButton: showRegisterButton,
            onTap: () => context.push('/couple/events/${event.id}'),
            onRegister: () => _registerForEvent(event),
            onCancel: () => _cancelRegistration(event),
            isRegistered:
                _registeredEvents.any((e) => e.id == event.id),
          );
        },
      ),
    );
  }

  Future<void> _registerForEvent(CoupleEvent event) async {
    final success = await _apiService.registerForEvent(event.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inscrit à "${event.title}" !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'inscription'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelRegistration(CoupleEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inscription ?'),
        content: Text(
            'Voulez-vous vraiment annuler votre inscription à "${event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.cancelEventRegistration(event.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription annulée'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadEvents();
      }
    }
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.showRegisterButton,
    required this.onTap,
    required this.onRegister,
    required this.onCancel,
    required this.isRegistered,
  });

  final CoupleEvent event;
  final bool showRegisterButton;
  final VoidCallback onTap;
  final VoidCallback onRegister;
  final VoidCallback onCancel;
  final bool isRegistered;

  static const coupleAccent = Color(0xFFFF6B9D);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: event.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: coupleAccent.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),

                // Date badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.eventDate.day.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: coupleAccent,
                          ),
                        ),
                        Text(
                          _getMonthAbbr(event.eventDate.month),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured badge
                if (event.isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.star, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'À la une',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Kosher badge
                if (event.isKosher)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✡️ Casher',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    '${event.categoryEmoji} ${event.category ?? 'Événement'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: coupleAccent,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Info row
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.formattedDate} ${event.formattedTime}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (event.city != null) ...[
                        Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.city!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom row: Price + Spots + Button
                  Row(
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Spots left
                      if (event.maxCouples != null) ...[
                        Icon(
                          LucideIcons.users,
                          size: 16,
                          color: event.isFull
                              ? AppColors.error
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isFull
                              ? 'Complet'
                              : '${event.spotsLeft} places',
                          style: TextStyle(
                            color: event.isFull
                                ? AppColors.error
                                : Colors.grey[600],
                            fontSize: 13,
                            fontWeight:
                                event.isFull ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Register/Cancel button
                      if (showRegisterButton && !isRegistered && !event.isFull)
                        ElevatedButton(
                          onPressed: onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: coupleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('S\'inscrire'),
                        )
                      else if (isRegistered)
                        OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: coupleAccent.withOpacity(0.3),
      child: Center(
        child: Text(
          event.categoryEmoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return months[month - 1];
  }
}
