import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'subscription_format.dart';

/// Outcome of a purchase attempt.
///
/// A user-initiated cancellation is a normal, expected outcome and is
/// surfaced as [PurchaseStatus.cancelled] rather than thrown as an error,
/// so callers never present it as a failure.
enum PurchaseStatus { success, cancelled }

/// Result of [RevenueCatService.purchasePackage].
///
/// On [PurchaseStatus.success], [customerInfo] holds the updated entitlements.
/// On [PurchaseStatus.cancelled], [customerInfo] is the last known info (may be
/// null if none was ever fetched).
class PurchaseResult {
  const PurchaseResult(this.status, this.customerInfo);

  final PurchaseStatus status;
  final CustomerInfo? customerInfo;

  bool get isCancelled => status == PurchaseStatus.cancelled;
  bool get isSuccess => status == PurchaseStatus.success;
}

/// RevenueCat API Configuration
class RevenueCatConfig {
  // API Keys
  static const String appleApiKey = 'test_EHjYnTRZZKABEGBLfettogPCNoR';
  static const String googleApiKey = 'test_EHjYnTRZZKABEGBLfettogPCNoR';

  // Entitlements
  static const String entitlementMazlPro = 'Mazl Pro';

  // Product Identifiers
  static const String productMonthly = 'monthly';
  static const String productYearly = 'yearly';
  static const String productTwoMonth = 'two_month';
  static const String productSixMonth = 'six_month';
  static const String productConsumable = 'consumable';

  static List<String> get allProducts => [
        productMonthly,
        productYearly,
        productTwoMonth,
        productSixMonth,
        productConsumable,
      ];
}

