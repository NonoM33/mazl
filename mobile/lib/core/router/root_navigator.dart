import 'package:flutter/widgets.dart';

/// The app's root navigator. It lives apart from the router so that services
/// (push notifications) can reach the navigator without importing every screen.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
