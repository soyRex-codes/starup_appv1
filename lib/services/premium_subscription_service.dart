import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/models/premium_payment_model.dart';
import 'package:foundervers/services/lazy_stripe_service.dart';

/// Service for managing premium subscriptions
/// Handles checking premium status, activation, and Stripe integration
class PremiumSubscriptionService {
  static final PremiumSubscriptionService _instance =
      PremiumSubscriptionService._internal();
  factory PremiumSubscriptionService() => _instance;
  PremiumSubscriptionService._internal();

  final _supabase = Supabase.instance.client;

  // Pricing (in USD)
  static const double monthlyPrice = 19.99;
  static const double annualPrice = 167.99;

  // Stripe price IDs (you'll need to create these in Stripe Dashboard)
  static const String monthlyPriceId =
      'price_monthly_premium'; // Replace with actual Stripe price ID
  static const String annualPriceId =
      'price_annual_premium'; // Replace with actual Stripe price ID

  /// Check if current user has active premium subscription
  /// Also automatically deactivates expired subscriptions
  Future<bool> checkPremiumStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('users')
          .select('is_premium, premium_expires_at')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;

      final isPremium = response['is_premium'] as bool? ?? false;
      if (!isPremium) return false;

      final expiresAt = response['premium_expires_at'] as String?;
      if (expiresAt == null) return true; // Lifetime premium

      final expiryDate = DateTime.parse(expiresAt);
      final isActive = expiryDate.isAfter(DateTime.now());

      // Auto-deactivate expired subscription
      if (!isActive && isPremium) {
        await _deactivateExpiredPremium(userId);
        return false;
      }

      return isActive;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Deactivate expired premium subscription
  Future<void> _deactivateExpiredPremium(String userId) async {
    try {
      debugPrint('⏰ Deactivating expired premium for user: $userId');

      await _supabase.from('users').update({
        'is_premium': false,
      }).eq('id', userId);

      debugPrint('✅ Expired premium deactivated');
    } catch (e) {
      debugPrint('❌ Failed to deactivate expired premium: $e');
    }
  }

