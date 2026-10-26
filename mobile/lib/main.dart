import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/layout/fold_state.dart';
import 'core/layout/orientation_policy.dart';
import 'core/dev/demo_http_client.dart';
import 'core/dev/dev_login.dart';
import 'core/l10n/app_language.dart';
import 'core/l10n/app_language_controller.dart';
import 'core/observability/crash_reporting.dart';
import 'core/observability/error_handlers.dart';
import 'core/observability/quiet_debug_print.dart';
import 'core/observability/startup_guard.dart';
import 'core/di/providers/identity_providers.dart';
import 'core/di/providers/verification_providers.dart';
import 'presentation/features/verification/providers/verification_providers.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/store/subscription_service.dart';

void main() {
  // Avant tout autre appel : hors debug, la console du téléphone ne reçoit
  // plus rien de ce que l'app écrit avec debugPrint.
  silenceDebugPrintOutsideDebug();
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

  // Les filets d'erreurs d'abord, Sentry ensuite : il s'y chaîne.
  const journal = DeveloperLogJournal();
  installGlobalErrorHandlers(journal: journal);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Chaque étape est protégée : si l'une échoue (réseau, StoreKit, push),
  // l'app s'ouvre quand même au lieu de rester sur un écran blanc.
  AppLanguage? savedLanguage;
  await runStartupSteps(
    [
      // Sans DSN fourni au build (--dart-define=SENTRY_DSN=...), rien n'est
      // initialisé : aucun envoi, aucun appel réseau.
      StartupStep(
        'plantages',
        () => startCrashReporting(const CrashReportingConfig.fromEnvironment()),
      ),
      // Date names for every interface language; MazlApp then points
      // Intl.defaultLocale at the language in use.
      StartupStep('dates', initializeDateFormatting),
      StartupStep('langue', () async {
        savedLanguage = await loadSavedLanguage(
          SharedPreferencesLanguageStore(),
        );
      }),
      // Upright until the hinge is known; OrientationPolicy then lets the
      // foldable iPhone turn sideways (tent pose).
      StartupStep(
        'orientation',
        () => SystemChrome.setPreferredOrientations(
          orientationsFor(FoldState.unknown),
        ),
      ),
      // Écoute les achats natifs dès le lancement : StoreKit rejoue ici les
      // transactions non terminées de la session précédente.
      StartupStep('achats', () => SubscriptionService().initialize()),
      StartupStep('auth', () => AuthService().initialize()),
      // Notifications push (APNs)
      StartupStep('push', () => PushNotificationService().initialize()),
    ],
    journal: journal,
    report: (error, stack) => Sentry.captureException(error, stackTrace: stack),
  );

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
