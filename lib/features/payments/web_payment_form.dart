import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Web-specific payment form using Stripe CardField
/// Uses confirmPayment() instead of PaymentSheet which is not supported on web
class WebPaymentForm extends StatefulWidget {
  final String clientSecret;
  final String merchantName;
  final double amount;
  final String currency;
  final VoidCallback? onSuccess;
  final Function(String error)? onError;
  final VoidCallback? onCancel;

  const WebPaymentForm({
    super.key,
    required this.clientSecret,
    required this.merchantName,
    required this.amount,
    this.currency = 'USD',
    this.onSuccess,
    this.onError,
    this.onCancel,
  });

  @override
  State<WebPaymentForm> createState() => _WebPaymentFormState();
}

class _WebPaymentFormState extends State<WebPaymentForm> {
  bool _isProcessing = false;
  bool _cardComplete = false;
  String? _errorMessage;
  // CardFieldInputDetails? _cardDetails; // Unused

  Future<void> _processPayment() async {
    if (!_cardComplete) {
      setState(() {
        _errorMessage = 'Please enter valid card details';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔵 Web: Confirming payment...');
      
      // Use confirmPayment for web
      // Note: PaymentMethodParams.card() with no arguments takes details from the CardField
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      debugPrint('✅ Web: Payment confirmed: ${paymentIntent.status}');

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        widget.onSuccess?.call();
      } else if (paymentIntent.status == PaymentIntentsStatus.RequiresAction) {
        // Handle 3D Secure or other authentication
        setState(() {
          _errorMessage = 'Additional authentication required. Please try again.';
          _isProcessing = false;
        });
      } else {
        widget.onError?.call('Payment status: ${paymentIntent.status}');
      }
    } on StripeException catch (e) {
      debugPrint('❌ Web: Stripe error: ${e.error.message}');
      setState(() {
        _errorMessage = e.error.localizedMessage ?? e.error.message ?? 'Payment failed';
        _isProcessing = false;
      });
      // Don't call onError immediately so user can try again or see error
    } catch (e) {
      debugPrint('❌ Web: Payment error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card, color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Secured by Stripe',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Card Field
          Text(
            'Card Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: CardField(
              onCardChanged: (details) {
                setState(() {
                  // _cardDetails = details;
                  _cardComplete = details?.complete ?? false;
                  if (_cardComplete) _errorMessage = null;
                });
              },
              // Note: Using minimal styling to avoid version conflicts
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Card number',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Verified Badge
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'SSL Encrypted Transaction',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Amount Display & Pay Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isProcessing || !_cardComplete) ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B2C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pay \$${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isProcessing ? null : widget.onCancel,
              child: Text(
                'Cancel Payment',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