  /// Get premium status with expiry date
  Future<PremiumStatus> getPremiumStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return PremiumStatus(isActive: false);
      }

      final response = await _supabase
          .from('users')
          .select('is_premium, premium_expires_at, premium_subscription_type')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return PremiumStatus(isActive: false);
      }

      final isPremium = response['is_premium'] as bool? ?? false;
      if (!isPremium) {
        return PremiumStatus(isActive: false);
      }

      final expiresAtStr = response['premium_expires_at'] as String?;
      final subscriptionType = response['premium_subscription_type'] as String?;

      if (expiresAtStr == null) {
        return PremiumStatus(
          isActive: true,
          isLifetime: true,
          subscriptionType: subscriptionType,
        );
      }

      final expiryDate = DateTime.parse(expiresAtStr);
      final isActive = expiryDate.isAfter(DateTime.now());

      return PremiumStatus(
        isActive: isActive,
        expiresAt: expiryDate,
        subscriptionType: subscriptionType,
      );
    } catch (e) {
      debugPrint('Error getting premium status: $e');
      return PremiumStatus(isActive: false);
    }
  }

  /// Activate premium subscription (called after successful payment)
  Future<bool> activatePremium({
    required bool isAnnual,
    String? transactionId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final expiresAt = DateTime.now().add(
        Duration(days: isAnnual ? 365 : 30),
      );

      await _supabase.from('users').update({
        'is_premium': true,
        'premium_expires_at': expiresAt.toIso8601String(),
        'premium_subscription_type': isAnnual ? 'annual' : 'monthly',
      }).eq('id', userId);

      // Transaction logging is handled by createPayment and completePremiumPayment

      return true;
    } catch (e) {
      debugPrint('Error activating premium: $e');
      return false;
    }
  }

  /// Deactivate premium (for cancellation/expiry)
  Future<bool> deactivatePremium() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('users').update({
        'is_premium': false,
        'premium_expires_at': null,
        'premium_subscription_type': null,
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error deactivating premium: $e');
      return false;
    }
  }

  /// Get ecosystem application fee discount for premium users
  double getEcosystemDiscountPercentage() {
    return 0.70; // 70% discount
  }

  /// Calculate discounted application fee
  Future<double> calculateApplicationFee(double baseFee) async {
    final isPremium = await checkPremiumStatus();
    if (isPremium) {
      return baseFee * (1 - getEcosystemDiscountPercentage());
    }
    return baseFee;
  }

  /// Create a premium payment record
  Future<Map<String, dynamic>> createPayment({
    required bool isAnnual,
    required String userId,
    String paymentMethod = 'stripe',
  }) async {
    try {
      final amount = isAnnual ? annualPrice : monthlyPrice;
      final subscriptionType = isAnnual ? 'annual' : 'monthly';
      final expiresAt = DateTime.now().add(
        Duration(days: isAnnual ? 365 : 30),
      );

      final result = await _supabase
          .from('premium_payments')
          .insert({
            'user_id': userId,
            'amount': amount,
            'currency': 'USD',
            'subscription_type': subscriptionType,
            'payment_method': paymentMethod,
            'status': 'pending',
            'started_at': DateTime.now().toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'payment': PremiumPaymentModel.fromJson(result),
        'message': 'Payment record created successfully',
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Failed to create payment: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Process premium payment using Stripe (via Edge Function)
  /// On Web: Returns clientSecret for WebPaymentForm widget
  /// On Mobile: Uses PaymentSheet
  Future<Map<String, dynamic>> processPayment({
    required String paymentId,
    required bool isAnnual,
    required String userId,
    required String email,
  }) async {
    try {
      final amount = isAnnual ? annualPrice : monthlyPrice;
      final subscriptionType = isAnnual ? 'annual' : 'monthly';

      // Step 1: Call Edge Function to create Stripe PaymentIntent
      debugPrint('🔵 Calling create-premium-subscription Edge Function...');
      debugPrint('📧 Email: $email');
      debugPrint('💰 Amount: \$${amount.toStringAsFixed(2)}');
      debugPrint('📅 Type: $subscriptionType');

      final response = await _supabase.functions.invoke(
        'create-premium-subscription',
        body: {
          'amount': amount,
          'userId': userId,
          'email': email,
          'subscriptionType': subscriptionType,
        },
      );

      debugPrint('📡 Edge Function response status: ${response.status}');
      debugPrint('📦 Edge Function response data: ${response.data}');

      if (response.status != 200) {
        final errorDetails = response.data is Map
            ? response.data['details'] ?? response.data['error']
            : response.data.toString();
        debugPrint('❌ Edge Function error: $errorDetails');
        throw Exception('Failed to create payment intent: $errorDetails');
      }

      final clientSecret = response.data['clientSecret'] as String;
      final paymentIntentId = response.data['paymentIntentId'] as String;

      // On Web: Return clientSecret for WebPaymentForm to handle
      if (kIsWeb) {
        debugPrint('🌐 Web: Returning clientSecret for WebPaymentForm');
        return {
          'success': true,
          'needsWebPayment': true,
          'clientSecret': clientSecret,
          'paymentIntentId': paymentIntentId,
          'paymentId': paymentId,
          'amount': amount,
        };
      }

      // On Mobile: Use PaymentSheet
      try {
        // Ensure Stripe is initialized (lazy, on-demand)
        final stripeReady = await LazyStripeService.ensureInitialized();
        if (!stripeReady) {
          return {
            'success': false,
            'message': 'Payment service not available',
            'error': 'Stripe initialization failed',
          };
        }

        debugPrint('🔧 Initializing Stripe Payment Sheet...');
        debugPrint('🔑 Client Secret: ${clientSecret.substring(0, 20)}...');

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'FounderVers Premium',
            style: ThemeMode.light,
            appearance: const PaymentSheetAppearance(
              primaryButton: PaymentSheetPrimaryButtonAppearance(
                colors: PaymentSheetPrimaryButtonTheme(
                  light: PaymentSheetPrimaryButtonThemeColors(
                    background: Color(0xFFFFA726),
                    text: Colors.white,
                  ),
                ),
              ),
            ),
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'US',
              testEnv: true,
              currencyCode: 'USD',
            ),
          ),
        );

        debugPrint('✅ Payment sheet initialized successfully');

        // Step 3: Present Stripe Payment Sheet to user
        debugPrint('📱 Presenting payment sheet...');
        await Stripe.instance.presentPaymentSheet();

        debugPrint('✅ Payment sheet completed successfully');

        // Step 4: Update payment record with payment intent ID
        final updateResult = await _supabase
            .from('premium_payments')
            .update({
              'payment_intent_id': paymentIntentId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId)
            .select()
            .single();

        return {
          'success': true,
          'payment': PremiumPaymentModel.fromJson(updateResult),
          'message': 'Payment processed successfully',
          'paymentIntentId': paymentIntentId,
        };
      } on StripeException catch (e) {
        // User cancelled or payment sheet error
        String errorMessage = 'Payment sheet error occurred';

        if (e.error.code == FailureCode.Canceled) {
          errorMessage = 'Payment was cancelled by user';
        } else if (e.error.code == FailureCode.Failed) {
          errorMessage = 'Payment failed: ${e.error.localizedMessage}';
        }

        debugPrint('❌ Stripe error: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
          'error': e.error.message ?? 'Unknown Stripe error',
          'cancelled': e.error.code == FailureCode.Canceled,
        };
      }
    } catch (e) {
      debugPrint('💥 Premium payment processing exception: $e');
      return {
        'success': false,
        'message': 'Payment processing failed',
        'error': e.toString(),
      };
    }
  }

  /// Mark premium payment as completed and activate subscription
  Future<bool> completePremiumPayment({
    required String paymentId,
    required bool isAnnual,
  }) async {
    try {
      // Update payment status
      await _supabase.from('premium_payments').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      // Activate premium subscription
      return await activatePremium(
        isAnnual: isAnnual,
        transactionId: paymentId,
      );
    } catch (e) {
      debugPrint('Error completing premium payment: $e');
      return false;
    }
  }
}

/// Premium subscription status
class PremiumStatus {
  final bool isActive;
  final bool isLifetime;
  final DateTime? expiresAt;
  final String? subscriptionType; // 'monthly' or 'annual'

  PremiumStatus({
    required this.isActive,
    this.isLifetime = false,
    this.expiresAt,
    this.subscriptionType,
  });

  String get displayText {
    if (!isActive) return 'Not Active';
    if (isLifetime) return 'Lifetime Premium';
    if (expiresAt == null) return 'Active';

    final daysLeft = expiresAt!.difference(DateTime.now()).inDays;
    if (daysLeft > 30) {
      return 'Active (expires ${_formatDate(expiresAt!)})';
    } else if (daysLeft > 0) {
      return 'Active ($daysLeft days left)';
    } else {
      return 'Expired';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
