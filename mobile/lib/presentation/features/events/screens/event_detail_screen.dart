import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../l10n/event_texts.dart';
import '../../../../core/layout/fold_message_view.dart';
import '../../../common/widgets/fold_pages.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

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
              SnackBar(
                content: Text(context.l10n.eventsRsvpCancelled),
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
              SnackBar(
                content: Text(context.l10n.eventsRsvpDone),
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
    return DateFormat.yMMMMEEEEd(context.l10n.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const FoldSpinner(),
      );
    }

    if (_hasError || _event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: FoldMessageView(
          icon: LucideIcons.alertTriangle,
          title: context.l10n.eventsNotFound,
          actionLabel: context.l10n.commonBack,
          onAction: () => context.pop(),
        ),
      );
    }

    final event = _event!;
    final typeColor = _getTypeColor(event.eventType);
    final typeIcon = _getTypeIcon(event.eventType);

    return FoldCutBuilder(
      builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
          ? _buildBook(context, cut!, event, typeColor, typeIcon)
          : _buildFlat(context, event, typeColor, typeIcon),
    );
  }

  bool _isFull(Event event) =>
      event.maxAttendees != null && event.attendeeCount >= event.maxAttendees!;

  Widget _visual(Event event, Color typeColor, IconData typeIcon) {
    Widget gradient({Widget? child}) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
      ),
      child: child,
    );
    Widget fallback() => gradient(
      child: Center(child: Icon(typeIcon, size: 80, color: Colors.white54)),
    );
    return event.imageUrl != null
        ? CachedNetworkImage(
            imageUrl: event.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => gradient(),
            errorWidget: (context, url, error) => fallback(),
          )
        : fallback();
  }

  Widget _backButton() => IconButton(
    icon: const CircleAvatar(
      backgroundColor: Colors.black26,
      child: DirectionalIcon(LucideIcons.arrowLeft, color: Colors.white),
    ),
    onPressed: () => context.pop(),
  );

  Widget _shareButton() => IconButton(
    icon: const CircleAvatar(
      backgroundColor: Colors.black26,
      child: Icon(LucideIcons.share2, color: Colors.white),
    ),
    onPressed: () {
      final event = _event;
      if (event == null) return;
      Share.share(
        context.l10n.eventsShareMessage(event.title),
        subject: event.title,
      );
    },
  );

  /// Type badge and title.
  List<Widget> _headline(Event event, Color typeColor, IconData typeIcon) {
    final l10n = context.l10n;
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon, size: 16, color: typeColor),
            const SizedBox(width: 6),
            Text(
              event.kind.detailLabel(l10n),
              style: TextStyle(color: typeColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        event.title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
    ];
  }

  /// When and where.
  List<Widget> _whenAndWhere(Event event) {
    final l10n = context.l10n;
    return [
      _InfoCard(
        icon: LucideIcons.calendar,
        title: l10n.eventsInfoDate,
        subtitle: _formatDate(event.date),
      ),
      if (event.time != null)
        _InfoCard(
          icon: LucideIcons.clock,
          title: l10n.eventsInfoTime,
          subtitle: event.endTime != null
              ? '${event.time} - ${event.endTime}'
              : event.time!,
        ),
      if (event.location != null)
        _InfoCard(
          icon: LucideIcons.mapPin,
          title: l10n.eventsInfoPlace,
          subtitle: event.location!,
          secondaryText: event.address,
        ),
    ];
  }

  /// Who comes and what it costs.
  List<Widget> _participantsAndPrice(Event event) {
    final l10n = context.l10n;
    final isFull = _isFull(event);
    return [
      _InfoCard(
        icon: LucideIcons.users,
        title: l10n.eventsInfoParticipants,
        subtitle: event.maxAttendees != null
            ? l10n.eventsCapacity(event.attendeeCount, event.maxAttendees!)
            : l10n.eventsRegisteredCount(event.attendeeCount),
        badge: isFull
            ? l10n.eventsFull
            : event.maxAttendees != null &&
                  event.attendeeCount >= event.maxAttendees! * 0.8
            ? l10n.eventsAlmostFull
            : null,
        badgeColor: isFull ? Colors.red : AppColors.warning,
      ),
      _InfoCard(
        icon: LucideIcons.euro,
        title: l10n.eventsInfoPrice,
        subtitle: event.price > 0
            ? l10n.eventsPricePerPerson(eventPriceText(event, l10n.localeName))
            : l10n.eventsFree,
      ),
    ];
  }

  /// The description and, once registered, the confirmation banner.
  List<Widget> _aboutAndStatus(Event event) {
    final l10n = context.l10n;
    return [
      if (event.description != null && event.description!.isNotEmpty) ...[
        Text(
          l10n.eventsDescription,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          event.description!,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
      if (_hasRsvp)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.checkCircle, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.eventsRsvpConfirmedBanner,
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _rsvpButton(Event event) {
    final l10n = context.l10n;
    final isFull = _isFull(event);
    return _hasRsvp
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
                : Text(l10n.eventsRsvpCancel),
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
                        ? l10n.eventsFull
                        : event.price > 0
                        ? l10n.eventsRsvpJoinPaid(
                            eventPriceText(event, l10n.localeName),
                          )
                        : l10n.eventsRsvpJoinFree,
                  ),
          );
  }

  /// Held like a book: the visual, the title, the date and the place on the
  /// reading-start page; the description, the participants and price and the
  /// registration button on the other. Nothing sits in the fold.
  Widget _buildBook(
    BuildContext context,
    FoldCut cut,
    Event event,
    Color typeColor,
    IconData typeIcon,
  ) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _backButton(),
        actions: [_shareButton()],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: cut.leadExtent,
            child: ListView(
              padding: EdgeInsets.only(bottom: 16 + bottom),
              children: [
                SizedBox(
                  height: 280,
                  child: _visual(event, typeColor, typeIcon),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._headline(event, typeColor, typeIcon),
                      ..._whenAndWhere(event),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: cut.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      kToolbarHeight + MediaQuery.paddingOf(context).top + 16,
                      16,
                      16,
                    ),
                    children: [
                      ..._participantsAndPrice(event),
                      const SizedBox(height: 12),
                      ..._aboutAndStatus(event),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
                  child: _rsvpButton(event),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlat(
    BuildContext context,
    Event event,
    Color typeColor,
    IconData typeIcon,
  ) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _visual(event, typeColor, typeIcon),
            ),
            leading: _backButton(),
            actions: [_shareButton()],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._headline(event, typeColor, typeIcon),
                  ..._whenAndWhere(event),
                  ..._participantsAndPrice(event),
                  const SizedBox(height: 24),
                  ..._aboutAndStatus(event),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(child: FoldSafeActions(child: _rsvpButton(event))),
      ),
    );
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
              color: AppColors.primary.withValues(alpha: 0.1),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.warning).withValues(
                            alpha: 0.1,
                          ),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
