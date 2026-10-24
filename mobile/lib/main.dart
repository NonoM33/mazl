import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/dev/demo_http_client.dart';
import 'core/dev/dev_login.dart';
import 'core/l10n/app_language_controller.dart';
import 'core/di/providers/identity_providers.dart';
import 'core/di/providers/verification_providers.dart';
import 'presentation/features/verification/providers/verification_providers.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/revenuecat_service.dart';

void main() {
  if (kDevLoginAvailable) {
    // Debug uniquement (constante de compilation, élaguée en release) : les
    // requêtes passent par un client qui ne répond depuis des données
    // fictives que pendant une session de connexion fictive. Tout le démarrage
    // vit dans la même zone, sinon les callbacks du moteur n'y seraient pas.
    unawaited(http.runWithClient(_start, () => DemoHttpClient(http.Client())));
  } else {
    unawaited(_start());
  }
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Date names for every interface language; MazlApp then points
  // Intl.defaultLocale at the language in use.
  await initializeDateFormatting();
  final savedLanguage = await loadSavedLanguage(
    SharedPreferencesLanguageStore(),
  );

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
        savedLanguageProvider.overrideWithValue(savedLanguage),
        // The identity flow (level 2) reuses the level-1 API client and selfie capture.
        identityVerificationApiProvider.overrideWith(
          (ref) => ref.watch(verificationApiProvider),
        ),
        identityLivenessCaptureProvider.overrideWith(
          (ref) => ref.watch(livenessCaptureProvider),
        ),
      ],
      child: const MazlApp(),
    ),
  );
}
