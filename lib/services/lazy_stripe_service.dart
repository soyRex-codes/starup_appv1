import 'package:flutter/foundation.dart';
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
      // Try dotenv first (from .env.mobile asset)
      final dotenvKey = dotenv.dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
      // Then try compile-time constant (from --dart-define)
      const compileTimeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
      
      final stripePublishableKey = dotenvKey ?? 
          (compileTimeKey.isNotEmpty ? compileTimeKey : null);

      if (stripePublishableKey == null || stripePublishableKey.isEmpty) {
        if (kDebugMode) debugPrint('Stripe publishable key not found');
        return false;
      }

      Stripe.publishableKey = stripePublishableKey;
      await Stripe.instance.applySettings();

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Stripe initialization failed: $e');
      return false;
    }
  }

  /// Check if Stripe is already initialized
  static bool get isInitialized => _isInitialized;
}
