import 'dart:async';

import 'credits_service.dart';
import 'subscription_service.dart';

/// Les services du store qui suivent la session : l'abonnement et le solde de
/// crédits. Un seul endroit les prévient de la connexion et de la déconnexion,
/// pour qu'aucun des deux ne soit oublié.
class StoreSession {
  StoreSession({SubscriptionService? subscriptions, CreditsService? credits})
    : _subscriptions = subscriptions,
      _credits = credits {
    _subscriptionService.addListener(_onSubscriptionChanged);
  }

  final SubscriptionService? _subscriptions;
  final CreditsService? _credits;

  // Résolus à l'appel : un test peut remplacer le singleton après coup.
  SubscriptionService get _subscriptionService =>
      _subscriptions ?? SubscriptionService();
  CreditsService get _creditsService => _credits ?? CreditsService();

  bool _wasSubscriber = false;

  /// Vrai pendant la connexion et la déconnexion : elles relisent déjà le
  /// solde elles-mêmes.
  bool _changingSession = false;

  /// L'inclus du jour dépend de l'abonnement (5 Super Likes et 1 Boost pour
  /// mazl+) : quand le statut change, seul le serveur sait le nouveau solde.
  void _onSubscriptionChanged() {
    if (_changingSession) return;
    final subscriber = _subscriptionService.isMazlPro;
    if (subscriber == _wasSubscriber) return;
    _wasSubscriber = subscriber;
    unawaited(_creditsService.refresh());
  }

  /// À appeler dès qu'une session est ouverte (connexion ou session
  /// restaurée) : relit l'abonnement et le solde, et rejoue les achats que la
  /// session précédente n'avait pas pu faire vérifier. Ne lève jamais.
  Future<void> onSignedIn(String? jwtToken) async {
    _changingSession = true;
    try {
      await Future.wait([
        _subscriptionService.onSignedIn(jwtToken),
        _creditsService.onSignedIn(jwtToken),
      ]);
    } finally {
      _changingSession = false;
      _wasSubscriber = _subscriptionService.isMazlPro;
    }
  }

  /// Session fictive (mode démo, debug seulement) : pas de JWT et pas
  /// d'abonnement, mais un solde de crédits fictif. Le jeton ci-dessous ne
  /// part nulle part : tant que la session dure, `DemoHttpClient` répond
  /// lui-même et ne transmet jamais rien au réseau.
  Future<void> onDemoSignedIn() => _creditsService.onSignedIn(_demoToken);

  static const String _demoToken = 'demo-session';

  /// À la déconnexion : plus de session, plus de droit, plus de solde.
  void onSignedOut() {
    _changingSession = true;
    try {
      _subscriptionService.onSignedOut();
      _creditsService.onSignedOut();
    } finally {
      _changingSession = false;
      _wasSubscriber = false;
    }
  }
}