/// RevenueCat Service for handling subscriptions and in-app purchases
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// Initialize RevenueCat SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure debug logs in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Get platform-specific API key
      final apiKey = Platform.isIOS
          ? RevenueCatConfig.appleApiKey
          : RevenueCatConfig.googleApiKey;

      // Configure RevenueCat
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        debugPrint('RevenueCat: Customer info updated');
      });

      _isInitialized = true;
      debugPrint('RevenueCat: Initialized successfully');
    } catch (e) {
      // Never let RevenueCat init failures block app startup: an invalid key
      // or an unavailable store must not crash the app before runApp(). The
      // user simply stays non-premium until initialization can succeed.
      debugPrint('RevenueCat: Initialization error (continuing non-premium) - $e');
    }
  }

  /// Login user to RevenueCat (call after authentication)
  Future<void> login(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      _customerInfo = result.customerInfo;
      debugPrint('RevenueCat: User logged in - $userId');
    } catch (e) {
      debugPrint('RevenueCat: Login error - $e');
      rethrow;
    }
  }

  /// Logout user from RevenueCat
  Future<void> logout() async {
    try {
      _customerInfo = await Purchases.logOut();
      debugPrint('RevenueCat: User logged out');
    } catch (e) {
      debugPrint('RevenueCat: Logout error - $e');
      rethrow;
    }
  }

  /// Check if user has Mazl Pro entitlement
  bool get isMazlPro {
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.active
        .containsKey(RevenueCatConfig.entitlementMazlPro);
  }

  /// Get customer info
  CustomerInfo? get customerInfo => _customerInfo;

  /// Refresh customer info
  Future<CustomerInfo> refreshCustomerInfo() async {
    _customerInfo = await Purchases.getCustomerInfo();
    return _customerInfo!;
  }

  /// Get available offerings
  Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  /// Get current offering
  Future<Offering?> getCurrentOffering() async {
    final offerings = await getOfferings();
    return offerings.current;
  }

  /// Purchase a package.
  ///
  /// Returns a [PurchaseResult] describing the outcome. A user-initiated
  /// cancellation is NOT an error: it is reported as
  /// [PurchaseStatus.cancelled] so callers can abandon silently. Any other
  /// failure is rethrown for the caller to handle.
  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final purchase = await Purchases.purchase(PurchaseParams.package(package));
      _customerInfo = purchase.customerInfo;
      debugPrint('RevenueCat: Purchase successful');
      return PurchaseResult(PurchaseStatus.success, purchase.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCat: Purchase cancelled by user');
        return PurchaseResult(PurchaseStatus.cancelled, _customerInfo);
      }
      rethrow;
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();
      debugPrint('RevenueCat: Purchases restored');
      return _customerInfo!;
    } catch (e) {
      debugPrint('RevenueCat: Restore error - $e');
      rethrow;
    }
  }

  /// Show RevenueCat Paywall
  Future<PaywallResult> showPaywall({
    Offering? offering,
    bool displayCloseButton = true,
  }) async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        RevenueCatConfig.entitlementMazlPro,
        offering: offering,
        displayCloseButton: displayCloseButton,
      );

      // Refresh customer info after paywall closes
      await refreshCustomerInfo();

      return result;
    } catch (e) {
      debugPrint('RevenueCat: Paywall error - $e');
      rethrow;
    }
  }

  /// Present paywall (always show, regardless of entitlement)
  Future<PaywallResult> presentPaywall({
    Offering? offering,
    bool displayCloseButton = true,
  }) async {
    try {
      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: displayCloseButton,
      );

      // Refresh customer info after paywall closes
      await refreshCustomerInfo();

      return result;
    } catch (e) {
      debugPrint('RevenueCat: Paywall error - $e');
      rethrow;
    }
  }

  /// Show Customer Center
  Future<void> showCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('RevenueCat: Customer Center error - $e');
      rethrow;
    }
  }

  /// Get subscription status string for UI
  String get subscriptionStatusText {
    if (!isMazlPro) return 'Gratuit';

    final entitlement =
        _customerInfo?.entitlements.active[RevenueCatConfig.entitlementMazlPro];
    if (entitlement == null) return 'Gratuit';

    if (entitlement.willRenew) {
      return 'mazl+ (actif)';
    } else {
      return 'mazl+ (expire bientôt)';
    }
  }

  /// Get expiration date for Mazl Pro
  DateTime? get mazlProExpirationDate {
    final entitlement =
        _customerInfo?.entitlements.active[RevenueCatConfig.entitlementMazlPro];
    if (entitlement?.expirationDate == null) return null;
    return DateTime.tryParse(entitlement!.expirationDate!);
  }

  /// Check if user is in trial period
  bool get isInTrialPeriod {
    final entitlement =
        _customerInfo?.entitlements.active[RevenueCatConfig.entitlementMazlPro];
    return entitlement?.periodType == PeriodType.trial;
  }

  EntitlementInfo? get _activeEntitlement =>
      _customerInfo?.entitlements.active[RevenueCatConfig.entitlementMazlPro];

  /// Durée de la formule active (« 6 mois »), ou null si inconnue.
  String? get activePlanLabel {
    final entitlement = _activeEntitlement;
    if (entitlement == null) return null;
    return planLabelForProduct(entitlement.productIdentifier);
  }

  /// Prix de la formule active tel qu'affiché par le store, retrouvé dans
  /// l'offre courante. Null si l'offre est indisponible.
  Future<String?> activePlanPrice() async {
    final entitlement = _activeEntitlement;
    if (entitlement == null) return null;
    try {
      final offering = await getCurrentOffering();
      for (final package in offering?.availablePackages ?? const <Package>[]) {
        final productId = package.storeProduct.identifier;
        if (productId == entitlement.productIdentifier ||
            productId.split(':').first ==
                entitlement.productIdentifier.split(':').first) {
          return package.storeProduct.priceString;
        }
      }
    } catch (e) {
      debugPrint('RevenueCat: active plan price unavailable - $e');
    }
    return null;
  }

  /// Faux quand l'abonnement a été résilié et s'arrêtera à l'échéance.
  bool get willRenew => _activeEntitlement?.willRenew ?? false;

  /// Page de gestion de l'abonnement dans le store, si RevenueCat la connaît.
  String? get managementUrl => _customerInfo?.managementURL;
}
