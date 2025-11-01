import 'package:flutter/material.dart';
import 'package:foundervers/services/application_payment_service.dart';
import 'package:foundervers/services/business_application_service.dart';
import 'package:foundervers/features/ecosystem/payment_processing_page.dart';

/// Payment Summary Page
/// Shows application details and $20 fee before payment
class PaymentSummaryPage extends StatelessWidget {
  final int applicationId;
  final Map<String, dynamic> applicationData;

  const PaymentSummaryPage({
    super.key,
    required this.applicationId,
    required this.applicationData,
  });

  @override
  Widget build(BuildContext context) {
    final serviceType = applicationData['service_type'] as String? ?? '';
    final applicantName = applicationData['applicant_name'] as String? ?? '';
    final applicantEmail = applicationData['applicant_email'] as String? ?? '';
    final formData =
        applicationData['form_data'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Review & Pay'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Application Summary Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B2C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFFFF6B2C),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review your details before payment',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Application Details
                  _buildDetailRow(
                      'Service Type',
                      BusinessApplicationService.getServiceTypeName(
                          serviceType)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Applicant Name', applicantName),
                  const SizedBox(height: 16),
                  _buildDetailRow('Email', applicantEmail),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Application ID', '#${applicationId.toString()}'),

                  // Additional form data summary
                  if (formData.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...formData.entries
                        .where((e) =>
                            e.key != 'uploaded_files' &&
                            e.value != null &&
                            e.value.toString().isNotEmpty)
                        .take(3)
                        .map((entry) {
                      String label =
                          entry.key.replaceAll('_', ' ').toUpperCase();
                      String value = entry.value.toString();
                      if (value.length > 50) {
                        value = '${value.substring(0, 50)}...';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDetailRow(label, value),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

            // Payment Fee Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B2C), Color(0xFFFF8F5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B2C).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Application Processing Fee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '\$${ApplicationPaymentService.applicationFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'One-time non-refundable fee',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // What's Included
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s Included',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIncludedItem(
                      '✓', 'Application review within 24-48 hours'),
                  _buildIncludedItem(
                      '✓', 'Direct connection with service providers'),
                  _buildIncludedItem('✓', 'Email confirmation and receipt'),
                  _buildIncludedItem('✓', 'Application status tracking'),
                  _buildIncludedItem('✓', 'Priority customer support'),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),

      // Proceed to Payment Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _proceedToPayment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B2C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Proceed to Secure Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B2C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  color: Color(0xFFFF6B2C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToPayment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingPage(
          applicationId: applicationId,
          applicationData: applicationData,
        ),
      ),
    );
  }
}
