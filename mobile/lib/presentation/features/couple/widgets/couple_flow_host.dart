import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/websocket_service.dart';
import 'couple_request_dialog.dart';

/// Keeps the couple flow alive above the router: loads the state once signed
/// in, re-aligns it when the app comes back, relays the `couple:*` real-time
/// messages, shows the request dialog and sends the member where the flow says
/// (celebration, messages). Screens never poll or listen on their own.
class CoupleFlowHost extends StatefulWidget {
  const CoupleFlowHost({
    super.key,
    required this.service,
    required this.router,
    required this.navigatorKey,
    required this.realtime,
    required this.auth,
    required this.isAuthenticated,
    this.onSignedIn,
    this.onSignedOut,
    required this.child,
  });

  final CoupleService service;
  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Real-time messages of the app (the WebSocket in production).
  final Stream<ChatEvent> realtime;

  /// Notifies sign-in / sign-out; [isAuthenticated] reads the current state.
  final Listenable auth;
  final bool Function() isAuthenticated;

  /// Side effects tied to the session (connect / disconnect the socket).
  final VoidCallback? onSignedIn;
  final VoidCallback? onSignedOut;
  final Widget child;

  @override
  State<CoupleFlowHost> createState() => _CoupleFlowHostState();
}

class _CoupleFlowHostState extends State<CoupleFlowHost> with WidgetsBindingObserver {
  StreamSubscription<CoupleFlowEvent>? _flowSubscription;
  StreamSubscription<ChatEvent>? _realtimeSubscription;
  bool _wasAuthenticated = false;
  int? _dialogRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flowSubscription = widget.service.events.listen(_onFlowEvent);
    _realtimeSubscription = widget.realtime.listen(_onRealtime);
    widget.auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.auth.removeListener(_onAuthChanged);
    _flowSubscription?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    final signedIn = widget.isAuthenticated();
    if (signedIn == _wasAuthenticated) return;
    _wasAuthenticated = signedIn;
    if (signedIn) {
      widget.onSignedIn?.call();
      unawaited(widget.service.initialize());
    } else {
      widget.onSignedOut?.call();
      unawaited(widget.service.reset());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_wasAuthenticated) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.service.onResumed());
    } else if (state == AppLifecycleState.paused) {
      widget.service.onPaused();
    }
  }

  void _onRealtime(ChatEvent event) {
    if (event is CoupleRealtimeEvent && _wasAuthenticated) {
      unawaited(widget.service.handleRealtime(event.type, event.payload));
    }
  }

  void _onFlowEvent(CoupleFlowEvent event) {
    switch (event) {
      case CoupleRequestReceived(:final request):
        _showRequestDialog(request);
      case CoupleFormed(:final couple):
        widget.router.go(
          RoutePaths.mazelTov,
          extra: {
            'partnerName': couple.partnerName ?? '',
            'partnerPicture': couple.partnerPicture,
          },
        );
      case CoupleRequestDeclined(:final partnerName):
        _snack(partnerName == null
            ? 'Votre demande n\'a pas abouti.'
            : '$partnerName n\'a pas donné suite à votre demande.');
      case CoupleEnded():
        _snack('Le mode couple a pris fin.');
    }
  }

  void _snack(String message) {
    final context = widget.navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRequestDialog(CoupleRequest request) {
    if (_dialogRequestId == request.id) return;
    final context = widget.navigatorKey.currentContext;
    if (context == null) {
      // The navigator is not mounted yet (cold start): try after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.service.receivedRequest?.id == request.id) {
          _showRequestDialog(request);
        }
      });
      return;
    }
    _dialogRequestId = request.id;
    unawaited(
      CoupleRequestDialog.show(context, request: request, service: widget.service)
          .whenComplete(() => _dialogRequestId = null),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
