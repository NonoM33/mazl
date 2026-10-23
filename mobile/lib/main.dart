import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/di/providers/identity_providers.dart';
import 'core/di/providers/verification_providers.dart';
import 'presentation/features/verification/providers/verification_providers.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize RevenueCat SDK
  await RevenueCatService().initialize();

  // Initialize Auth Service
  await AuthService().initialize();

  // Initialize Push Notifications (OneSignal)
  await PushNotificationService().initialize();

  runApp(
    ProviderScope(
      overrides: [
        // The identity flow (level 2) reuses the level-1 API client and selfie capture.
        identityVerificationApiProvider.overrideWith((ref) => ref.watch(verificationApiProvider)),
        identityLivenessCaptureProvider.overrideWith((ref) => ref.watch(livenessCaptureProvider)),
      ],
      child: const MazlApp(),
    ),
  );
}
