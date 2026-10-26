import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_safe_actions.dart';
import '../../../../core/models/couple_event.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/couple_failure_label.dart';
import '../l10n/couple_feed_labels.dart';
import '../widgets/book_pages.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/event_category.dart';
import '../../../common/widgets/fold_pages.dart';

class CoupleEventDetailScreen extends StatefulWidget {
  const CoupleEventDetailScreen({
    super.key,
    required this.eventId,
    this.apiService,
  });

  final String eventId;

  /// Injected by tests; the app uses the real service.
  final CoupleApiService? apiService;

  @override
  State<CoupleEventDetailScreen> createState() =>
      _CoupleEventDetailScreenState();
}

class _CoupleEventDetailScreenState extends State<CoupleEventDetailScreen> {
  late final CoupleApiService _apiService =
      widget.apiService ?? CoupleApiService();

  CoupleEvent? _event;
  bool _isRegistered = false;
  bool _isLoading = true;
  bool _isUpdatingRegistration = false;
  CoupleFailure? _failure;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final id = int.tryParse(widget.eventId);
    if (id == null) {
      setState(() {
        _isLoading = false;
        _failure = const CoupleFailure(
          CoupleFailureKind.notFound,
          'invalidEventId',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final results = await Future.wait([
      _apiService.getEvent(id),
      _apiService.getRegisteredEvents(),
    ]);
    if (!mounted) return;

    final event = results[0] as CoupleResult<CoupleEvent>;
    final registered = results[1] as CoupleResult<List<CoupleEvent>>;
    setState(() {
      _isLoading = false;
      switch ((event, registered)) {
        case (CoupleFailed(:final failure), _):
        case (_, CoupleFailed(:final failure)):
          _failure = failure;
        case (CoupleOk(value: final e), CoupleOk(value: final list)):
          _event = e;
          _isRegistered = list.any((r) => r.id == e.id);
      }
    });
  }

  Future<void> _toggleRegistration() async {
    final event = _event;
    if (event == null || _isUpdatingRegistration) return;

    final wasRegistered = _isRegistered;
    setState(() => _isUpdatingRegistration = true);

    final result = wasRegistered
        ? await _apiService.cancelEventRegistration(event.id)
        : await _apiService.registerForEvent(event.id);
    if (!mounted) return;

    switch (result) {
      case CoupleFailed(:final failure):
        setState(() => _isUpdatingRegistration = false);
        showCoupleError(
          context,
          failure.kind == CoupleFailureKind.full
              ? failure.label(context.l10n)
              : wasRegistered
              ? context.l10n.coupleFeedEventCancelError
              : context.l10n.coupleFeedEventRegisterError,
        );
      case CoupleOk():
        setState(() {
          _isUpdatingRegistration = false;
          _isRegistered = !wasRegistered;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasRegistered
                  ? context.l10n.coupleFeedEventCancelled
                  : context.l10n.coupleFeedEventRegisteredSnackDetail(
                      event.title,
                    ),
            ),
            backgroundColor: wasRegistered ? null : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshEvent(event.id);
    }
  }

  /// Seats left changed: re-read the event; a failure keeps what is shown.
  Future<void> _refreshEvent(int id) async {
    final result = await _apiService.getEvent(id);
    if (!mounted) return;
    if (result case CoupleOk(:final value)) setState(() => _event = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Stack(
          children: [
            FoldSpinner(),
            _BackButton(),
          ],
        ),
      );
    }

    final failure = _failure;
    final event = _event;
    if (failure != null || event == null) {
      return Scaffold(
        body: Stack(
          children: [
            failure == null || failure.kind == CoupleFailureKind.notFound
                ? CoupleMessageView(
                    icon: LucideIcons.calendarX,
                    title: context.l10n.coupleFeedEventNotFoundTitle,
                    line: context.l10n.coupleFeedEventNotFoundLine,
                  )
                : coupleFailureView(context, failure, onRetry: _loadEvent),
            const _BackButton(),
          ],
        ),
      );
    }

    return FoldCutBuilder(
      minPaneExtent: bookPaneExtent,
      builder: (context, cut) => cut?.axis == FoldSplitAxis.vertical
          ? Scaffold(body: _buildBook(event, cut!))
          : Scaffold(
              body: _buildContent(event),
              bottomNavigationBar: _buildRegistrationBar(event),
            ),
    );
  }

  /// Held like a book: the photo, the title and the price to look at on the
  /// first page; the practical details and the registration on the other.
  Widget _buildBook(CoupleEvent event, FoldCut cut) {
    return bookPages(
      cut,
      lead: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(event),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: _buildHeadline(event),
            ),
          ],
        ),
      ),
      action: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.paddingOf(context).top + 24,
                24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDetails(event),
              ),
            ),
          ),
          _buildRegistrationBar(event),
        ],
      ),
    );
  }

  Widget _buildRegistrationBar(CoupleEvent event) {
    final l10n = context.l10n;
    final label = _isRegistered
        ? l10n.coupleFeedEventCancelMine
        : event.isFull
        ? l10n.coupleFeedEventFull
        : l10n.coupleFeedEventRegister;
    final canTap = !_isUpdatingRegistration && (_isRegistered || !event.isFull);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return FoldSafeActions(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 12),
        child: SizedBox(
          width: double.infinity,
          child: _isRegistered
              ? OutlinedButton(
                  onPressed: canTap ? _toggleRegistration : null,
                  child: Text(label),
                )
              : ElevatedButton(
                  onPressed: canTap ? _toggleRegistration : null,
                  child: Text(label),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(CoupleEvent event) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(event),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeadline(event),
                const SizedBox(height: 24),
                ..._buildDetails(event),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// When, title, tags and price: what the member looks at first.
  Widget _buildHeadline(CoupleEvent event) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(event.whenLabel(l10n)),
        const SizedBox(height: 10),
        Text(
          event.title,
          style: textTheme.headlineMedium?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TagPill(
              eventCategoryLabel(l10n, event.category),
              icon: eventCategoryIcon(event.category),
            ),
            if (event.isKosher) TagPill(l10n.coupleFeedKosher),
            if (event.isFeatured)
              TagPill(l10n.coupleFeedFeatured, icon: LucideIcons.star),
          ],
        ),
        const SizedBox(height: 24),
        _buildPriceCard(event),
      ],
    );
  }

  /// Place, dress code, description: the practical side.
  List<Widget> _buildDetails(CoupleEvent event) {
    final l10n = context.l10n;
    return [
      ..._buildFacts(event),
      _buildSection(l10n.coupleFeedDescription, event.description),
      if (event.whatIncluded != null) ...[
        const SizedBox(height: 24),
        _buildSection(l10n.coupleFeedEventIncluded, event.whatIncluded!),
      ],
    ];
  }

  List<Widget> _buildFacts(CoupleEvent event) {
    final l10n = context.l10n;
    final place = event.location ?? event.city;
    final facts = <(String, String)>[
      if (place != null) (l10n.coupleFeedEventFactPlace, place),
      if (event.address != null) (l10n.coupleFeedAddress, event.address!),
      if (event.dressCode != null)
        (l10n.coupleFeedEventFactDressCode, event.dressCode!),
      if (event.organizerName != null)
        (l10n.coupleFeedEventFactOrganizer, event.organizerName!),
    ];
    return [
      for (var i = 0; i < facts.length; i++)
        FactRow(
          label: facts[i].$1,
          value: facts[i].$2,
          last: i == facts.length - 1,
        ),
      if (facts.isNotEmpty) const SizedBox(height: 24),
    ];
  }

  Widget _buildHero(CoupleEvent event) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 280 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: event.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _placeholder(event),
                    errorWidget: (_, _, _) => _placeholder(event),
                  )
                : _placeholder(event),
          ),
          const _BackButton(),
        ],
      ),
    );
  }

  Widget _placeholder(CoupleEvent event) => EventImagePlaceholder(
    category: event.category,
    seed: event.id,
    iconSize: 64,
  );

  Widget _buildPriceCard(CoupleEvent event) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final full = event.isFull;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.ticket, size: 22, color: scheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              event.priceLabel(l10n),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ),
          if (event.maxCouples != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                full
                    ? l10n.coupleFeedEventFull
                    : l10n.coupleFeedEventSpotsLeft(event.spotsLeft),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  color: full ? Theme.of(context).colorScheme.error : scheme.onSurfaceVariant,
                  fontWeight: full ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: 10),
        Text(
          body,
          style: TextStyle(fontSize: 16, height: 1.5, color: scheme.onSurface),
        ),
      ],
    );
  }
}

/// Retour posé sur la photo, calé sur le bord de départ.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return PositionedDirectional(
      top: top + 8,
      start: 24,
      child: RoundIconButton(
        icon: backArrowIcon(context),
        tooltip: context.l10n.commonBack,
        onPressed: () => context.pop(),
      ),
    );
  }
}
