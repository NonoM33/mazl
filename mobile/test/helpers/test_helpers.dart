import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mazl/core/theme/app_colors.dart';

/// Creates a testable widget wrapped with necessary providers and theme
Widget createTestableWidget(
  Widget child, {
  List<Override>? overrides,
  GoRouter? router,
}) {
  final testRouter = router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => child,
          ),
          // Stub routes for navigation
          GoRoute(
            path: '/profile',
            builder: (context, state) => const _StubScreen(title: 'Profile'),
          ),
          GoRoute(
            path: '/couple/activities',
            builder: (context, state) => const _StubScreen(title: 'Activities'),
          ),
          GoRoute(
            path: '/couple/events',
            builder: (context, state) => const _StubScreen(title: 'Events'),
          ),
          GoRoute(
            path: '/couple/space',
            builder: (context, state) => const _StubScreen(title: 'Space'),
          ),
          GoRoute(
            path: '/couple/saved',
            builder: (context, state) => const _StubScreen(title: 'Saved'),
          ),
          GoRoute(
            path: '/success-stories',
            builder: (context, state) => const _StubScreen(title: 'Success Stories'),
          ),
        ],
      );

  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp.router(
      routerConfig: testRouter,
      theme: _testTheme,
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Creates a simple testable widget without GoRouter
Widget createSimpleTestableWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: child,
      theme: _testTheme,
      debugShowCheckedModeBanner: false,
    ),
  );
}

/// Test theme that mimics the app's theme
final ThemeData _testTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
);

/// Stub screen for navigation testing
class _StubScreen extends StatelessWidget {
  final String title;

  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen')),
    );
  }
}

/// Helper to pump widget and wait for animations
extension WidgetTesterExtensions on WidgetTester {
  /// Pumps the widget and waits for all animations to complete
  Future<void> pumpAndWait({Duration? duration}) async {
    await pump(duration ?? const Duration(milliseconds: 100));
    await pumpAndSettle();
  }

  /// Pumps multiple frames to simulate time passing
  Future<void> pumpFrames(int count, {Duration? interval}) async {
    for (var i = 0; i < count; i++) {
      await pump(interval ?? const Duration(milliseconds: 16));
    }
  }
}

/// Mock network image for tests - avoids network calls
class MockNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const MockNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey),
      ),
    );
  }
}
