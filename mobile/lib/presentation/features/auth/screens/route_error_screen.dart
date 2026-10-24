import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../l10n/l10n.dart';

/// Shown by the router when the address does not exist. The router's own
/// error text is a diagnostic in English: it is never displayed.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.authRouteErrorTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.authRouteErrorBody),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.discover),
              child: Text(l10n.authRouteErrorHome),
            ),
          ],
        ),
      ),
    );
  }
}
