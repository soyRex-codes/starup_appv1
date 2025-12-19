import 'dart:developer';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

/// Lazy Stripe initialization service.
/// Stripe is only initialized when needed (on first payment attempt),
/// not at app startup. This reduces cold start time significantly.
class LazyStripeService {
  static bool _isInitialized = false;

  /// Ensure Stripe is initialized. Call this before any Stripe operations.
  /// Safe to call multiple times - will only initialize once.
  static Future<bool> ensureInitialized() async {
    if (_isInitialized) return true;

    try {
      final stripePublishableKey =
          dotenv.dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY') ??
              const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

      if (stripePublishableKey.isEmpty) {
        log('⚠️ Stripe publishable key not found');
        return false;
      }

      Stripe.publishableKey = stripePublishableKey;
      await Stripe.instance.applySettings();

      _isInitialized = true;
      log('✅ Stripe initialized (lazy, on-demand)');
      return true;
    } catch (e) {
      log('❌ Stripe initialization failed: $e');
      return false;
    }
  }

  /// Check if Stripe is already initialized
  static bool get isInitialized => _isInitialized;
}
