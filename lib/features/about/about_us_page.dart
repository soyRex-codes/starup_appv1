import 'package:flutter/material.dart';
import 'package:foundervers/widgets/terai_logo.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375; // iPhone SE, iPhone 12/13 mini
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 20.0;
    final sectionSpacing = isSmallScreen ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Terai',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // App Logo
                  Container(
                    width: isSmallScreen ? 180 : 220,
                    height: isSmallScreen ? 75 : 95,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TeraiLogo(
                      width: isSmallScreen ? 180 : 220,
                      height: isSmallScreen ? 75 : 95,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    'Terai',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Connecting Visionary Founders',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Mission Section
            _SectionCard(
              icon: Icons.flag_outlined,
              iconColor: Colors.orange,
              title: 'Our Mission',
              content:
                  'We believe every great idea deserves the right connections to become reality. Terai exists to bridge the gap between visionary founders, passionate investors, and skilled collaborators.',
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: verticalSpacing),

            // How We Make It Possible
            _SectionCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: 'How We Make It Possible',
              content:
                  'Through our thoughtful, form-based approach to connections, we ensure every interaction is meaningful. Whether you\'re seeking investment, collaboration, or simply want to share suggestions, our platform facilitates genuine relationships built on mutual respect and shared vision.',
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: verticalSpacing),

            // Platform Features
            _FeatureSection(isSmallScreen: isSmallScreen),

            SizedBox(height: verticalSpacing),

            // Vision Section
            _SectionCard(
              icon: Icons.visibility_outlined,
              iconColor: Colors.blue,
              title: 'Our Vision',
              content:
                  'To create the world\'s most trusted ecosystem where founders can connect, collaborate, and build the future together. We envision a platform where great ideas meet great people, fostering innovation that makes a positive impact on the world.',
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: sectionSpacing),

            // Values Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_outline,
                            color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Our Values',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _ValueItem('Authenticity',
                      'We believe in genuine connections and honest communication.',
                      isSmallScreen: isSmallScreen),
                  _ValueItem('Innovation',
                      'We constantly evolve to serve our community better.',
                      isSmallScreen: isSmallScreen),
                  _ValueItem('Respect',
                      'Every founder\'s journey is unique and deserves respect.',
                      isSmallScreen: isSmallScreen),
                  _ValueItem('Privacy',
                      'Your ideas and communications are protected and private.',
                      isSmallScreen: isSmallScreen),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            // Call to Action
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    color: Colors.white,
                    size: isSmallScreen ? 28 : 32,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Join Our Community',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Ready to connect with like-minded founders and turn your vision into reality?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.isSmallScreen,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            content,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.isSmallScreen});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Platform Features',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _FeatureItem(Icons.business_outlined, 'Smart Investment Matching',
              'Connect with investors who align with your vision',
              isSmallScreen: isSmallScreen),
          _FeatureItem(Icons.group_outlined, 'Collaboration Hub',
              'Find co-founders and team members who complement your skills',
              isSmallScreen: isSmallScreen),
          _FeatureItem(Icons.chat_bubble_outline, 'Thoughtful Messaging',
              'Form-based approach ensures meaningful conversations',
              isSmallScreen: isSmallScreen),
          _FeatureItem(Icons.lightbulb_outline, 'Suggestion System',
              'Share and receive valuable feedback privately',
              isSmallScreen: isSmallScreen),
          _FeatureItem(Icons.security_outlined, 'Privacy First',
              'Your ideas and conversations remain confidential',
              isSmallScreen: isSmallScreen),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem(this.icon, this.title, this.description,
      {required this.isSmallScreen});

  final IconData icon;
  final String title;
  final String description;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon,
                size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  const _ValueItem(this.title, this.description, {required this.isSmallScreen});

  final String title;
  final String description;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
