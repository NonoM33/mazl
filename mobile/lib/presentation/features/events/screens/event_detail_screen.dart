import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/share/share_sheet.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../l10n/event_texts.dart';
import '../widgets/event_flight.dart';
import '../widgets/event_info_tile.dart';
import '../widgets/event_photo.dart';
import '../widgets/event_place_map.dart';
import '../../../../core/layout/fold_message_view.dart';
import '../../../common/widgets/fold_pages.dart';
import 'package:mazl/core/layout/bar_navigation.dart';
import 'package:mazl/core/layout/column_app_bar.dart';
import 'package:mazl/core/layout/vertical_bar.dart';

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
  bool _isAlerting = false;

  int get _eventId => int.tryParse(widget.eventId) ?? 0;

  /// The photo's flight between the card and the header, once the page knows
  /// whether it is reduced motion (first `didChangeDependencies`).
  EventFlightController? _flight;
  EventFlight? _opening;
  final GlobalKey _headerKey = GlobalKey(debugLabel: 'event-header');

  @override
  void initState() {
    super.initState();
    // The list already knows this event: show it at once, refresh behind.
    _opening = EventFlights.take(_eventId);
    final known = _opening?.event;
    if (known != null) {
      _event = known;
      _hasRsvp = known.userRsvpStatus != null;
      _isLoading = false;
    }
    _loadEvent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flight != null) return;
    final opening = _opening;
    final expectFlight = opening?.from != null && !MazlMotion.reduced(context);
    final flight = EventFlightController(
      eventId: _eventId,
      expectFlight: expectFlight,
    );
    _flight = flight;
    if (!expectFlight) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      flight.attach(
        context,
        from: opening?.from,
        headerKey: _headerKey,
        photo: (context) {
          final event = _event;
          return EventPhoto(
            imageUrl: event?.imageUrl,
            typeColor: _getTypeColor(event?.eventType),
            typeIcon: _getTypeIcon(event?.eventType),
            fallbackEnd: AppColors.primary,
            iconSize: 80,
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _flight?.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final refreshing = _event != null;
    if (!refreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final response = await _apiService.getEvent(_eventId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _event = response.data;
          _hasRsvp = response.data!.userRsvpStatus != null;
          _hasError = false;
        } else if (!refreshing) {
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
            _event = _event!.copyWith(
              attendeeCount: _event!.attendeeCount - 1,
              userRsvpStatus: () => null,
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
            _event = _event!.copyWith(
              attendeeCount: _event!.attendeeCount + 1,
              userRsvpStatus: () => 'going',
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

  /// « Me prévenir » on a coming soon event, or « Vous serez prévenu » touched
  /// again to withdraw the alert.
  Future<void> _toggleAlert() async {
    final event = _event;
    if (event == null || _isAlerting) return;
    final requested = !event.notifyRequested;
    setState(() => _isAlerting = true);
    final response = await _apiService.setEventAlert(
      _eventId,
      requested: requested,
    );
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _isAlerting = false;
      if (response.success) {
        _event = event.copyWith(notifyRequested: requested);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !response.success
              ? l10n.eventsNotifyError
              : requested
              ? l10n.eventsNotifyRequestedDone
              : l10n.eventsNotifyCancelled,
        ),
        backgroundColor: response.success
            ? AppColors.success
            : AppColors.warning,
      ),
    );
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
        appBar: ColumnAppBar(appBar: AppBar()),
        body: const FoldSpinner(),
      );
    }

    if (_hasError || _event == null) {
      return Scaffold(
        appBar: ColumnAppBar(appBar: AppBar()),
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

  /// The photo, hidden while the flying one covers it, with the scrim that
  /// keeps the badge and the title readable.
  Widget _photoLayer(Event event, Color typeColor, IconData typeIcon) {
    final flight = _flight!;
    return SizedBox.expand(
      key: _headerKey,
      child: ValueListenableBuilder<bool>(
        valueListenable: flight.flying,
        builder: (context, flying, child) =>
            Opacity(opacity: flying ? 0 : 1, child: child),
        child: EventPhoto(
          imageUrl: event.imageUrl,
          typeColor: typeColor,
          typeIcon: typeIcon,
          fallbackEnd: AppColors.primary,
          iconSize: 80,
          scrim: EventPhotoScrim.bottom,
        ),
      ),
    );
  }

  /// Kind badge and large title, on the photo. They fade in when the photo
  /// has landed, and out when it leaves.
  Widget _titleOnPhoto(Event event, Color typeColor, IconData typeIcon) {
    final l10n = context.l10n;
    final fade = MazlMotion.reduced(context)
        ? Duration.zero
        : MazlMotion.eventPhotoFade;
    return ValueListenableBuilder<bool>(
      valueListenable: _flight!.flying,
      builder: (context, flying, child) => AnimatedOpacity(
        opacity: flying ? 0 : 1,
        duration: fade,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  event.kind.detailLabel(l10n),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// The photo, full frame, with the title at its foot.
  Widget _header(
    Event event,
    Color typeColor,
    IconData typeIcon, {
    double titleFade = 1,
  }) => Stack(
    fit: StackFit.expand,
    children: [
      _photoLayer(event, typeColor, typeIcon),
      PositionedDirectional(
        start: 16,
        end: 16,
        bottom: 16,
        child: Opacity(
          opacity: titleFade,
          child: _titleOnPhoto(event, typeColor, typeIcon),
        ),
      ),
    ],
  );

  Widget _backButton() => IconButton(
    icon: const CircleAvatar(
      backgroundColor: Colors.black38,
      child: DirectionalIcon(LucideIcons.arrowLeft, color: Colors.white),
    ),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => context.pop(),
  );

  /// The share button. It reads its own box (not the page's) to tell the share
  /// sheet where to point: on a large screen iOS refuses a sheet without an
  /// origin, and the buttons of the vertical bar live above the navigator.
  Widget _shareButton() => Builder(
    builder: (buttonContext) => IconButton(
      icon: const CircleAvatar(
        backgroundColor: Colors.black38,
        child: Icon(LucideIcons.share2, color: Colors.white),
      ),
      tooltip: context.l10n.commonShare,
      onPressed: () => _share(buttonContext),
    ),
  );

  Future<void> _share(BuildContext buttonContext) async {
    final event = _event;
    if (event == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final shared = await ShareSheet.share(
      buttonContext,
      text: l10n.eventsShareMessage(event.title),
      subject: event.title,
    );
    if (!shared && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.eventsShareError)));
    }
  }

  /// Date, time, place, participants and price, in a compact grid.
  Widget _infoGrid(Event event) {
    final l10n = context.l10n;
    final isFull = _isFull(event);
    final time = eventTimeText(event, l10n);
    final date = EventInfoTile(
      icon: LucideIcons.calendar,
      title: l10n.eventsInfoDate,
      value: _formatDate(event.date),
    );
    final clock = time == null
        ? null
        : EventInfoTile(
            icon: LucideIcons.clock,
            title: l10n.eventsInfoTime,
            value: time,
          );
    final place = event.location == null
        ? null
        : EventInfoTile(
            icon: LucideIcons.mapPin,
            title: l10n.eventsInfoPlace,
            value: event.location!,
            secondary: event.address,
          );
    final participants = EventInfoTile(
      icon: LucideIcons.users,
      title: l10n.eventsInfoParticipants,
      value: event.maxAttendees != null
          ? l10n.eventsCapacity(event.attendeeCount, event.maxAttendees!)
          : l10n.eventsRegisteredCount(event.attendeeCount),
      badge: isFull
          ? l10n.eventsFull
          : event.maxAttendees != null &&
                event.attendeeCount >= event.maxAttendees! * 0.8
          ? l10n.eventsAlmostFull
          : null,
      badgeColor: isFull ? Colors.red : AppColors.warning,
    );
    final price = EventInfoTile(
      icon: LucideIcons.euro,
      title: l10n.eventsInfoPrice,
      value: event.price > 0
          ? l10n.eventsPricePerPerson(eventPriceText(event, l10n.localeName))
          : l10n.eventsFree,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clock != null) EventInfoRow(children: [date, clock]) else date,
        if (place != null) ...[const SizedBox(height: 10), place],
        const SizedBox(height: 10),
        EventInfoRow(children: [participants, price]),
      ],
    );
  }

  /// The place on a map, when the event has coordinates. The pin is exact
  /// only once registrations are open and the event gives an address.
  Widget? _map(Event event) {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) return null;
    return EventPlaceMap(
      latitude: latitude,
      longitude: longitude,
      placeName: event.location,
      preciseAddress:
          !event.isComingSoon && (event.address ?? '').trim().isNotEmpty,
    );
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

  /// Registrations not open yet: « Bientôt disponible », disabled, and the
  /// alert the member may ask for.
  Widget _comingSoonActions(Event event) {
    final l10n = context.l10n;
    final requested = event.notifyRequested;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.clock, size: 18),
          label: Text(l10n.eventsComingSoon),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isAlerting ? null : _toggleAlert,
          icon: _isAlerting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  requested ? LucideIcons.bellRing : LucideIcons.bell,
                  size: 18,
                ),
          label: Text(
            requested ? l10n.eventsNotifyRequested : l10n.eventsNotifyMe,
          ),
        ),
      ],
    );
  }

  Widget _rsvpButton(Event event) {
    final l10n = context.l10n;
    final isFull = _isFull(event);
    if (event.isComingSoon) return _comingSoonActions(event);
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

  /// Held like a book (or opened wide): the photo with the title and the map
  /// on the reading-start page; the dates, the place, the participants and
  /// price, the description and the registration button on the other.
  /// Nothing sits in the fold, and the map stays whole on its page.
  Widget _buildBook(
    BuildContext context,
    FoldCut cut,
    Event event,
    Color typeColor,
    IconData typeIcon,
  ) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final map = _map(event);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ColumnAppBar(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: _backButton(),
          actions: [_shareButton()],
        ),
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
                  height: 340,
                  child: _header(event, typeColor, typeIcon),
                ),
                if (map != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: EventReveal(group: 1, child: map),
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
                      EventReveal(group: 0, child: _infoGrid(event)),
                      const SizedBox(height: 20),
                      EventReveal(
                        group: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _aboutAndStatus(event),
                        ),
                      ),
                    ],
                  ),
                ),
                EventReveal(
                  group: 3,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
                    child: _rsvpButton(event),
                  ),
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
    final map = _map(event);
    final collapsed = kToolbarHeight + MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) => _header(
                event,
                typeColor,
                typeIcon,
                titleFade: ((constraints.maxHeight - collapsed) / 120).clamp(
                  0.0,
                  1.0,
                ),
              ),
            ),
            leading: BarNavigation(
              buttons: [_backButton(), _shareButton()],
              inline: _backButton(),
            ),
            actions: VerticalBarScope.geometryOf(context) == null
                ? [_shareButton()]
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EventReveal(group: 0, child: _infoGrid(event)),
                  if (map != null) ...[
                    const SizedBox(height: 20),
                    EventReveal(group: 1, child: map),
                  ],
                  const SizedBox(height: 24),
                  EventReveal(
                    group: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _aboutAndStatus(event),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: EventReveal(
        group: 3,
        child: Container(
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
      ),
    );
  }
}
