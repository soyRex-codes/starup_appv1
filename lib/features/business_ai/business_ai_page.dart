import 'package:flutter/material.dart';

/// BusinessAI Chatbot - Coming Soon Page
class BusinessAIPage extends StatelessWidget {
  const BusinessAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BusinessAI'),
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
              'BusinessAI Chatbot',
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
                    Theme.of(context).primaryColor.withOpacity(0.7),
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
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
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
