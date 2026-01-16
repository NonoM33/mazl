import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

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
      debugPrint('RevenueCat: Initialization error - $e');
      rethrow;
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

  /// Purchase a package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      _customerInfo = result;
      debugPrint('RevenueCat: Purchase successful');
      return result;
    } catch (e) {
      if (e is PurchasesErrorCode) {
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('RevenueCat: Purchase cancelled by user');
        }
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
    if (!isMazlPro) return 'Free';

    final entitlement =
        _customerInfo?.entitlements.active[RevenueCatConfig.entitlementMazlPro];
    if (entitlement == null) return 'Free';

    if (entitlement.willRenew) {
      return 'Mazl Pro (Active)';
    } else {
      return 'Mazl Pro (Expires soon)';
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
}
