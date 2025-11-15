import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foundervers/app/app_icons.dart';

/// Help & Support page with FAQ and contact information
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          _buildSectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 16),

          _buildFAQItem(
            question: 'How do I create my first post?',
            answer:
                'Tap the "+" button in the bottom navigation bar, fill in your post details including title, description, and category. You can also add images to showcase your idea or project.',
          ),

          _buildFAQItem(
            question: 'How do I connect with other founders?',
            answer:
                'You can connect with founders by:\n• Messaging them directly from their profile\n• Participating in Global Chat\n• Responding to posts with collaboration requests\n• Using action buttons on posts (Invest, Collaborate, Contact)',
          ),

          _buildFAQItem(
            question: 'What are the different post categories?',
            answer:
                'FounderVers supports various categories including Technology, Finance, Marketing, Healthcare, E-commerce, and more. Choose the category that best fits your startup or idea.',
          ),

          _buildFAQItem(
            question: 'How does the messaging system work?',
            answer:
                'The app has two messaging systems:\n• Direct Messages (DMs) - Private conversations with other founders\n• Global Chat - Community-wide discussions where all founders can participate',
          ),

          _buildFAQItem(
            question: 'Can I edit or delete my posts?',
            answer:
                'Yes! You can edit or delete your posts by tapping the three-dot menu on your post cards. Only you can modify your own posts.',
          ),

          _buildFAQItem(
            question: 'How do I update my profile?',
            answer:
                'Go to Menu → Profile & Account to update your profile information, bio, company details, and profile picture.',
          ),

          _buildFAQItem(
            question: 'What is the Suggestions Inbox?',
            answer:
                'The Suggestions Inbox contains ideas and feedback from other founders on your posts. You can review, accept, or respond to suggestions to improve your projects.',
          ),

          _buildFAQItem(
            question: 'How do I delete my account?',
            answer:
                'Go to Menu → Settings → Delete Account. This will permanently remove all your data including posts, messages, and profile information. This action cannot be undone.',
          ),

          _buildFAQItem(
            question: 'Is my data secure?',
            answer:
                'Yes, we use enterprise-grade security measures and follow industry best practices for data protection. Your personal information and conversations are encrypted and secure.',
          ),

          const SizedBox(height: 32),

          // Contact Support Section
          _buildSectionHeader('Need More Help?'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
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
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'For personalized assistance or technical issues that aren\'t covered in our FAQ, our support team is here to help.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
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
          _buildSectionHeader('App Information'),
          const SizedBox(height: 16),

          _buildInfoTile(
            icon: AppIcons.info(size: 24),
            title: 'Version',
            subtitle: '1.0.0',
          ),

          const SizedBox(height: 8),
          _buildInfoTile(
            icon: AppIcons.appLogo(size: 24),
            title: 'About FounderVers',
            subtitle:
                'A platform connecting entrepreneurs and founders worldwide',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
            'Hi FounderVers Support Team,\n\nI need assistance with:\n\n[Please describe your issue or question here]\n\nApp Version: 1.0.0\nDevice: ${_getDeviceInfo()}\n\nThank you for your help!\n\nBest regards,',
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
