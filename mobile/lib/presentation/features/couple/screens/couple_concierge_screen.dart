import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/concierge_composer.dart';
import '../widgets/concierge_controller.dart';
import '../widgets/concierge_conversation.dart';
import '../widgets/concierge_paywall.dart';
import '../widgets/concierge_quick_asks.dart';
import '../widgets/concierge_request_card.dart';
import '../widgets/couple_kit.dart';
import '../widgets/couple_message_view.dart';
import '../l10n/couple_failure_label.dart';

/// The concierge tab. Without MAZL Couple: the way to the subscription. With
/// it: the title, the quick asks and the requests on one page, and the
/// conversation of the request open on the other (book pose and wide window);
/// on a single column the conversation opens as its own page.
class CoupleConciergeScreen extends StatefulWidget {
  const CoupleConciergeScreen({super.key, this.api, this.couple});

  /// Injected by tests; the app uses the real services.
  final CoupleDailyApi? api;
  final CoupleService? couple;

  @override
  State<CoupleConciergeScreen> createState() => _CoupleConciergeScreenState();
}

class _CoupleConciergeScreenState extends State<CoupleConciergeScreen>
    with WidgetsBindingObserver {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleService _couple = widget.couple ?? CoupleService();

  /// The conversation of the page at the right (book pose, wide window): the
  /// request open there, its ticked idea, its draft.
  late final ConciergeController _controller = ConciergeController(api: _api);

  /// The field of a single column: it only ever starts a new request.
  late final ConciergeController _fresh = ConciergeController(api: _api);

  // The two pages keep their state when the device folds: same element,
  // reparented with a global key.
  final GlobalKey _listKey = GlobalKey(debugLabel: 'concierge-list');
  final GlobalKey _conversationKey = GlobalKey(
    debugLabel: 'concierge-conversation',
  );

  List<ConciergeSummary> _requests = const [];
  bool _loading = true;
  CoupleFailure? _failure;
  bool _subscribed = false;

  /// The layout shows the conversation next to the list (book pose, laptop
  /// pose, wide window); a single column opens it as a page.
  bool _twoPages = false;
  bool _autoSelected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _couple.addListener(_coupleChanged);
    _controller
      ..onFailure = _onFailure
      ..onChanged = _reload
      ..start();
    _fresh
      ..onFailure = _onFailure
      ..onCreated = _onCreated
      ..onChanged = _reload;
    _subscribed = _couple.premium.active;
    if (_subscribed) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller
        ..start()
        ..refreshQuietly();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _couple.removeListener(_coupleChanged);
    _controller.dispose();
    _fresh.dispose();
    super.dispose();
  }

  void _coupleChanged() {
    if (!mounted) return;
    final active = _couple.premium.active;
    if (active == _subscribed) return;
    setState(() => _subscribed = active);
    if (active) _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!_subscribed) return;
    if (!quiet) {
      setState(() {
        _loading = true;
        _failure = null;
      });
    }
    final result = await _api.getConcierge();
    if (!mounted) return;
    switch (result) {
      case CoupleOk(:final value):
        setState(() {
          _requests = value;
          _loading = false;
          _failure = null;
        });
        _selectFirstOpen();
      case CoupleFailed(:final failure):
        if (failure.kind == CoupleFailureKind.subscriptionRequired) {
          setState(() {
            _subscribed = false;
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
            if (!quiet) _failure = failure;
          });
        }
    }
  }

  /// With two pages, the first open request is shown on the second, once.
  void _selectFirstOpen() {
    if (!_twoPages || _autoSelected || _controller.requestId != null) return;
    _autoSelected = true;
    for (final request in _requests) {
      if (request.isOpen) {
        _controller.open(request.id);
        return;
      }
    }
  }

  void _onFailure(CoupleFailure failure) {
    if (!mounted) return;
    if (failure.kind == CoupleFailureKind.subscriptionRequired) {
      setState(() => _subscribed = false);
      return;
    }
    showCoupleError(context, failure.label(context.l10n));
  }

  void _reload() {
    if (mounted) _load(quiet: true);
  }

  void _onCreated(int id) {
    if (!mounted) return;
    // A single column: the new request opens as its own page and the field
    // here is ready for the next one.
    _fresh.open(null);
    _openPage(id);
  }

  Future<void> _openPage(int id) async {
    await context.push(RoutePaths.conciergeRequestPath(id));
    if (mounted) _load(quiet: true);
  }

  void _open(ConciergeSummary request) {
    if (_twoPages) {
      _controller.open(request.id);
    } else {
      _openPage(request.id);
    }
  }

  void _ask(ConciergeKind kind, String start) {
    if (!_twoPages) {
      _fresh.prepare(kind, start);
      return;
    }
    // A quick ask always starts a new request, even beside an open one.
    _controller.open(null);
    _controller.prepare(kind, start);
  }

  Future<void> _discover() async {
    await context.push(RoutePaths.couplePremium);
    if (!mounted) return;
    await _couple.refresh();
    if (!mounted) return;
    if (_couple.premium.active && !_subscribed) {
      setState(() => _subscribed = true);
      await _load();
    }
  }

  /// Tells the layout once per frame whether the conversation has its own
  /// page. Nothing is dropped when it flips: both controllers keep their state.
  void _layoutIs({required bool twoPages}) {
    if (twoPages == _twoPages) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _twoPages == twoPages) return;
      setState(() => _twoPages = twoPages);
      if (twoPages) _selectFirstOpen();
    });
  }

  String get _partnerName =>
      _couple.coupleData?.partnerName ??
      context.l10n.coupleConciergePartnerFallback;

  @override
  Widget build(BuildContext context) {
    if (!_subscribed) {
      return Scaffold(body: ConciergePaywall(onDiscover: _discover));
    }
    if (_loading && _requests.isEmpty) {
      return const Scaffold(body: FoldSpinner());
    }
    final failure = _failure;
    if (failure != null && _requests.isEmpty) {
      return Scaffold(body: CoupleMessageView.failure(failure, onRetry: _load));
    }
    return Scaffold(
      body: FoldCutBuilder(
        minPaneExtent: 240,
        builder: (context, cut) {
          _layoutIs(twoPages: cut != null);
          return _layout(context, cut);
        },
      ),
    );
  }

  Widget _layout(BuildContext context, FoldCut? cut) {
    final safe = MediaQuery.paddingOf(context);
    final list = KeyedSubtree(key: _listKey, child: _list(context));
    if (cut == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: list),
          ConciergeComposer(controller: _fresh),
        ],
      );
    }
    final conversation = KeyedSubtree(
      key: _conversationKey,
      child: ConciergeConversation(
        controller: _controller,
        partnerName: _partnerName,
        topPadding: cut.axis == FoldSplitAxis.vertical ? safe.top + 16 : 12,
      ),
    );
    return switch (cut.axis) {
      FoldSplitAxis.vertical => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: cut.leadExtent, child: list),
          SizedBox(width: cut.gap),
          Expanded(child: conversation),
        ],
      ),
      FoldSplitAxis.horizontal => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: cut.leadExtent, child: list),
          SizedBox(height: cut.gap),
          Expanded(child: conversation),
        ],
      ),
    };
  }

  /// The page of the title, the quick asks and the requests.
  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final safe = MediaQuery.paddingOf(context);
    final open = [
      for (final request in _requests)
        if (request.isOpen) request,
    ];
    final closed = [
      for (final request in _requests)
        if (!request.isOpen) request,
    ];
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          safe.top + 16,
          24,
          _twoPages ? safe.bottom + 24 : 16,
        ),
        children: [
          CoupleHeader(
            eyebrow: l10n.coupleConciergeEyebrow,
            title: l10n.coupleConciergeTitle,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.coupleConciergeIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ConciergeQuickAsks(onAsk: _ask),
          const SizedBox(height: 32),
          SectionLabel(l10n.coupleConciergeInProgress),
          const SizedBox(height: 12),
          if (open.isEmpty)
            Text(
              l10n.coupleConciergeNoRequests,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final request in open) ...[
            ConciergeRequestCard(
              key: ValueKey('concierge-request-${request.id}'),
              request: request,
              selected: _twoPages && _controller.requestId == request.id,
              onTap: () => _open(request),
            ),
            const SizedBox(height: 12),
          ],
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionLabel(l10n.coupleConciergeClosedSection),
            const SizedBox(height: 12),
            for (final request in closed) ...[
              ConciergeRequestCard(
                key: ValueKey('concierge-request-${request.id}'),
                request: request,
                selected: _twoPages && _controller.requestId == request.id,
                onTap: () => _open(request),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}
