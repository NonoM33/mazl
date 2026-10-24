import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'consumable_purchases.dart';
import 'credits_service.dart';
import 'purchase_errors.dart';
import 'store_gateway.dart';
import 'store_products.dart';
import 'subscription_api.dart';
import 'subscription_models.dart';

const String _verifyPath = '/api/subscriptions/apple/verify';
const String _subscriptionPath = '/api/subscription';

/// Abonnement mazl+ acheté nativement (StoreKit 2 via `in_app_purchase`).
///
/// Le store vend, le BACKEND décide : un achat n'ouvre le droit qu'après
/// `POST /api/subscriptions/apple/verify`, et le statut premium est toujours
/// celui de `GET /api/subscription` (actif ET échéance dans le futur).
///
/// Singleton comme [AuthService] ; [SubscriptionService.create] sert aux tests
/// (faux store, fausse API, horloge fixe).
class SubscriptionService extends ChangeNotifier {
  factory SubscriptionService() => _shared;

  SubscriptionService.create({
    StoreGateway? gateway,
    SubscriptionApi? api,
    TargetPlatform? platform,
    DateTime Function()? now,
    Duration restoreSettle = const Duration(seconds: 3),
    Duration purchaseSettleTimeout = const Duration(seconds: 45),
    Future<bool> Function(Uri uri)? openUrl,
    ConsumablePurchaseHandler? consumables,
  }) : _gateway = gateway,
       _api = api,
       _platform = platform,
       _now = now ?? DateTime.now,
       _restoreSettle = restoreSettle,
       _purchaseSettleTimeout = purchaseSettleTimeout,
       _openUrl = openUrl ?? _launchExternally,
       _consumables = consumables;

  static final SubscriptionService _shared = _buildShared();

  /// Le singleton de production : le flux d'achats est unique, et c'est lui
  /// qui démarre l'écoute pour le [CreditsService] (qui ne l'écoute jamais).
  static SubscriptionService _buildShared() {
    final credits = CreditsService();
    final service = SubscriptionService.create(consumables: credits);
    credits.attachPurchaseStream(service.initialize);
    return service;
  }

  StoreGateway? _gateway;
  SubscriptionApi? _api;
  final TargetPlatform? _platform;
  final DateTime Function() _now;
  final Duration _restoreSettle;
  final Duration _purchaseSettleTimeout;
  final Future<bool> Function(Uri uri) _openUrl;

  /// Qui tient les consommables (Boosts, Super Likes). Le flux d'achats est
  /// unique : ce service reçoit tout et leur confie ce qui n'est pas un
  /// abonnement.
  final ConsumablePurchaseHandler? _consumables;

  StoreGateway get _store => _gateway ??= InAppPurchaseGateway();
  SubscriptionApi get _backend =>
      _api ??= HttpSubscriptionApi(tokenProvider: () => _token);

  String? _token;
  MazlSubscription? _subscription;
  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdates;
  _PendingPurchase? _pendingPurchase;
  List<_VerifyOutcome>? _restoreOutcomes;
  bool _disposed = false;

  /// Vérifications en cours, par transaction : une transaction livrée deux
  /// fois n'est envoyée qu'une fois au serveur.
  final Map<String, Future<_VerifyOutcome>> _inFlight = {};

  /// Traitements d'achats du flux encore en cours (la restauration les attend).
  final Set<Future<void>> _handlers = {};

  /// Transactions qu'on n'a pas pu vérifier faute de session ou de réseau :
  /// rejouées à la connexion suivante.
  final Map<String, PurchaseDetails> _deferred = {};

  TargetPlatform get _targetPlatform => _platform ?? defaultTargetPlatform;

  // ---------------------------------------------------------------- lecture

  /// Premium = statut « active » ET échéance dans le futur (heure du téléphone).
  bool get isMazlPro => _subscription?.isActiveAt(_now()) ?? false;

  /// Durée de la formule active, en mois, ou null si inconnue. L'écran écrit
  /// la durée dans la langue du membre.
  int? get activePlanMonths {
    final sub = _subscription;
    if (sub == null || !isMazlPro) return null;
    return monthsFromProductId(sub.productId);
  }

  /// Échéance de la formule active.
  DateTime? get expirationDate => isMazlPro ? _subscription?.expiresAt : null;

  /// StoreKit natif n'expose pas l'intention de renouvellement : le backend ne
  /// rapporte « active » que tant que l'abonnement court, donc on le tient
  /// pour renouvelé jusqu'à l'échéance.
  bool get willRenew => isMazlPro;

