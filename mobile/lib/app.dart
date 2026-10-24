import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers/service_providers.dart';
import 'core/motion/reduce_motion_scope.dart';
import 'core/router/app_router.dart';
import 'core/services/websocket_service.dart';
import 'presentation/features/couple/widgets/couple_flow_host.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/dismiss_keyboard_on_tap.dart';

class MazlApp extends ConsumerWidget {
  const MazlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final couple = ref.watch(coupleServiceProvider.notifier);
    final auth = ref.watch(authServiceProvider.notifier);
    final socket = WebSocketService();

    return MaterialApp.router(
      title: 'MAZL',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router
      routerConfig: router,

      // iOS « Réduire les animations » only reaches Flutter as
      // AccessibilityFeatures.reduceMotion: fold it into disableAnimations
      // for every screen, sheet and overlay. A tap outside a text field
      // closes the keyboard, everywhere.
      builder: (context, child) => ReduceMotionScope(
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
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
