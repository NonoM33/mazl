import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/revenuecat_service.dart';

/// RevenueCat Service Provider
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
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
  final revenueCat = ref.watch(revenueCatServiceProvider);
  return revenueCat.isMazlPro;
});

/// Subscription Status Provider
final subscriptionStatusProvider = Provider<String>((ref) {
  final revenueCat = ref.watch(revenueCatServiceProvider);
  return revenueCat.subscriptionStatusText;
});
