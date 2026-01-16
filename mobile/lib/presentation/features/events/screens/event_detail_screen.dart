import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final ApiService _apiService = ApiService();

  Event? _event;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isRsvping = false;
  bool _hasRsvp = false;

  int get _eventId => int.tryParse(widget.eventId) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final response = await _apiService.getEvent(_eventId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _event = response.data;
          _hasRsvp = response.data!.userRsvpStatus != null;
        } else {
          _hasError = true;
        }
      });
    }
  }

  Future<void> _handleRsvp() async {
    if (_event == null || _isRsvping) return;

    setState(() => _isRsvping = true);

    if (_hasRsvp) {
      // Cancel RSVP
      final response = await _apiService.cancelRsvp(_eventId);
      if (mounted) {
        setState(() {
          _isRsvping = false;
          if (response.success) {
            _hasRsvp = false;
            _event = Event(
              id: _event!.id,
              title: _event!.title,
              description: _event!.description,
              eventType: _event!.eventType,
              location: _event!.location,
              address: _event!.address,
              date: _event!.date,
              time: _event!.time,
              endTime: _event!.endTime,
              price: _event!.price,
              currency: _event!.currency,
              maxAttendees: _event!.maxAttendees,
              attendeeCount: _event!.attendeeCount - 1,
              imageUrl: _event!.imageUrl,
              isPublished: _event!.isPublished,
              userRsvpStatus: null,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inscription annulée'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        });
      }
    } else {
      // Create RSVP
      final response = await _apiService.rsvpEvent(_eventId);
      if (mounted) {
        setState(() {
          _isRsvping = false;
          if (response.success) {
            _hasRsvp = true;
            _event = Event(
              id: _event!.id,
              title: _event!.title,
              description: _event!.description,
              eventType: _event!.eventType,
              location: _event!.location,
              address: _event!.address,
              date: _event!.date,
              time: _event!.time,
              endTime: _event!.endTime,
              price: _event!.price,
              currency: _event!.currency,
              maxAttendees: _event!.maxAttendees,
              attendeeCount: _event!.attendeeCount + 1,
              imageUrl: _event!.imageUrl,
              isPublished: _event!.isPublished,
              userRsvpStatus: 'going',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inscription confirmée !'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        });
      }
    }
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text('Événement introuvable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    final typeColor = _getTypeColor(event.eventType);
    final typeIcon = _getTypeIcon(event.eventType);
    final isFull = event.maxAttendees != null &&
        event.attendeeCount >= event.maxAttendees!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [typeColor, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(typeIcon, size: 80, color: Colors.white54),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [typeColor, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(typeIcon, size: 80, color: Colors.white54),
                      ),
                    ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(LucideIcons.arrowLeft, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(LucideIcons.share2, color: Colors.white),
                ),
                onPressed: () {
                  // TODO: Share event
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 16, color: typeColor),
                        const SizedBox(width: 6),
                        Text(
                          _getTypeLabel(event.eventType),
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Info cards
                  _InfoCard(
                    icon: LucideIcons.calendar,
                    title: 'Date',
                    subtitle: _formatDate(event.date),
                  ),
                  if (event.time != null)
                    _InfoCard(
                      icon: LucideIcons.clock,
                      title: 'Heure',
                      subtitle: event.endTime != null
                          ? '${event.time} - ${event.endTime}'
                          : event.time!,
                    ),
                  if (event.location != null)
                    _InfoCard(
                      icon: LucideIcons.mapPin,
                      title: 'Lieu',
                      subtitle: event.location!,
                      secondaryText: event.address,
                    ),
                  _InfoCard(
                    icon: LucideIcons.users,
                    title: 'Participants',
                    subtitle: event.maxAttendees != null
                        ? '${event.attendeeCount} / ${event.maxAttendees} places'
                        : '${event.attendeeCount} inscrits',
                    badge: isFull
                        ? 'Complet'
                        : event.maxAttendees != null &&
                                event.attendeeCount >=
                                    event.maxAttendees! * 0.8
                            ? 'Presque complet'
                            : null,
                    badgeColor: isFull ? Colors.red : AppColors.warning,
                  ),
                  _InfoCard(
                    icon: LucideIcons.euro,
                    title: 'Prix',
                    subtitle: event.price > 0
                        ? '${event.price.toStringAsFixed(0)}${event.currency == 'EUR' ? '€' : ' ${event.currency}'} par personne'
                        : 'Gratuit',
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // RSVP status
                  if (_hasRsvp)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.checkCircle,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Vous êtes inscrit(e) à cet événement',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
          child: _hasRsvp
              ? OutlinedButton(
                  onPressed: _isRsvping ? null : _handleRsvp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: _isRsvping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Annuler mon inscription'),
                )
              : ElevatedButton(
                  onPressed: isFull || _isRsvping ? null : _handleRsvp,
                  child: _isRsvping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isFull
                              ? 'Complet'
                              : event.price > 0
                                  ? 'S\'inscrire - ${event.price.toStringAsFixed(0)}${event.currency == 'EUR' ? '€' : ' ${event.currency}'}'
                                  : 'S\'inscrire gratuitement',
                        ),
                ),
        ),
      ),
    );
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'shabbat_dinner':
        return 'Shabbat Dinner';
      case 'speed_dating':
        return 'Speed Dating';
      case 'holiday':
        return 'Fête';
      case 'lecture':
        return 'Cours';
      case 'social':
        return 'Social';
      default:
        return 'Événement';
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.secondaryText,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? secondaryText;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.warning)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: badgeColor ?? AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (secondaryText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      secondaryText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