  /// Seul iOS achète : le serveur ne vérifie pas encore Google Play, et on
  /// n'ouvre jamais un droit sur un achat non vérifié.
  bool get canPurchase => canSellOn(_targetPlatform);

  /// Pourquoi l'achat est impossible ici, ou null s'il est possible.
  PurchaseProblem? get unavailablePurchaseProblem =>
      canPurchase ? null : PurchaseProblem.androidSoon;

  // --------------------------------------------------------------- cycle de vie

  /// Écoute le flux d'achats. À appeler dès le lancement : les transactions non
  /// terminées de la session précédente sont rejouées à ce moment-là.
  Future<void> initialize() async {
    if (_purchaseUpdates != null || !canPurchase || _disposed) return;
    try {
      _purchaseUpdates = _store.purchaseStream.listen(
        _onPurchases,
        onError: (Object error) =>
            debugPrint('Subscription: flux d’achats en erreur - $error'),
      );
    } on Exception catch (error) {
      debugPrint('Subscription: flux d’achats indisponible - $error');
    }
  }

  /// À appeler dès qu'une session est ouverte (connexion ou session restaurée).
  /// Ne lève jamais.
  Future<void> onSignedIn(String? jwtToken) async {
    _token = jwtToken;
    if (jwtToken == null) {
      _setSubscription(null);
      return;
    }
    await refresh();
    final retry = List<PurchaseDetails>.of(_deferred.values);
    _deferred.clear();
    await Future.wait(retry.map(_verifyOnce));
  }

  /// À appeler à la déconnexion : plus de session, plus de droit.
  void onSignedOut() {
    _token = null;
    _deferred.clear();
    _setSubscription(null);
  }

  /// Relit le statut auprès du backend (source de vérité). Ne lève jamais ;
  /// en cas de panne réseau, le dernier état connu est conservé.
  Future<void> refresh() async {
    if (_token == null) {
      _setSubscription(null);
      return;
    }
    try {
      final reply = await _backend.get(_subscriptionPath);
      if (reply.statusCode == 401 || reply.statusCode == 403) {
        _setSubscription(null);
        return;
      }
      final body = reply.body;
      if (!reply.isOk || body == null) {
        debugPrint('Subscription: statut illisible (HTTP ${reply.statusCode})');
        return;
      }
      _setSubscription(MazlSubscription.fromEnvelope(body));
    } on FormatException catch (error) {
      debugPrint('Subscription: réponse inattendue - ${error.message}');
    } on Exception catch (error) {
      debugPrint('Subscription: statut non rafraîchi - $error');
    }
  }

  // ----------------------------------------------------------------- formules

  /// Les formules vendues, de la plus courte à la plus longue. Vide si le store
  /// est indisponible ou ne connaît aucun de nos produits.
  Future<List<SubscriptionPlan>> loadPlans() async {
    try {
      if (!await _store.isAvailable()) return const [];
      final response = await _store.queryProductDetails(
        kSubscriptionProductIds.toSet(),
      );
      final error = response.error;
      if (error != null) {
        debugPrint('Subscription: produits en erreur - ${error.message}');
      }
      final plans = <SubscriptionPlan>[
        for (final product in response.productDetails)
          if (monthsFromProductId(product.id) case final months?)
            SubscriptionPlan.fromProduct(product, months),
      ]..sort((a, b) => a.months.compareTo(b.months));
      return plans;
    } on Exception catch (error) {
      debugPrint('Subscription: produits indisponibles - $error');
      return const [];
    }
  }

  /// Prix de la formule active tel que le store l'affiche, ou null.
  Future<String?> activePlanPrice() async {
    final sub = _subscription;
    if (sub == null || !isMazlPro) return null;
    for (final plan in await loadPlans()) {
      if (plan.productId == sub.productId) return plan.priceLabel;
    }
    return null;
  }

  // -------------------------------------------------------------------- achat

