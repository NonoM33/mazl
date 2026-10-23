import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/dev/demo_http_client.dart';
import 'core/dev/dev_login.dart';
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
    const ProviderScope(
      child: MazlApp(),
    ),
  );
}
