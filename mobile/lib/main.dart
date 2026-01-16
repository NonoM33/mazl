import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // TODO: Initialize Hive for local storage
  // await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: MazlApp(),
    ),
  );
}
