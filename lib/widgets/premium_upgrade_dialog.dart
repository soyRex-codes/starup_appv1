import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:foundervers/features/premium/premium_payment_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Premium upgrade dialog shown when non-premium users try to access locked features
class PremiumUpgradeDialog extends StatefulWidget {
  final String featureName;

  const PremiumUpgradeDialog({
    super.key,
    required this.featureName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String featureName,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => PremiumUpgradeDialog(featureName: featureName),
    );
  }

  @override
  State<PremiumUpgradeDialog> createState() => _PremiumUpgradeDialogState();
}

class _PremiumUpgradeDialogState extends State<PremiumUpgradeDialog> {
  bool _isAnnual = true; // Default to annual plan

  void _navigateToPayment() {
    Navigator.pop(context, true);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumPaymentPage(isAnnual: _isAnnual),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;

    // Adaptive padding and sizing
    // Adaptive padding and sizing
    final dialogPadding = isSmallScreen ? 14.0 : 22.0;
    final iconSize = isSmallScreen ? 32.0 : 42.0;
    final titleSize = isSmallScreen ? 18.0 : 22.0;
    final descSize = isSmallScreen ? 13.0 : 15.0;
    final benefitSize = isSmallScreen ? 11.0 : 13.0;
    final spacingSmall = isSmallScreen ? 6.0 : 10.0;
    final spacingMedium = isSmallScreen ? 14.0 : 22.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isSmallScreen ? 24 : 32, // Reduced vertical padding
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                dialogPadding + 20, // Add top padding for close button
                dialogPadding,
                dialogPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Golden ticket icon
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: iconSize,
                      color: Colors.amber.shade700,
                    ),
                  ),

                  SizedBox(height: spacingMedium),

                  // Title
                  Text(
                    'Premium Feature',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: spacingSmall),

                  // Description
                  Text(
                    '${widget.featureName} is only available for Premium members.',
                    style: TextStyle(
                      fontSize: descSize,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: spacingMedium),

                  // Benefits list
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to unlock:',
                          style: TextStyle(
                            fontSize: benefitSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        _buildBenefit('✨', 'Business.AI assistant', benefitSize),
                        _buildBenefit('💬', 'Global Chat access', benefitSize),
                        _buildBenefit('👑', 'Golden premium Crown badge', benefitSize),
                        _buildBenefit('💰', '70% off ecosystem fees', benefitSize),
                        _buildBenefit('📊', 'Advanced analytics', benefitSize),
                        _buildBenefit(
'🎟️', 'Early access to features', benefitSize),
                        _buildBenefit('!', 'Priority investor access', benefitSize),
                      ],
                    ),
                  ),

                  SizedBox(height: spacingMedium),

                  // Plan Selection and Buttons
                  if (!kIsWeb && Platform.isIOS) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Premium subscriptions are currently not available for purchase on the iOS app - Coming Soon on IOS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: descSize,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'foundervers@gmail.com',
                                query: 'subject=Premium Subscription Question',
                              );
                              debugPrint('📧 Attempting to launch: $emailLaunchUri');
                              try {
                                if (await canLaunchUrl(emailLaunchUri)) {
                                  await launchUrl(emailLaunchUri);
                                } else {
                                  // Fallback: try launching anyway (simulator sometimes fails check)
                                  await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                debugPrint('❌ Could not launch email: $e');
                              }
                            },
                            child: Text(
                              'Questions? Email: foundervers@gmail.com',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: descSize * 0.9,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final Uri websiteUri = Uri.parse('https://foundervers.com/');
                              debugPrint('🌐 Attempting to launch: $websiteUri');
                              try {
                                if (await canLaunchUrl(websiteUri)) {
                                  await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
                                } else {
                                  await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                debugPrint('❌ Could not launch website: $e');
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.language,
                                    size: 18,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Learn more at foundervers.com',
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontSize: descSize * 0.95,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacingMedium),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey.shade200, // Make it look more like a button
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Plan Selection - Stack vertically on very small screens
                    isSmallScreen
                        ? Column(
                            children: [
                              _buildSelectablePriceCard(
                                'Monthly',
                                '\$19.99',
                                'per month',
                                !_isAnnual,
                                () => setState(() => _isAnnual = false),
                              ),
                              SizedBox(height: spacingSmall),
                              _buildSelectablePriceCard(
                                'Annual',
                                '\$167.99',
                                'per year',
                                _isAnnual,
                                () => setState(() => _isAnnual = true),
                                savings: 'Save 30%',
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isAnnual = false),
                                  child: _buildPriceCard(
                                    'Monthly',
                                    '\$19.99',
                                    'per month',
                                    !_isAnnual,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacingSmall),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isAnnual = true),
                                  child: _buildPriceCard(
                                    'Annual',
                                    '\$167.99',
                                    'per year',
                                    _isAnnual,
                                    savings: 'Save 30%',
                                  ),
                                ),
                              ),
                            ],
                          ),

                    SizedBox(height: spacingMedium),

                    // Buttons - Stack vertically on small screens
                    isSmallScreen
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _navigateToPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Upgrade Now',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: spacingSmall),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 14),
                                  ),
                                  child: Text(
                                    'Maybe Later',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    'Maybe Later',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: spacingSmall),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _navigateToPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Upgrade Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ],
              ),
            ),

            // Fixed Close Button (Top Right)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String emoji, String text, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: fontSize + 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectablePriceCard(
    String period,
    String price,
    String suffix,
    bool isRecommended,
    VoidCallback onTap, {
    String? savings,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildPriceCard(
        period,
        price,
        suffix,
        isRecommended,
        savings: savings,
      ),
    );
  }

  Widget _buildPriceCard(
    String period,
    String price,
    String suffix,
    bool isRecommended, {
    String? savings,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended ? Colors.amber.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? Colors.amber.shade300 : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (savings != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                savings,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          if (savings != null) const SizedBox(height: 4),
          Text(
            period,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isRecommended ? Colors.amber.shade700 : Colors.grey.shade800,
            ),
          ),
          Text(
            suffix,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
