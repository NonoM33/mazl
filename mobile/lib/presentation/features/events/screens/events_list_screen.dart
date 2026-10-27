import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/data_prefetch_service.dart';
import '../../../../core/services/premium_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../widgets/skeletons.dart';
import '../l10n/event_texts.dart';
import '../widgets/event_flight.dart';
import '../widgets/event_member_price.dart';
import '../widgets/event_photo.dart';
import '../../../../core/layout/fold_message_view.dart';
import 'package:mazl/core/layout/column_app_bar.dart';
import '../../../common/widgets/star_refresh/star_refresh.dart';

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

  String _filterLabel(AppLocalizations l10n, String type) => type == 'all'
      ? l10n.eventsFilterAll
      : EventKind.fromApi(type).filterLabel(l10n);

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
      if (_prefetchService.eventsNeedRefresh) {
        await _loadEvents(isRefresh: true);
      }
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
      appBar: ColumnAppBar(
        appBar: AppBar(title: Text(context.l10n.eventsTitle)),
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
                  color: Colors.black.withValues(alpha: 0.03),
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
                final isSelected =
                    (_selectedType ?? 'all') == type ||
                    (_selectedType == null && type == 'all');
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: GestureDetector(
                    onTap: () => _onTypeSelected(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getTypeColor(type == 'all' ? null : type)
                            : Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _getTypeColor(type == 'all' ? null : type)
                              : Colors.transparent,
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
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            _filterLabel(context.l10n, type),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
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

  /// The tab bar capsule is counted in the bottom padding (the shell's
  /// Scaffold extends its body under it).
  EdgeInsets _listPadding() => EdgeInsets.fromLTRB(
    16,
    16,
    16,
    16 + MediaQuery.paddingOf(context).bottom,
  );

  Widget _cardFor(Event event, {bool featured = false}) => _EventCard(
    event: event,
    typeColor: _getTypeColor(event.eventType),
    typeIcon: _getTypeIcon(event.eventType),
    featured: featured,
    onTap: () {
      EventFlights.prepare(event);
      context.go('/events/${event.id}');
    },
  );

  Widget _buildFlatList() => ListView.builder(
    padding: _listPadding(),
    itemCount: _events.length,
    itemBuilder: (context, index) => _cardFor(_events[index]),
  );

  /// Held like a book: the next event, large, on the reading-start page; the
  /// others as a list on the other page. No card crosses the fold.
  Widget _buildBook(FoldCut cut) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: cut.leadExtent,
        child: ListView(
          padding: _listPadding(),
          children: [_cardFor(_events.first, featured: true)],
        ),
      ),
      SizedBox(width: cut.gap),
      Expanded(
        child: _events.length > 1
            ? ListView(
                padding: _listPadding(),
                children: [
                  for (final event in _events.skip(1)) _cardFor(event),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    context.l10n.eventsNoOthers,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
      ),
    ],
  );

  Widget _buildBody() {
    // Show skeleton only on initial load
    if (_isInitialLoading && _events.isEmpty) {
      return const EventsListSkeleton();
    }

    if (_hasError && _events.isEmpty) {
      return FoldMessageView(
        icon: LucideIcons.wifiOff,
        title: context.l10n.eventsLoadError,
        actionLabel: context.l10n.commonRetry,
        onAction: _loadEvents,
      );
    }

    if (_events.isEmpty) {
      return FoldMessageView(
        icon: LucideIcons.calendar,
        iconColor: Theme.of(context).colorScheme.primary,
        title: context.l10n.eventsEmptyTitle,
        line: context.l10n.eventsEmptyHint,
      );
    }

    return Stack(
      children: [
        StarRefresh(
          onRefresh: () => _loadEvents(isRefresh: true),
          child: AnimatedOpacity(
            opacity: _isFilterLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: FoldCutBuilder(
              builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
                  ? _buildBook(cut!)
                  : _buildFlatList(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.eventsLoading,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
    this.featured = false,
  });

  /// The large card of the book layout: taller visual, longer title, and the
  /// description.
  final bool featured;

  final Event event;
  final Color typeColor;
  final IconData typeIcon;
  final VoidCallback onTap;

  String _formatDate(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return l10n.commonToday;
    } else if (diff.inDays == 1) {
      return l10n.eventsTomorrow;
    } else {
      return DateFormat.MMMMEEEEd(l10n.localeName).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
      shadowColor: typeColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image or gradient + overlays
            Stack(
              children: [
                EventFlightSource(
                  eventId: event.id,
                  child: SizedBox(
                    width: double.infinity,
                    height: featured ? 220 : 140,
                    child: EventPhoto(
                      imageUrl: event.imageUrl,
                      typeColor: typeColor,
                      typeIcon: typeIcon,
                    ),
                  ),
                ),
                // Gradient overlay for better text visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Type badge
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.4),
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
                          event.kind.label(l10n),
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
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.date.difference(DateTime.now()).inDays == 0
                                ? l10n.commonToday
                                : event.date
                                          .difference(DateTime.now())
                                          .inDays ==
                                      1
                                ? l10n.eventsTomorrow
                                : l10n.eventsInDays(
                                    event.date
                                        .difference(DateTime.now())
                                        .inDays,
                                  ),
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
                PositionedDirectional(
                  bottom: 12,
                  end: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: event.price > 0 ? Colors.white : AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      event.price > 0
                          ? eventPriceText(event, l10n.localeName)
                          : l10n.eventsFree,
                      style: TextStyle(
                        color: event.price > 0
                            ? AppColors.primary
                            : Colors.white,
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
                    style: TextStyle(
                      fontSize: featured ? 22 : 17,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (featured && (event.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Date and time with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: _readableOnSurface(context, typeColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event.time != null
                              ? l10n.eventsDateAtTime(
                                  _formatDate(l10n, event.date),
                                  eventClockText(event.time!, l10n.localeName),
                                )
                              : _formatDate(l10n, event.date),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: _readableOnSurface(context, typeColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // The mazl+ rate, next to the price on the photo
                  if (hasMemberReduction(event)) ...[
                    const SizedBox(height: 4),
                    EventMemberPrice(
                      event: event,
                      subscriber: PremiumGate.isPremium,
                      onOffer: () => context.push(RoutePaths.premium),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Bottom row: « Bientôt disponible » for an event not open
                  // yet, otherwise attendees count + capacity bar
                  if (event.isComingSoon)
                    _ComingSoonBadge(label: l10n.eventsComingSoon)
                  else ...[
                    Row(
                      children: [
                        Icon(
                          LucideIcons.users,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.maxAttendees != null
                              ? '${event.attendeeCount} / ${event.maxAttendees}'
                              : l10n.eventsAttendeesCount(event.attendeeCount),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        if (isAlmostFull) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.alertCircle,
                                    size: 12,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      l10n.eventsAlmostFull,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAlmostFull ? AppColors.warning : typeColor,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
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

/// « Bientôt disponible » on the card of an event whose registrations are not
/// open yet, where the attendees and the capacity bar would be.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.clock,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La couleur du type d'évènement quand elle sert de texte ou d'icône : le
/// tekhelet de marque est trop sombre sur le fond sombre, le thème en donne
/// la variante claire.
Color _readableOnSurface(BuildContext context, Color color) =>
    color == AppColors.primary ? Theme.of(context).colorScheme.primary : color;
