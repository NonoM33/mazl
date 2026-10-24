import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/store/subscription_service.dart';

/// Subscription Service Provider
///
/// [SubscriptionService] est un singleton [ChangeNotifier] : les providers qui
/// en dépendent se recalculent à chaque changement du statut d'abonnement
/// (achat, restauration, rafraîchissement, déconnexion).
final subscriptionServiceProvider = ChangeNotifierProvider<SubscriptionService>(
  (ref) => SubscriptionService(),
);

/// Auth Service Provider
///
/// [AuthService] is an application-wide singleton that extends [ChangeNotifier].
/// Exposing it through a [ChangeNotifierProvider] makes every dependent provider
/// (and the router's [refreshListenable]) recompute whenever the authentication
/// state changes (login / logout / init / user refresh).
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

/// Current User Provider
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

/// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

/// Is Mazl Pro Provider
final isMazlProProvider = Provider<bool>((ref) {
  final subscriptions = ref.watch(subscriptionServiceProvider);
  return subscriptions.isMazlPro;
});

/// Couple Service Provider
///
/// [CoupleService] is an application-wide singleton that extends [ChangeNotifier].
/// Exposing it through a [ChangeNotifierProvider] makes every dependent provider
/// recompute whenever the couple state changes (activation / deactivation /
/// data sync / couple request updates).
final coupleServiceProvider = ChangeNotifierProvider<CoupleService>((ref) {
  return CoupleService();
});

/// Is Couple Mode Enabled Provider
final isCoupleModeEnabledProvider = Provider<bool>((ref) {
  final coupleService = ref.watch(coupleServiceProvider);
  return coupleService.isCoupleModeEnabled;
});

/// Couple Data Provider
final coupleDataProvider = Provider<CoupleData?>((ref) {
  final coupleService = ref.watch(coupleServiceProvider);
  return coupleService.coupleData;
});

/// Received Couple Request Provider
final receivedCoupleRequestProvider = Provider<CoupleRequest?>((ref) {
  final coupleService = ref.watch(coupleServiceProvider);
  return coupleService.receivedRequest;
});
