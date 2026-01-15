import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // TODO: Show calendar view
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EventCard(
            title: 'Shabbat Dinner - Communauté Paris 16',
            date: 'Vendredi 24 Janvier',
            time: '19:00',
            location: 'Paris 16ème',
            attendees: 24,
            maxAttendees: 30,
            type: EventType.shabbatDinner,
            eventId: 'event_1',
          ),
          _EventCard(
            title: 'Speed Dating 25-35 ans',
            date: 'Dimanche 26 Janvier',
            time: '15:00',
            location: 'Paris 3ème',
            attendees: 18,
            maxAttendees: 20,
            type: EventType.speedDating,
            eventId: 'event_2',
          ),
          _EventCard(
            title: 'Tu BiShvat Party',
            date: 'Jeudi 13 Février',
            time: '20:00',
            location: 'Paris 11ème',
            attendees: 45,
            maxAttendees: 100,
            type: EventType.holiday,
            eventId: 'event_3',
          ),
          _EventCard(
            title: 'Cours de Torah - Les Pirkei Avot',
            date: 'Mercredi 29 Janvier',
            time: '19:30',
            location: 'En ligne',
            attendees: 12,
            type: EventType.lecture,
            eventId: 'event_4',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create event
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum EventType {
  shabbatDinner,
  speedDating,
  holiday,
  lecture,
  social,
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.attendees,
    this.maxAttendees,
    required this.type,
    required this.eventId,
  });

  final String title;
  final String date;
  final String time;
  final String location;
  final int attendees;
  final int? maxAttendees;
  final EventType type;
  final String eventId;

  Color get _typeColor {
    switch (type) {
      case EventType.shabbatDinner:
        return AppColors.accentGold;
      case EventType.speedDating:
        return AppColors.secondary;
      case EventType.holiday:
        return AppColors.accent;
      case EventType.lecture:
        return AppColors.primary;
      case EventType.social:
        return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case EventType.shabbatDinner:
        return Icons.dinner_dining;
      case EventType.speedDating:
        return Icons.favorite;
      case EventType.holiday:
        return Icons.celebration;
      case EventType.lecture:
        return Icons.school;
      case EventType.social:
        return Icons.groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/events/$eventId'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_typeColor, _typeColor.withOpacity(0.7)],
                ),
              ),
              child: Row(
                children: [
                  Icon(_typeIcon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text('$date à $time'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Text(location),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        maxAttendees != null
                            ? '$attendees / $maxAttendees participants'
                            : '$attendees participants',
                      ),
                      const Spacer(),
                      if (maxAttendees != null &&
                          attendees >= maxAttendees! * 0.8)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Presque complet',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
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
