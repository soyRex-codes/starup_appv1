import 'package:flutter/material.dart';
import 'package:foundervers/services/premium_subscription_service.dart';
import 'package:foundervers/widgets/premium_upgrade_dialog.dart';

/// BusinessAI Chatbot - Premium Feature with Lock Screen
class BusinessAIPage extends StatefulWidget {
  const BusinessAIPage({super.key});

  @override
  State<BusinessAIPage> createState() => _BusinessAIPageState();
}

class _BusinessAIPageState extends State<BusinessAIPage> {
  bool? _isPremium;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final isPremium = await PremiumSubscriptionService().checkPremiumStatus();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business.AI'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show lock screen for non-premium users
    if (_isPremium != true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business.AI'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Business.AI is Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get AI-powered business insights and guidance! This is a premium feature exclusive to our premium members.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await PremiumUpgradeDialog.show(
                        context,
                        featureName: 'Business.AI',
                      );
                      _checkPremium(); // Re-check after returning from dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Unlock Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

    // Premium user - show actual Business.AI content
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business.AI'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // AI Chatbot Icon
            Image.asset(
              'lib/icons/ai-chatbot.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Business.AI Assistant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Coming Soon Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Coming Soon!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'To answer all your business-related questions',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 15,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features Slider
            SizedBox(
              height: 200,
              child: PageView(
                children: [
                  _buildFeatureCard(
                    'Get instant answers to business questions',
                    Icons.question_answer,
                  ),
                  _buildFeatureCard(
                    'AI-powered startup guidance',
                    Icons.lightbulb,
                  ),
                  _buildFeatureCard(
                    '24/7 intelligent business assistant',
                    Icons.access_time,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue[600], size: 32),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
