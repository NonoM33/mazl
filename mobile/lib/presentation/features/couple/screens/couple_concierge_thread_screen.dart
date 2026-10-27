import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/layout/fold_cut.dart';
import '../widgets/concierge_controller.dart';
import '../widgets/concierge_conversation.dart';

/// The conversation of one request on its own page (`/couple/concierge/:id`):
/// the page the list opens when there is no room for a second page, and where
/// a push notification of the team's reply lands.
class ConciergeThreadScreen extends StatefulWidget {
  const ConciergeThreadScreen({
    super.key,
    required this.requestId,
    this.api,
    this.couple,
  });

  final int requestId;

  /// Injected by tests; the app uses the real services.
  final CoupleDailyApi? api;
  final CoupleService? couple;

  @override
  State<ConciergeThreadScreen> createState() => _ConciergeThreadScreenState();
}

class _ConciergeThreadScreenState extends State<ConciergeThreadScreen>
    with WidgetsBindingObserver {
  final GlobalKey _conversationKey = GlobalKey(
    debugLabel: 'concierge-thread-conversation',
  );
  late final ConciergeController _controller = ConciergeController(
    api: widget.api ?? CoupleDailyApi.forApp(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.onFailure = (failure) =>
        reportConciergeFailure(context, failure);
    _controller.start();
    _controller.open(widget.requestId);
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
    _controller.dispose();
    super.dispose();
  }

  void _leave(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null && !router.canPop()) {
      router.go(RoutePaths.coupleConcierge);
      return;
    }
    Navigator.of(context).maybePop();
  }

  /// One page, or the request on one page and its conversation on the other
  /// when the fold (or the width) gives two: nothing sits on the fold.
  Widget _page(BuildContext context, FoldCut? cut, String partnerName) {
    final conversation = KeyedSubtree(
      key: _conversationKey,
      child: ConciergeConversation(
        controller: _controller,
        partnerName: partnerName,
        topPadding: 8,
        header: ConciergeHeader.details,
        part: cut == null ? ConciergePart.all : ConciergePart.messages,
      ),
    );
    if (cut == null) return conversation;
    final request = ConciergeConversation(
      controller: _controller,
      partnerName: partnerName,
      topPadding: 8,
      header: ConciergeHeader.details,
      part: ConciergePart.request,
    );
    return switch (cut.axis) {
      FoldSplitAxis.vertical => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: cut.leadExtent, child: request),
          SizedBox(width: cut.gap),
          Expanded(child: conversation),
        ],
      ),
      FoldSplitAxis.horizontal => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: cut.leadExtent, child: request),
          SizedBox(height: cut.gap),
          Expanded(child: conversation),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final couple = widget.couple ?? CoupleService();
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, couple]),
      builder: (context, _) => Scaffold(
        appBar: ColumnAppBar(
          appBar: AppBar(
            leading: BackButton(onPressed: () => _leave(context)),
            title: Text(
              _controller.thread?.request.title ??
                  context.l10n.coupleConciergeThreadEyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        body: FoldCutBuilder(
          minPaneExtent: 240,
          builder: (context, cut) => _page(
            context,
            cut,
            couple.coupleData?.partnerName ??
                context.l10n.coupleConciergePartnerFallback,
          ),
        ),
      ),
    );
  }
}
