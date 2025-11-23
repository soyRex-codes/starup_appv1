import 'package:flutter/material.dart';
import 'package:foundervers/services/application_payment_service.dart';
import 'package:foundervers/services/business_application_service.dart';
import 'package:foundervers/features/ecosystem/payment_success_page.dart';
import 'package:foundervers/models/payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Payment Processing Page
/// Handles payment UI and processing via Stripe Payment Sheet
class PaymentProcessingPage extends StatefulWidget {
  final int applicationId;
  final Map<String, dynamic> applicationData;

  const PaymentProcessingPage({
    super.key,
    required this.applicationId,
    required this.applicationData,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  bool _isProcessing = false;
  String? _errorMessage;

  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      if (userId == null || userEmail == null) {
        throw Exception('User not authenticated');
      }

      // Step 1: Create payment record
      final paymentResult = await ApplicationPaymentService.createPayment(
        applicationId: widget.applicationId,
        userId: userId,
        paymentMethod: 'stripe',
      );

      if (!paymentResult['success']) {
        throw Exception(paymentResult['message']);
      }

      final paymentId = paymentResult['payment'].id;

      // Step 2: Process payment with Stripe Payment Sheet
      final processResult = await ApplicationPaymentService.processPayment(
        paymentId: paymentId,
        applicationId: widget.applicationId,
        userId: userId,
        email: userEmail,
        applicantName: widget.applicationData['applicant_name'] ?? 'Applicant',
        paymentDetails: {}, // Stripe Payment Sheet handles card details
        couponCode: _couponController.text.trim().isNotEmpty ? _couponController.text.trim() : null,
      );

      if (!processResult['success']) {
        print('❌ Payment failed: ${processResult['message']}');
        print('🔍 Error details: ${processResult['error']}');
        throw Exception(processResult['message'] ?? 'Payment failed');
      }

      // Step 3: Update application status
      await BusinessApplicationService.markApplicationAsPaid(
        applicationId: widget.applicationId,
        paymentId: paymentId,
      );

      // Step 4: Generate receipt data
      final payment = paymentResult['payment'] as PaymentModel;
      final receiptData = ApplicationPaymentService.generateReceipt(
        payment: payment,
        applicationData: widget.applicationData,
      );

      // Step 5: Navigate to success page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              applicationId: widget.applicationId,
              receiptData: receiptData,
            ),
          ),
        );
      }
    } catch (e) {
      print('💥 Payment processing exception: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your payment information is encrypted and secure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '\$${ApplicationPaymentService.baseApplicationFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B2C),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Coupon Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coupon Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter code (e.g. SAVE10)',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Application ID', '#${widget.applicationId}'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Service Type',
                      widget.applicationData['service_type'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Applicant',
                      widget.applicationData['applicant_name'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'Payment Method', 'Credit/Debit Card via Stripe'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A secure Stripe payment screen will open when you click "Pay Now"',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
