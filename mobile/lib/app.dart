import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers/service_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/websocket_service.dart';
import 'presentation/features/couple/widgets/couple_flow_host.dart';
import 'core/theme/app_theme.dart';

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
      builder: (context, child) => CoupleFlowHost(
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
  }
}
