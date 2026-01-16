import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final ApiService _apiService = ApiService();

  List<Event> _events = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _selectedType;

  final List<String> _eventTypes = [
    'all',
    'shabbat_dinner',
    'speed_dating',
    'holiday',
    'lecture',
    'social',
  ];

  final Map<String, String> _typeLabels = {
    'all': 'Tous',
    'shabbat_dinner': 'Shabbat',
    'speed_dating': 'Speed Dating',
    'holiday': 'Fêtes',
    'lecture': 'Cours',
    'social': 'Social',
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final response = await _apiService.getEvents(
      type: _selectedType == 'all' ? null : _selectedType,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _events = response.data!;
        } else {
          _hasError = true;
        }
      });
    }
  }

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type == 'all' ? null : type;
    });
    _loadEvents();
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'shabbat_dinner':
        return AppColors.accentGold;
      case 'speed_dating':
        return AppColors.secondary;
      case 'holiday':
        return AppColors.accent;
      case 'lecture':
        return AppColors.primary;
      case 'social':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'shabbat_dinner':
        return LucideIcons.utensilsCrossed;
      case 'speed_dating':
        return LucideIcons.heart;
      case 'holiday':
        return LucideIcons.partyPopper;
      case 'lecture':
        return LucideIcons.graduationCap;
      case 'social':
        return LucideIcons.users;
      default:
        return LucideIcons.calendar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendarDays),
            onPressed: () {
              // TODO: Show calendar view
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Type filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _eventTypes.length,
              itemBuilder: (context, index) {
                final type = _eventTypes[index];
                final isSelected = (_selectedType ?? 'all') == type ||
                    (_selectedType == null && type == 'all');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_typeLabels[type] ?? type),
                    selected: isSelected,
                    onSelected: (_) => _onTypeSelected(type),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),

          // Events list
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text('Impossible de charger les événements'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.calendar,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun événement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez bientôt pour découvrir\nde nouveaux événements !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _EventCard(
            event: event,
            typeColor: _getTypeColor(event.eventType),
            typeIcon: _getTypeIcon(event.eventType),
            onTap: () => context.go('/events/${event.id}'),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.typeColor,
    required this.typeIcon,
    required this.onTap,
  });

  final Event event;
  final Color typeColor;
  final IconData typeIcon;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return "Aujourd'hui";
    } else if (diff.inDays == 1) {
      return 'Demain';
    } else {
      return DateFormat('EEEE d MMMM', 'fr_FR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsLeft = event.maxAttendees != null
        ? event.maxAttendees! - event.attendeeCount
        : null;
    final isAlmostFull =
        spotsLeft != null && spotsLeft <= (event.maxAttendees! * 0.2);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image or gradient
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: event.imageUrl == null
                    ? LinearGradient(
                        colors: [typeColor, typeColor.withOpacity(0.7)],
                      )
                    : null,
              ),
              child: event.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, typeColor.withOpacity(0.7)],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, typeColor.withOpacity(0.7)],
                          ),
                        ),
                        child: Icon(typeIcon, size: 48, color: Colors.white54),
                      ),
                    )
                  : Center(
                      child: Icon(typeIcon, size: 48, color: Colors.white54),
                    ),
            ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date and time
                  Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(event.date)}${event.time != null ? ' à ${event.time}' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location
                  if (event.location != null)
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Bottom row: attendees + price
                  Row(
                    children: [
                      Icon(LucideIcons.users,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        event.maxAttendees != null
                            ? '${event.attendeeCount} / ${event.maxAttendees}'
                            : '${event.attendeeCount} participants',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (isAlmostFull) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Presque complet',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (event.price > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${event.price.toStringAsFixed(0)}${event.currency == 'EUR' ? '€' : event.currency}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Gratuit',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}
