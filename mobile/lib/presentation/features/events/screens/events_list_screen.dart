import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/skeletons.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen>
    with AutomaticKeepAliveClientMixin {
  final DataPrefetchService _prefetchService = DataPrefetchService();
  final ApiService _apiService = ApiService();

  List<Event> _events = [];
  bool _isInitialLoading = true;
  bool _isFilterLoading = false;
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Try to use prefetched data first
    final cachedEvents = _prefetchService.events;
    if (cachedEvents != null && cachedEvents.isNotEmpty) {
      setState(() {
        _events = cachedEvents;
        _isInitialLoading = false;
      });
    } else {
      // Load from API if no cached data
      await _loadEvents();
    }
  }

  Future<void> _loadEvents({bool isRefresh = false}) async {
    // Don't show skeleton if we already have data
    if (_events.isEmpty && !isRefresh) {
      setState(() {
        _isInitialLoading = true;
        _hasError = false;
      });
    }

    final response = await _apiService.getEvents(
      type: _selectedType == 'all' ? null : _selectedType,
    );

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
        _isFilterLoading = false;
        if (response.success && response.data != null) {
          _events = response.data!;
        } else if (_events.isEmpty) {
          _hasError = true;
        }
      });
    }
  }

  void _onTypeSelected(String type) {
    if (_selectedType == type || (type == 'all' && _selectedType == null)) {
      return;
    }

    setState(() {
      _selectedType = type == 'all' ? null : type;
      _isFilterLoading = true;
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
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evenements'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendarDays),
            onPressed: () {},
            tooltip: 'Calendrier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Type filter chips - improved design
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _eventTypes.length,
              itemBuilder: (context, index) {
                final type = _eventTypes[index];
                final isSelected = (_selectedType ?? 'all') == type ||
                    (_selectedType == null && type == 'all');
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _onTypeSelected(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _getTypeColor(type == 'all' ? null : type) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _getTypeColor(type == 'all' ? null : type) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (type != 'all') ...[
                            Icon(
                              _getTypeIcon(type),
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _typeLabels[type] ?? type,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
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
    // Show skeleton only on initial load
    if (_isInitialLoading && _events.isEmpty) {
      return const EventsListSkeleton();
    }

    if (_hasError && _events.isEmpty) {
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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _loadEvents(isRefresh: true),
          child: AnimatedOpacity(
            opacity: _isFilterLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
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
          ),
        ),
        // Subtle loading indicator for filter changes
        if (_isFilterLoading)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chargement...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'shabbat_dinner':
        return 'Shabbat';
      case 'speed_dating':
        return 'Speed Dating';
      case 'holiday':
        return 'Fete';
      case 'lecture':
        return 'Cours';
      case 'social':
        return 'Social';
      default:
        return 'Evenement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotsLeft = event.maxAttendees != null
        ? event.maxAttendees! - event.attendeeCount
        : null;
    final isAlmostFull =
        spotsLeft != null && spotsLeft <= (event.maxAttendees! * 0.2);
    final isSoon = event.date.difference(DateTime.now()).inDays <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: typeColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image or gradient + overlays
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: event.imageUrl == null
                        ? LinearGradient(
                            colors: [typeColor, typeColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
                                strokeWidth: 2,
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
                // Gradient overlay for better text visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeLabel(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // "Bientot" badge if within 3 days
                if (isSoon)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            event.date.difference(DateTime.now()).inDays == 0
                                ? "Aujourd'hui"
                                : event.date.difference(DateTime.now()).inDays == 1
                                    ? 'Demain'
                                    : 'Dans ${event.date.difference(DateTime.now()).inDays}j',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Price badge at bottom right
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: event.price > 0 ? Colors.white : AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      event.price > 0
                          ? '${event.price.toStringAsFixed(0)}${event.currency == 'EUR' ? '€' : event.currency}'
                          : 'Gratuit',
                      style: TextStyle(
                        color: event.price > 0 ? AppColors.primary : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date and time with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(LucideIcons.calendar, size: 16, color: typeColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_formatDate(event.date)}${event.time != null ? ' a ${event.time}' : ''}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (event.location != null)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.mapPin, size: 16, color: typeColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // Bottom row: attendees count + capacity bar
                  Row(
                    children: [
                      Icon(LucideIcons.users, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        event.maxAttendees != null
                            ? '${event.attendeeCount} / ${event.maxAttendees}'
                            : '${event.attendeeCount} participants',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      if (isAlmostFull) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.alertCircle, size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              const Text(
                                'Presque complet',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Capacity progress bar
                  if (event.maxAttendees != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: event.attendeeCount / event.maxAttendees!,
                        backgroundColor: Colors.grey.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAlmostFull ? AppColors.warning : typeColor,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
