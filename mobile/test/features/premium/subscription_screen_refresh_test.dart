import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/store/subscription_service.dart';
import 'package:mazl/core/theme/app_theme.dart';
import 'package:mazl/l10n/generated/app_localizations.dart';
import 'package:mazl/presentation/features/premium/screens/subscription_screen.dart';

import '../../support/store_fakes.dart';

/// Opening « Abonnement » while something above it listens to the service
/// must not change that service during the build.
void main() {
  testWidgets('opening the screen does not notify listeners while building', (
    tester,
  ) async {
    final service = SubscriptionService.create(
      gateway: FakeStoreGateway(),
      api: FakeSubscriptionApi(),
      platform: TargetPlatform.iOS,
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListenableBuilder(
          listenable: service,
          builder: (context, _) => SubscriptionScreen(service: service),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
