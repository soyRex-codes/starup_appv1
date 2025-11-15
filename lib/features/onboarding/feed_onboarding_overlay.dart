import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding overlay for first-time users on the Feed page
class FeedOnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Widget child;

  const FeedOnboardingOverlay({
    super.key,
    required this.onComplete,
    required this.child,
  });

  @override
  State<FeedOnboardingOverlay> createState() => _FeedOnboardingOverlayState();

  /// Check if user has completed feed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('feed_onboarding_completed') ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feed_onboarding_completed', true);
  }
}

class _FeedOnboardingOverlayState extends State<FeedOnboardingOverlay> {
  @override
  void initState() {
    super.initState();
    // Show onboarding dialog after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOnboardingDialog();
    });
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => OnboardingDialog(
        onComplete: () async {
          await FeedOnboardingOverlay.completeOnboarding();
          widget.onComplete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return child directly without overlay
    return widget.child;
  }
}

/// Modern onboarding dialog with PageView
class OnboardingDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.rocket_launch,
      iconColor: Color(0xFFFF6B2C),
      title: 'Welcome to FounderVers! ',
      description:
          'Discover founders, share your journey, and build meaningful connections.',
    ),
    OnboardingPage(
      icon: Icons.search,
      iconColor: Color(0xFF6B4EFF),
      title: 'Find Your Community',
      description:
          'Search and filter posts by category, stage, or location to find relevant content.',
    ),
    OnboardingPage(
      icon: Icons.favorite,
      iconColor: Color(0xFFFF4E88),
      title: 'Engage & Connect',
      description:
          'Comment, Bookmark, and suggest improvements on posts that resonate with you.',
    ),
    OnboardingPage(
      icon: Icons.add_circle,
      iconColor: Color(0xFF00C853),
      title: 'Share Your startup Story',
      description:
          'Create posts to share your startup journey, ideas, or ask for feedback, to collaborate, and find investment.',
    ),
    OnboardingPage(
      icon: Icons.explore,
      iconColor: Color(0xFF00BCD4),
      title: 'Explore All Features',
      description:
          'Access Ecosystem services, Business.AI tools, and connect via Chat!',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
      widget.onComplete();
    }
  }

  void _skipOnboarding() {
    Navigator.of(context).pop();
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Responsive sizing
    final titleFontSize = isSmallScreen ? 20.0 : 22.0;
    final descriptionFontSize = isSmallScreen ? 13.5 : 14.5;
    final iconSize = isSmallScreen ? 70.0 : 80.0;
    final horizontalPadding = screenWidth < 360 ? 20.0 : 24.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skip button (compact)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon (smaller)
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: page.iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: iconSize * 0.5,
                            color: page.iconColor,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        // Title (optimized)
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        // Description (optimized)
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: descriptionFontSize,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicator and button
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                children: [
                  // Page dots (compact)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 28 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFFF6B2C)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 16),
                  // Next/Get Started button (compact)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B2C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}
