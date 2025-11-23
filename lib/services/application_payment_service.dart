import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:foundervers/models/payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/premium_subscription_service.dart';

/// Application Payment Service
/// Handles payment processing for ecosystem applications
/// Base fee: $20.00 (Premium users get 70% discount = $6.00)
class ApplicationPaymentService {
  static final _supabase = Supabase.instance.client;
  static const double baseApplicationFee = 20.00;
  static const String currency = 'USD';

  /// Get application fee (with premium discount if applicable)
  static Future<double> getApplicationFee() async {
    final premiumService = PremiumSubscriptionService();
    return await premiumService.calculateApplicationFee(baseApplicationFee);
  }

  /// Create a payment record for an application
  static Future<Map<String, dynamic>> createPayment({
    required int applicationId,
    required String userId,
    String paymentMethod = 'stripe',
  }) async {
    try {
      final applicationFee =
          await getApplicationFee(); // Get fee with premium discount

      final result = await _supabase
          .from('application_payments')
          .insert({
            'application_id': applicationId,
            'user_id': userId,
            'amount': applicationFee,
            'currency': currency,
            'payment_method': paymentMethod,
            'status': 'pending',
          })
          .select()
          .single();

      return {
        'success': true,
        'payment': PaymentModel.fromJson(result),
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

  /// Process payment using Stripe (via Edge Function)
  /// Calls create-payment-intent Edge Function to get clientSecret
  /// Then shows Stripe Payment Sheet for user to enter card details
  static Future<Map<String, dynamic>> processPayment({
    required String paymentId,
    required int applicationId,
    required String userId,
    required String email,
    required String applicantName,
    required Map<String, dynamic> paymentDetails,
    String? couponCode,
  }) async {
    try {
      final applicationFee =
          await getApplicationFee(); // Get fee with premium discount

      // Step 1: Call Edge Function to create Stripe PaymentIntent
      debugPrint('🔵 Calling create-payment-intent Edge Function...');
      debugPrint('📧 Email: $email');
      debugPrint('💰 Amount: \$${applicationFee.toStringAsFixed(2)}');
      if (couponCode != null) debugPrint('🎟️ Coupon: $couponCode');

      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': applicationFee,
          'applicationId': applicationId.toString(),
          'userId': userId,
          'email': email,
          'applicant_name': applicantName,
          'couponCode': couponCode,
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

      // Check for Free Transaction (100% off coupon)
      if (response.data['isFree'] == true) {
        debugPrint('🎉 Transaction is free! Skipping Stripe Payment Sheet.');
        
        // Update payment record to 'succeeded' immediately
        final updateResult = await _supabase
            .from('application_payments')
            .update({
              'status': 'succeeded',
              'payment_method': 'coupon',
              'payment_intent_id': 'free_${DateTime.now().millisecondsSinceEpoch}',
              'metadata': {'coupon_code': couponCode, 'is_free': true},
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId)
            .select()
            .single();

        return {
          'success': true,
          'payment': PaymentModel.fromJson(updateResult),
          'message': 'Coupon applied! Payment complete.',
          'paymentIntentId': 'free',
        };
      }

      final clientSecret = response.data['clientSecret'] as String;
      final paymentIntentId = response.data['paymentIntentId'] as String;

      // Step 2: Initialize Stripe Payment Sheet
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'FounderVers',
            style: ThemeMode.system,
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'US',
              testEnv: true,
            ),
            // Apple Pay removed - requires merchant identifier setup
            // applePay: const PaymentSheetApplePay(
            //   merchantCountryCode: 'US',
            // ),
          ),
        );

        // Step 3: Present Stripe Payment Sheet to user
        await Stripe.instance.presentPaymentSheet();

        // Step 4: Update payment record with payment intent ID
        final updateResult = await _supabase
            .from('application_payments')
            .update({
              'payment_intent_id': paymentIntentId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId)
            .select()
            .single();

        return {
          'success': true,
          'payment': PaymentModel.fromJson(updateResult),
          'message': 'Payment processed successfully',
          'paymentIntentId': paymentIntentId,
        };
      } on StripeException catch (e) {
        // User cancelled or payment sheet error
        String errorMessage = 'Payment sheet error occurred';

        if (e.error.code == FailureCode.Canceled) {
          errorMessage = 'Payment was cancelled by user';
        } else {
          errorMessage = e.error.localizedMessage ??
              e.error.message ??
              'Payment sheet error occurred';
        }

        // Update payment record with error
        await _supabase.from('application_payments').update({
          'status': 'failed',
          'error_message': errorMessage,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', paymentId);

        return {
          'success': false,
          'message': 'Payment was cancelled or failed',
          'error': errorMessage,
        };
      }
    } on PostgrestException catch (e) {
      // Database error
      await _supabase.from('application_payments').update({
        'status': 'failed',
        'error_message': e.message,
      }).eq('id', paymentId);

      return {
        'success': false,
        'message': 'Payment processing failed: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      // Edge function or general error
      debugPrint('❌ Payment processing error: $e');
      debugPrint('📋 Error type: ${e.runtimeType}');

      await _supabase.from('application_payments').update({
        'status': 'failed',
        'error_message': e.toString(),
      }).eq('id', paymentId);

      return {
        'success': false,
        'message': 'Payment processing failed',
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
    }
  }

  /// Get payment details for an application
  static Future<PaymentModel?> getPaymentForApplication(
      int applicationId) async {
    try {
      final result = await _supabase
          .from('application_payments')
          .select()
          .eq('application_id', applicationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result == null) return null;
      return PaymentModel.fromJson(result);
    } catch (e) {
      return null;
    }
  }

  /// Get all payments for current user
  static Future<List<PaymentModel>> getUserPayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final result = await _supabase
          .from('application_payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return result.map((json) => PaymentModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if application has been paid
  static Future<bool> isApplicationPaid(int applicationId) async {
    try {
      final result = await _supabase
          .from('application_payments')
          .select('status')
          .eq('application_id', applicationId)
          .eq('status', 'succeeded')
          .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Request refund for a payment
  static Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    required String reason,
  }) async {
    try {
      // TODO: Call Supabase Edge Function to process Stripe refund
      // For now, just update status

      final result = await _supabase
          .from('application_payments')
          .update({
            'status': 'refunded',
            'metadata': {'refund_reason': reason},
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId)
          .select()
          .single();

      return {
        'success': true,
        'payment': PaymentModel.fromJson(result),
        'message': 'Refund processed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Refund failed',
        'error': e.toString(),
      };
    }
  }

  /// Generate receipt data for a payment
  static Map<String, dynamic> generateReceipt({
    required PaymentModel payment,
    required Map<String, dynamic> applicationData,
  }) {
    return {
      'payment_id': payment.id,
      'application_id': payment.applicationId,
      'amount': payment.amount,
      'currency': payment.currency,
      'status': payment.status.displayName,
      'paid_at': payment.updatedAt.toIso8601String(),
      'applicant_name': applicationData['applicant_name'] ?? 'N/A',
      'applicant_email': applicationData['applicant_email'] ?? 'N/A',
      'service_type': applicationData['service_type'] ?? 'N/A',
      'receipt_number': 'FV-${payment.id.substring(0, 8).toUpperCase()}',
      'payment_method': payment.paymentMethod ?? 'Card',
    };
  }
}
