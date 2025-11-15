import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foundervers/services/premium_subscription_service.dart';
import 'package:foundervers/services/iap_service.dart';
import 'package:foundervers/models/premium_payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Premium Payment Processing Page
/// Handles premium subscription payment UI and processing via Stripe Payment Sheet
class PremiumPaymentPage extends StatefulWidget {
  final bool isAnnual;

  const PremiumPaymentPage({
    super.key,
    required this.isAnnual,
  });

  @override
  State<PremiumPaymentPage> createState() => _PremiumPaymentPageState();
}

class _PremiumPaymentPageState extends State<PremiumPaymentPage> {
  bool _isProcessing = false;
  String? _errorMessage;
  final _premiumService = PremiumSubscriptionService();

  late bool _isAnnualPlan;

  @override
  void initState() {
    super.initState();
    _isAnnualPlan = widget.isAnnual;
  }

  double get _amount => _isAnnualPlan
      ? PremiumSubscriptionService.annualPrice
      : PremiumSubscriptionService.monthlyPrice;

  String get _subscriptionType => _isAnnualPlan ? 'Annual' : 'Monthly';

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('🚀 Starting premium payment process...');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      if (userId == null || userEmail == null) {
        throw Exception('User not authenticated');
      }

      print('👤 User ID: $userId');
      print('📧 User Email: $userEmail');

