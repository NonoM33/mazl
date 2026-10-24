import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/di/providers/service_providers.dart';
import 'core/l10n/app_language_controller.dart';
import 'core/l10n/locale_resolution.dart';
import 'core/motion/reduce_motion_scope.dart';
import 'core/router/app_router.dart';
import 'core/services/websocket_service.dart';
import 'presentation/features/couple/widgets/couple_flow_host.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';

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
      // for every screen, sheet and overlay.
      builder: (context, child) {
        // DateFormat and NumberFormat without an explicit locale follow the
        // interface language.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return ReduceMotionScope(
          child: CoupleFlowHost(
            service: couple,
            router: router,
            navigatorKey: rootNavigatorKey,
            realtime: socket.events,
            auth: auth,
            isAuthenticated: () => auth.isAuthenticated,
            onSignedIn: socket.connect,
            onSignedOut: socket.disconnect,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
