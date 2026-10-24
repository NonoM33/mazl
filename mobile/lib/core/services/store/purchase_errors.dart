import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Vrai quand l'erreur est la fermeture volontaire de la fenêtre de paiement
/// (StoreKit 1 : SKErrorPaymentCancelled ; StoreKit 2 : userCancelled).
bool isUserCancellation(Object? error) {
  final text = switch (error) {
    PlatformException(:final code, :final message) => '$code $message',
    IAPError(:final code, :final message) => '$code $message',
    _ => '',
  };
  return text.toLowerCase().contains('cancel');
}