      // Use IAP on iOS, Stripe on Android
      if (Platform.isIOS) {
        await _processAppleIAPPayment(userId);
      } else {
        await _processStripePayment(userId, userEmail);
      }
    } catch (e) {
      print('💥 Premium payment processing exception: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });

      // Show error dialog
      if (mounted) {
        _showErrorDialog(
          'Payment Error',
          _errorMessage ?? 'An unexpected error occurred',
          null,
        );
      }
    }
  }

  /// Process payment using Apple In-App Purchase (iOS only)
  Future<void> _processAppleIAPPayment(String userId) async {
    print('🍎 Using Apple In-App Purchase');

    final iapService = IAPService();

    // Initialize IAP if not already done
    final isAvailable = await iapService.initialize();

    if (!isAvailable) {
      throw Exception('In-App Purchase is not available on this device');
    }

    // Start purchase flow
    final result = await iapService.purchaseSubscription(
      isAnnual: _isAnnualPlan,
      userId: userId,
    );

    if (!result['success']) {
      throw Exception(result['message']);
    }

    print('✅ IAP purchase initiated');
    print('⏳ Waiting for Apple payment sheet...');

    // Purchase is now pending, Apple payment sheet will be shown
    // Result will be handled by IAP service's purchase stream
    // Show loading message
    if (mounted) {
      setState(() {
        _errorMessage = 'Processing payment with Apple...';
      });
    }

    // Wait a moment for the purchase to complete
    await Future.delayed(const Duration(seconds: 2));

    // Check if premium was activated
    final isPremium = await _premiumService.checkPremiumStatus();

    if (isPremium) {
      print('🎉 Premium activated via IAP!');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PremiumPaymentSuccessPage(
              isAnnual: _isAnnualPlan,
              amount: _amount,
            ),
          ),
        );
      }
    } else {
      // Still processing, show message
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Purchase initiated. Please complete the payment in the Apple payment sheet. '
              'If you completed the purchase, it may take a few moments to activate.';
        });
      }
    }
  }

  /// Process payment using Stripe (Android only)
  Future<void> _processStripePayment(String userId, String userEmail) async {
    print('💳 Using Stripe payment');

    // Step 1: Create payment record
    print('📝 Step 1: Creating payment record...');
    final paymentResult = await _premiumService.createPayment(
      isAnnual: _isAnnualPlan,
      userId: userId,
      paymentMethod: 'stripe',
    );

    if (!paymentResult['success']) {
      throw Exception(paymentResult['message']);
    }

    final payment = paymentResult['payment'] as PremiumPaymentModel;
    final paymentId = payment.id;
    print('✅ Payment record created: $paymentId');

    // Step 2: Process payment with Stripe Payment Sheet
    print('💳 Step 2: Processing payment with Stripe...');
    final processResult = await _premiumService.processPayment(
      paymentId: paymentId,
      isAnnual: _isAnnualPlan,
      userId: userId,
      email: userEmail,
    );

    if (!processResult['success']) {
      // Check if user cancelled
      if (processResult['cancelled'] == true) {
        print('ℹ️ Payment cancelled by user');
        setState(() {
          _errorMessage = 'Payment was cancelled';
          _isProcessing = false;
        });
        return;
      }

      print('❌ Payment failed: ${processResult['message']}');
      print('🔍 Error details: ${processResult['error']}');

      // Show user-friendly error message
      setState(() {
        _errorMessage =
            processResult['message'] ?? 'Payment failed. Please try again.';
        _isProcessing = false;
      });

      // Show error dialog with details
      if (mounted) {
        _showErrorDialog(
          'Payment Failed',
          processResult['message'] ?? 'An error occurred during payment',
          processResult['error']?.toString(),
        );
      }
      return;
    }

    print('✅ Payment processed successfully');

    // Step 3: Complete premium payment and activate subscription
    print('🎯 Step 3: Activating premium subscription...');
    final activated = await _premiumService.completePremiumPayment(
      paymentId: paymentId,
      isAnnual: _isAnnualPlan,
    );

    if (!activated) {
      throw Exception('Failed to activate premium subscription');
    }

    print('🎉 Premium subscription activated successfully!');

    // Step 4: Navigate to success page
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PremiumPaymentSuccessPage(
            isAnnual: _isAnnualPlan,
            amount: _amount,
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message, String? details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Technical Details:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String priceLabel,
    required bool selected,
    required VoidCallback onTap,
    String? description,
    required bool isSmallScreen,
  }) {
    final borderColor = selected ? Colors.amber[700]! : Colors.grey.shade300;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 14,
            horizontal: isSmallScreen ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.amber[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.amber[800] : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                priceLabel,
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 20,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.amber[700] : Colors.grey[800],
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber[700], size: isSmallScreen ? 14 : 20),
          SizedBox(width: isSmallScreen ? 6 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 14,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    // Adaptive sizing for mobile - optimized for smaller screens
    final bodyPadding = isSmallScreen ? 10.0 : 20.0;
    final containerPadding = isSmallScreen ? 8.0 : 16.0;
    final verticalSpacing = isSmallScreen ? 10.0 : 24.0;
    final smallSpacing = isSmallScreen ? 4.0 : 12.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(bodyPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Badge
            Container(
              padding: EdgeInsets.all(containerPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[700]!, Colors.amber[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium,
                      color: Colors.white, size: isSmallScreen ? 24 : 32),
                  SizedBox(width: smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FounderVers Premium',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: smallSpacing / 3),
                        Text(
                          'Unlock exclusive features and benefits',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),

            Container(
              padding: EdgeInsets.all(containerPadding),
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
                  Text(
                    'Choose your plan',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: smallSpacing),
                  Row(
                    children: [
                      _buildPlanOption(
                        title: 'Monthly Plan',
                        priceLabel:
                            '\$${PremiumSubscriptionService.monthlyPrice.toStringAsFixed(2)}/month',
                        selected: !_isAnnualPlan,
                        onTap: () {
                          if (_isAnnualPlan) {
                            setState(() {
                              _isAnnualPlan = false;
                            });
                          }
                        },
                        description: 'Flexible month-to-month access',
                        isSmallScreen: isSmallScreen,
                      ),
                      SizedBox(width: smallSpacing),
                      _buildPlanOption(
                        title: 'Annual Plan',
                        priceLabel:
                            '\$${PremiumSubscriptionService.annualPrice.toStringAsFixed(2)}/year',
                        selected: _isAnnualPlan,
                        onTap: () {
                          if (!_isAnnualPlan) {
                            setState(() {
                              _isAnnualPlan = true;
                            });
                          }
                        },
                        description: 'Best value with 30% savings',
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),

            // Payment Amount
            Container(
              padding: EdgeInsets.all(containerPadding),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _subscriptionType,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${_amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  if (_isAnnualPlan) ...[
                    SizedBox(height: smallSpacing),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'Save 30% with Annual Plan',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),

            // Premium Benefits
            Container(
              padding: EdgeInsets.all(containerPadding),
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
                  Text(
                    'Premium Benefits',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: smallSpacing),
                  _buildBenefitRow(
                    Icons.smart_toy,
                    'Business.AI Assistant - AI-powered business insights',
                    isSmallScreen,
                  ),
                  _buildBenefitRow(
                    Icons.chat_bubble,
                    'Global Chat - Connect with founders worldwide',
                    isSmallScreen,
                  ),
                  _buildBenefitRow(
                    Icons.workspace_premium,
                    'Golden Premium Badge - Stand out in the community',
                    isSmallScreen,
                  ),
                  _buildBenefitRow(
                    Icons.monetization_on,
                    '70% OFF Ecosystem Application Fees',
                    isSmallScreen,
                  ),
                  _buildBenefitRow(
                    Icons.analytics,
                    'Advanced Analytics & Insights',
                    isSmallScreen,
                  ),
                  _buildBenefitRow(
                    Icons.priority_high,
                    'Priority Access to Investors',
                    isSmallScreen,
                  ),
                  SizedBox(height: smallSpacing),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: isSmallScreen ? 14 : 20),
                        SizedBox(width: isSmallScreen ? 6 : smallSpacing),
                        Expanded(
                          child: Text(
                            Platform.isIOS
                                ? 'Apple will open a secure purchase sheet when you click "Subscribe Now"'
                                : 'A secure Stripe payment screen will open when you click "Subscribe Now"',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 12,
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

            SizedBox(height: verticalSpacing),

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
                        color: Colors.red.shade700,
                        size: isSmallScreen ? 16 : 20),
                    SizedBox(width: isSmallScreen ? 6 : smallSpacing),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: isSmallScreen ? 10 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 42 : 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: isSmallScreen ? 18 : 24,
                        width: isSmallScreen ? 18 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            SizedBox(height: verticalSpacing),

            // Terms
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless cancelled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Payment Success Page
class PremiumPaymentSuccessPage extends StatelessWidget {
  final bool isAnnual;
  final double amount;

  const PremiumPaymentSuccessPage({
    super.key,
    required this.isAnnual,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[700]!, Colors.amber[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Success Title
              const Text(
                'Welcome to Premium!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Success Message
              Text(
                'You\'ve successfully subscribed to FounderVers Premium ${isAnnual ? 'Annual' : 'Monthly'} plan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
                  children: [
                    _buildInfoRow('Plan', isAnnual ? 'Annual' : 'Monthly'),
                    const Divider(height: 24),
                    _buildInfoRow('Amount', '\$${amount.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildInfoRow('Status', 'Active',
                        valueColor: Colors.green.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Benefits Activated
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All premium features are now unlocked!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to home, clearing the navigation stack
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Get Started',
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