  /// Achète [plan]. Ne lève jamais : l'annulation, l'attente d'approbation et
  /// l'échec sont des issues, pas des exceptions.
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    final unavailable = unavailablePurchaseProblem;
    if (unavailable != null) return PurchaseFailed(unavailable);
    if (_pendingPurchase != null) {
      return const PurchaseFailed(PurchaseProblem.purchaseInProgress);
    }
    final pending = _PendingPurchase(plan.productId);
    _pendingPurchase = pending;
    try {
      await initialize();
      final started = await _store.buyNonConsumable(
        PurchaseParam(productDetails: plan.product),
      );
      if (!started) return const PurchaseFailed(PurchaseProblem.generic);
      return await pending.result.future.timeout(
        _purchaseSettleTimeout,
        onTimeout: () => const PurchasePending(),
      );
    } on Exception catch (error) {
      if (isUserCancellation(error)) return const PurchaseCancelled();
      debugPrint('Subscription: purchase failed - $error');
      return const PurchaseFailed(PurchaseProblem.generic);
    } finally {
      if (identical(_pendingPurchase, pending)) _pendingPurchase = null;
    }
  }

  /// Restaure les achats de l'identifiant Apple, puis relit le statut serveur.
  Future<RestoreResult> restore() async {
    if (!canPurchase) {
      await refresh();
      return isMazlPro ? const RestoreFound() : const RestoreNothing();
    }
    final outcomes = <_VerifyOutcome>[];
    _restoreOutcomes = outcomes;
    try {
      await initialize();
      await _store.restorePurchases();
      // Les achats restaurés arrivent sur le flux, pas en retour d'appel : on
      // laisse une courte fenêtre puis on attend les vérifications en cours.
      await Future<void>.delayed(_restoreSettle);
      await Future.wait(List<Future<void>>.of(_handlers));
    } on Exception catch (error) {
      debugPrint('Subscription: restauration en erreur - $error');
      return const RestoreFailed(PurchaseProblem.restoreFailed);
    } finally {
      _restoreOutcomes = null;
    }
    if (!outcomes.any((o) => o.granted)) await refresh();
    if (isMazlPro) return const RestoreFound();
    final refusal = outcomes.where((o) => o.problem != null).firstOrNull;
    if (refusal != null) return RestoreFailed(refusal.problem!);
    return const RestoreNothing();
  }

  /// Ouvre la gestion de l'abonnement dans le store. Faux si impossible.
  Future<bool> manageSubscriptions() async {
    final uri = Uri.parse(
      _targetPlatform == TargetPlatform.android
          ? 'https://play.google.com/store/account/subscriptions'
          : 'https://apps.apple.com/account/subscriptions',
    );
    try {
      return await _openUrl(uri);
    } on Exception catch (error) {
      debugPrint('Subscription: gestion non ouverte - $error');
      return false;
    }
  }

  // ----------------------------------------------------------- flux d'achats

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final handler = _handle(purchase);
      _handlers.add(handler);
      unawaited(
        handler.whenComplete(() {
          _handlers.remove(handler);
        }),
      );
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    if (isConsumableProductId(purchase.productID)) {
      await _handleConsumable(purchase);
      return;
    }
    switch (purchase.status) {
      case PurchaseStatus.pending:
        _resolvePending(purchase.productID, const PurchasePending());
      case PurchaseStatus.canceled:
        _resolvePending(purchase.productID, const PurchaseCancelled());
      case PurchaseStatus.error:
        _resolvePending(
          purchase.productID,
          isUserCancellation(purchase.error)
              ? const PurchaseCancelled()
              : const PurchaseFailed(PurchaseProblem.generic),
        );
        // Une transaction en erreur n'a rien livré : la terminer est sans risque
        // et évite qu'elle bloque un nouvel achat.
        await _complete(purchase);
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final outcome = await _verifyOnce(purchase);
        _restoreOutcomes?.add(outcome);
        _resolvePending(purchase.productID, outcome.asPurchaseResult());
    }
  }

  /// Un consommable n'est ni un abonnement ni une restauration : il va, tel
  /// quel, à celui qui tient les crédits. Sans lui, on le laisse NON terminé :
  /// le store le rejouera, rien n'est perdu.
  Future<void> _handleConsumable(PurchaseDetails purchase) async {
    final consumables = _consumables;
    if (consumables == null) {
      debugPrint('Subscription: no owner for ${purchase.productID}');
      return;
    }
    await consumables.handlePurchase(purchase);
  }

  void _resolvePending(String productId, PurchaseResult result) {
    final pending = _pendingPurchase;
    if (pending == null || pending.productId != productId) return;
    if (!pending.result.isCompleted) pending.result.complete(result);
  }

  // ------------------------------------------------------------ vérification

  Future<_VerifyOutcome> _verifyOnce(PurchaseDetails purchase) {
    final key =
        purchase.purchaseID ??
        '${purchase.productID}:${purchase.transactionDate}';
    final running = _inFlight[key];
    if (running != null) return running;
    // Bloc et non flèche : `remove` rend le Future lui-même, et `whenComplete`
    // attendrait un Future qui s'attend lui-même.
    final started = _verify(purchase, key).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = started;
    return started;
  }

  /// Envoie le JWS signé au backend ; ne lève jamais.
  ///
  /// QUAND TERMINER LA TRANSACTION (`completePurchase`). Apple veut que chaque
  /// transaction soit terminée un jour ; tant qu'elle ne l'est pas, StoreKit la
  /// rejoue à chaque lancement et bloque un nouvel achat du même produit.
  /// Règle retenue :
  ///  - 200 : droit accordé -> on termine, APRÈS la réponse du serveur ;
  ///  - 409 (achat déjà lié à un autre compte mazl) : refus DÉFINITIF, qui ne
  ///    changera jamais pour ce compte -> on termine, sinon l'erreur reviendrait
  ///    à chaque lancement. Rien n'est perdu : « Restaurer » depuis le bon
  ///    compte mazl rejoue la transaction ;
  ///  - 400 / 422 / 401 / réseau / 5xx : refus ou panne POTENTIELLEMENT
  ///    corrigeable (bug d'envoi, mauvais environnement sandbox/production du
  ///    serveur, session expirée, coupure) -> on NE termine PAS : la transaction
  ///    sera rejouée et l'utilisateur ne perd pas un achat payé. Seules 401 et
  ///    les pannes sont aussi gardées en mémoire pour être rejouées dès la
  ///    prochaine connexion.
  Future<_VerifyOutcome> _verify(PurchaseDetails purchase, String key) async {
    final signed = purchase.verificationData.serverVerificationData;
    try {
      final reply = await _backend.post(_verifyPath, {
        'signedTransaction': signed,
      });
      switch (reply.statusCode) {
        case 200:
          return await _grant(purchase, reply);
        case 409:
          await _complete(purchase);
          return const _VerifyOutcome.refused(
            PurchaseProblem.ownedByAnotherAccount,
          );
        case 400:
          return const _VerifyOutcome.refused(PurchaseProblem.invalidBody);
        case 422:
          return const _VerifyOutcome.refused(
            PurchaseProblem.invalidTransaction,
          );
        case 401:
        case 403:
          _deferred[key] = purchase;
          return const _VerifyOutcome.refused(PurchaseProblem.signInAgain);
        default:
          _deferred[key] = purchase;
          return const _VerifyOutcome.refused(PurchaseProblem.offline);
      }
    } on Exception catch (error) {
      debugPrint('Subscription: verification impossible - $error');
      _deferred[key] = purchase;
      return const _VerifyOutcome.refused(PurchaseProblem.offline);
    }
  }

  Future<_VerifyOutcome> _grant(
    PurchaseDetails purchase,
    ApiReply reply,
  ) async {
    final body = reply.body;
    try {
      final subscription = body == null || body['success'] != true
          ? null
          : MazlSubscription.fromEnvelope(body);
      if (subscription == null) {
        debugPrint('Subscription: verification reply without subscription');
        return const _VerifyOutcome.refused(PurchaseProblem.invalidTransaction);
      }
      _setSubscription(subscription);
    } on FormatException catch (error) {
      debugPrint('Subscription: unreadable verification reply - ${error.message}');
      return const _VerifyOutcome.refused(PurchaseProblem.invalidTransaction);
    }
    await _complete(purchase);
    return isMazlPro
        ? const _VerifyOutcome.granted()
        : const _VerifyOutcome.refused(PurchaseProblem.inactive);
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (purchase.purchaseID == null) return;
    try {
      await _store.completePurchase(purchase);
    } on Exception catch (error) {
      // Le droit est déjà accordé : la transaction sera simplement rejouée.
      debugPrint('Subscription: transaction non terminée - $error');
    }
  }

  // ------------------------------------------------------------------ interne

  void _setSubscription(MazlSubscription? subscription) {
    _subscription = subscription;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_purchaseUpdates?.cancel());
    _purchaseUpdates = null;
    super.dispose();
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _PendingPurchase {
  _PendingPurchase(this.productId);

  final String productId;
  final Completer<PurchaseResult> result = Completer<PurchaseResult>();
}

class _VerifyOutcome {
  const _VerifyOutcome.granted() : granted = true, problem = null;

  const _VerifyOutcome.refused(PurchaseProblem this.problem) : granted = false;

  final bool granted;
  final PurchaseProblem? problem;

  PurchaseResult asPurchaseResult() =>
      granted ? const PurchaseSucceeded() : PurchaseFailed(problem!);
}
