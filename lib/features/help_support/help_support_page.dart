import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foundervers/app/app_icons.dart';

/// Help & Support page with FAQ and contact information
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          _buildSectionHeader('Frequently Asked Questions', isDark: isDark),
          const SizedBox(height: 16),

          _buildFAQItem(
            question: 'How do I create my first post?',
            answer:
                'Tap the "+" button in the bottom navigation bar, fill in your post details including title, description, and category. You can also add images to showcase your idea or project.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'How do I connect with other founders?',
            answer:
                'You can connect with founders by:\n• Messaging them directly from their profile\n• Responding to posts with collaboration requests\n• Using action buttons on posts (Invest, Collaborate, Contact)',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'What are the different post categories?',
            answer:
                'FounderVers supports various categories including Technology, Finance, Marketing, Healthcare, E-commerce, and more. Choose the category that best fits your startup or idea.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'How does the messaging system work?',
            answer:
                'The app uses Direct Messages (DMs) for private conversations with other members.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'Can I edit or delete my posts?',
            answer:
                'Yes! You can edit or delete your posts by tapping the three-dot menu on your post cards. Only you can modify your own posts.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'How do I update my profile?',
            answer:
                'Go to Menu → Profile & Account to update your profile information, bio, company details, and profile picture.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'What is Product Feedback?',
            answer:
                'Product Feedback contains ideas and feedback from other founders on your posts. You can review and respond to feedback to improve your projects.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'How do I delete my account?',
            answer:
                'Go to Menu → Settings → Delete Account. This will permanently remove all your data including posts, messages, and profile information. This action cannot be undone.',
            isDark: isDark,
          ),

          _buildFAQItem(
            question: 'Is my data secure?',
            answer:
                'Yes, we use enterprise-grade security measures and follow industry best practices for data protection. Your personal information and conversations are encrypted and secure.',
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Contact Support Section
          _buildSectionHeader('Need More Help?', isDark: isDark),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.shade900.withValues(alpha: 0.3)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Live Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'For personalized assistance or technical issues that aren\'t covered in our FAQ, our support team is here to help.',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _sendSupportEmail(context),
                    icon: const Icon(Icons.email),
                    label: const Text(
                        'Email Support Team at foundervers@gmail.com'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader('App Information', isDark: isDark),
          const SizedBox(height: 16),

          _buildInfoTile(
            icon: AppIcons.info(size: 24),
            title: 'Version',
            subtitle: '1.2.0',
            isDark: isDark,
          ),

          const SizedBox(height: 8),
          _buildInfoTile(
            icon: AppIcons.appLogo(size: 24),
            title: 'About Terai',
            subtitle:
                'A platform connecting entrepreneurs and founders worldwide',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFAQItem(
      {required String question,
      required String answer,
      required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required Widget icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'foundervers@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'FounderVers Support Request',
        'body':
            'Hi FounderVers Support Team,\n\nI need assistance with:\n\n[Please describe your issue or question here]\n\nApp Version: 1.2.0\nDevice: ${_getDeviceInfo()}\n\nThank you for your help!\n\nBest regards,',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not open email app. Please send an email to foundervers@gmail.com'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error opening email. Please contact foundervers@gmail.com'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  String _getDeviceInfo() {
    // Simple device info - in a real app you might use device_info_plus package
    return 'Mobile Device';
  }
}
