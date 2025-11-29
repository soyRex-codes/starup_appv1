import 'package:flutter/material.dart';
import 'package:foundervers/features/feed/feed_page.dart';
import 'package:foundervers/features/dm/dm_unread_controller.dart';
import 'package:foundervers/features/ecosystem/ecosystem_application_page.dart';
import 'package:foundervers/features/chat/chat_page_with_tabs.dart';
import 'package:foundervers/features/business_ai/business_ai_page.dart';
import 'package:foundervers/core/cache/feed_cache.dart';
import 'package:foundervers/services/premium_subscription_service.dart';
import 'package:foundervers/widgets/premium_upgrade_dialog.dart';
import 'package:foundervers/services/deep_link_service.dart';
import 'package:foundervers/features/premium/premium_payment_page.dart';

import '../features/post_creation/post_creation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final GlobalKey<FeedPageState> _feedPageKey = GlobalKey<FeedPageState>();
  bool _isNavVisible = true; // Auto-hide navigation state
  bool _deepLinksInitialized = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedPage(
        key: _feedPageKey,
        onNavVisibilityChanged: (visible) {
          if (mounted && _isNavVisible != visible) {
            setState(() => _isNavVisible = visible);
          }
        },
      ),
      const EcosystemApplicationPage(),
      const BusinessAIPage(),
      const ChatPageWithTabs(),
    ];
    // Initialize unread controller once user is available (Firebase auth already initialized earlier in app start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DmUnreadController.instance.ensureStarted();
      if (!_deepLinksInitialized) {
        DeepLinkService.initialize(context);
        _deepLinksInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        // Keep nav bar fixed at the bottom. Header inside pages may still hide.
        height: null,
        curve: Curves.fastOutSlowIn,
        child: AnimatedOpacity(
          // Always show nav bar. We keep opacity constant so it doesn't hide with the feed header.
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: _NavBar(
            index: _index,
            onTap: (i) async {
              // Check if trying to access Business.AI (premium feature)
              if (i == 2) {
                // Business.AI = 2
                final isPremium =
                    await PremiumSubscriptionService().checkPremiumStatus();
                if (!isPremium && mounted) {
                  final upgrade = await PremiumUpgradeDialog.show(
                    context,
                    featureName: 'Business.AI',
                  );
                  if (upgrade == true && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PremiumPaymentPage(isAnnual: false)),
                    );
                  }
                  return; // Don't switch tabs
                }
              }

              setState(() {
                _index = i;
                // Reset nav visibility when switching tabs
                if (i != 0) _isNavVisible = true;
              });
            },
            onAdd: () async {
              if (!mounted) return;
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const PostCreationPage()),
              );
              if (created == true) {
                // Clear cache and refresh feed to show new post immediately
                FeedCache.instance.clear();
                setState(() => _index = 0);
                // Trigger feed refresh after navigation
                _feedPageKey.currentState?.refreshAfterPostCreation();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar(
      {required this.index, required this.onTap, required this.onAdd});
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(
                label: 'Home',
                icon: const Icon(Icons.home, size: 22),
                active: index == 0,
                onTap: () => onTap(0),
                iconSize: 22,
              ),
              _NavBtn(
                label: 'Ecosystem',
                icon: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    index == 1
                        ? const Color(0xFFFF6B2C)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFB0B0B0) // Light grey for dark mode
                            : const Color(0xFF6B7280)), // Dark grey for light mode
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'lib/icons/ecosystem_application.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
                active: index == 1,
                onTap: () => onTap(1),
                iconSize: 22,
              ),
              _AddNavBtn(onTap: onAdd),
              _NavBtn(
                label: 'Business.AI',
                icon: const Icon(Icons.auto_awesome, size: 22),
                active: index == 2,
                onTap: () => onTap(2),
                iconSize: 22,
              ),
              ValueListenableBuilder<int>(
                valueListenable: DmUnreadController.instance.unread,
                builder: (context, unread, _) => _NavBtn(
                  label: 'Chat',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 22),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B2C),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Text(
                              unread > 99 ? '99+' : unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  active: index == 3,
                  onTap: () => onTap(3),
                  iconSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNavBtn extends StatelessWidget {
  const _AddNavBtn({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B2C), Color(0xFFFF8C42)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B2C).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap,
      this.iconSize = 24});
  final String label;
  final Widget icon;
  final bool active;
  final VoidCallback onTap;
  final double iconSize;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: active
                    ? const Color.fromARGB(255, 255, 107, 44).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: IconTheme(
                  data: IconThemeData(
                    color: active
                        ? const Color(0xFFFF6B2C)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFB0B0B0) // Light grey for dark mode
                            : const Color(0xFF6B7280)), // Dark grey for light mode
                    size: iconSize,
                  ),
                  child: icon,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1.0,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active 
                    ? const Color(0xFFFF6B2C) 
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB0B0B0) // Light grey for dark mode
                        : const Color(0xFF6B7280)), // Dark grey for light mode
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
