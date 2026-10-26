import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/screen_view_tracker.dart';
import '../../../../core/di/providers/analytics_providers.dart';
import '../../../../core/di/providers/privacy_providers.dart';
import '../../../../core/di/providers/service_providers.dart';
import '../../../../core/privacy/analytics_consent.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/quiet_display.dart';
import 'analytics_consent_sheet.dart';

/// Keeps the usage measurement alive above the router, for the life of the
/// app: records `app_opened`, follows the screens, flushes when the app goes
/// to the background, gives the measurement the consent read from the server
/// once the member is signed in, and asks the question ONCE per session when
/// it was never answered (or answered for an older text).
class AnalyticsHost extends ConsumerStatefulWidget {
  const AnalyticsHost({
    super.key,
    required this.router,
    required this.navigatorKey,
    required this.child,
    this.quiet,
  });

  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;

  /// While it is on (the Shabbat display), the question waits. The app's own
  /// by default.
  final QuietDisplay? quiet;
  final Widget child;

  @override
  ConsumerState<AnalyticsHost> createState() => _AnalyticsHostState();
}

class _AnalyticsHostState extends ConsumerState<AnalyticsHost>
    with WidgetsBindingObserver {
  static const _retryEvery = Duration(seconds: 1);
  static const _maxRetries = 30;

  late final Analytics _analytics;
  late final ScreenViewTracker _screens;
  ProviderSubscription<bool>? _authSubscription;
  ProviderSubscription<AsyncValue<ApiResponse<AnalyticsConsent>>>?
  _consentSubscription;
  Timer? _retry;
  bool _asking = false;
  bool _askedThisSession = false;

  QuietDisplay get _quiet => widget.quiet ?? QuietDisplay.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _analytics = ref.read(analyticsProvider)..track(AnalyticsEvent.appOpened());
    _screens = ScreenViewTracker(router: widget.router, analytics: _analytics)
      ..start();
    _authSubscription = ref.listenManual<bool>(
      isAuthenticatedProvider,
      (_, signedIn) => _onAuthentication(signedIn),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    _authSubscription?.close();
    _consentSubscription?.close();
    _screens.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(_analytics.onBackground());
    }
  }

  void _onAuthentication(bool signedIn) {
    if (signedIn) {
      _consentSubscription ??= ref.listenManual(
        analyticsConsentProvider,
        (_, state) => _onConsent(state),
        fireImmediately: true,
      );
      return;
    }
    _consentSubscription?.close();
    _consentSubscription = null;
    _retry?.cancel();
    _askedThisSession = false;
    _asking = false;
  }

  void _onConsent(AsyncValue<ApiResponse<AnalyticsConsent>> state) {
    final consent = state.valueOrNull?.data;
    if (consent == null) return;
    _analytics.consentLoaded(
      granted: consent.isValid
          ? true
          : consent.granted == false
          ? false
          : null,
    );
    final answered = consent.isValid || consent.granted == false;
    if (!answered && !_askedThisSession) _ask(consent, 0);
  }

  void _ask(AnalyticsConsent consent, int attempt) {
    _retry?.cancel();
    if (_asking || _askedThisSession) return;
    final context = widget.navigatorKey.currentContext;
    final route = widget.router.routerDelegate.currentConfiguration.isEmpty
        ? null
        : widget.router.routerDelegate.currentConfiguration.last.route;
    final onSplash = route is GoRoute && route.name == RouteNames.splash;
    if (context == null || onSplash || _quiet.isOn) {
      if (attempt < _maxRetries || _quiet.isOn) {
        _retry = Timer(_retryEvery, () => _ask(consent, attempt + 1));
      }
      return;
    }
    _asking = true;
    unawaited(
      showAnalyticsConsentSheet(context, consent).whenComplete(() {
        _asking = false;
        _askedThisSession = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
