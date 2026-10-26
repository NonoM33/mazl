import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/di/providers/service_providers.dart';
import 'core/l10n/app_language_controller.dart';
import 'core/l10n/locale_resolution.dart';
import 'core/motion/reduce_motion_scope.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/websocket_service.dart';
import 'presentation/features/couple/widgets/couple_flow_host.dart';
import 'core/layout/fold_channel.dart';
import 'core/layout/fold_state.dart';
import 'core/layout/orientation_policy.dart';
import 'core/layout/side_safe_area.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/dismiss_keyboard_on_tap.dart';
import 'core/widgets/quiet_backdrop.dart';
import 'presentation/features/settings/widgets/shabbat_display_proposal_host.dart';
import 'l10n/l10n.dart';

/// One subscription to the fold of the device for the life of the app.
final Stream<FoldState> _foldStates = platformFoldStates();

class MazlApp extends ConsumerWidget {
  const MazlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final couple = ref.watch(coupleServiceProvider.notifier);
    final auth = ref.watch(authServiceProvider.notifier);
    final socket = WebSocketService();
    final language = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'MAZL',
      debugShowCheckedModeBanner: false,

      // Language: the one chosen in the settings, else the phone's, else
      // English. Hebrew turns the whole app right-to-left.
      locale: language?.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: (deviceLocales, _) =>
          resolveAppLocale(deviceLocales),

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router
      routerConfig: router,

      // iOS « Réduire les animations » only reaches Flutter as
      // AccessibilityFeatures.reduceMotion: fold it into disableAnimations
      // for every screen, sheet and overlay. A tap outside a text field
      // closes the keyboard, everywhere. On the foldable iPhone, nothing is
      // drawn under the side column of the status bar, and every screen can
      // read the fold.
      builder: (context, child) {
        // DateFormat and NumberFormat without an explicit locale follow the
        // interface language.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return FoldStateHost(
          states: _foldStates,
          child: OrientationPolicy(
            child: QuietBackdrop(
              child: SideSafeArea(
                child: ReduceMotionScope(
                  child: DismissKeyboardOnTap(
                    child: CoupleFlowHost(
                      service: couple,
                      router: router,
                      navigatorKey: rootNavigatorKey,
                      realtime: socket.events,
                      auth: auth,
                      isAuthenticated: () => auth.isAuthenticated,
                      onSignedIn: socket.connect,
                      onSignedOut: socket.disconnect,
                      child: ShabbatDisplayProposalHost(
                        onLaunch: () =>
                            unawaited(router.push(RoutePaths.shabbatDisplay)),
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
