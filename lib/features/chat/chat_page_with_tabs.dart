import 'package:flutter/material.dart';
import 'package:foundervers/features/dm/new_inbox_page.dart';
import 'package:foundervers/features/Global_public_chat-for_founders/global_chat_page.dart';
import 'package:foundervers/features/suggestions/suggestions_inbox.dart';
import 'package:foundervers/services/premium_subscription_service.dart';
import 'package:foundervers/widgets/premium_upgrade_dialog.dart';

/// Chat Page with Tabs for Inbox and Global Chat
class ChatPageWithTabs extends StatefulWidget {
  const ChatPageWithTabs({super.key});

  @override
  State<ChatPageWithTabs> createState() => _ChatPageWithTabsState();
}

class _ChatPageWithTabsState extends State<ChatPageWithTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 tabs, starting at index 0 (Inbox)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // Add listener to check premium status when switching to Global Chat
    _tabController.addListener(() {
      _handleTabChange();
    });
  }

  Future<void> _handleTabChange() async {
    // Check if trying to access Global Chat (index 2)
    if (_tabController.index == 2) {
      final isPremium = await PremiumSubscriptionService().checkPremiumStatus();
      if (!isPremium && mounted) {
        // Switch back to previous tab
        final previousIndex = _tabController.previousIndex;
        _tabController.animateTo(previousIndex);

        // Show premium dialog
        await PremiumUpgradeDialog.show(
          context,
          featureName: 'Global Chat',
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Compact tab bar directly at top (SafeArea handles status bar)
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF8B4513),
                indicatorWeight: 2.5,
                labelColor: const Color(0xFF8B4513),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13, // Reduced from 14
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13, // Reduced from 14
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4), // Reduced from 8
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 16), // Reduced from 18
                        const SizedBox(width: 4), // Reduced from 6
                        Text("DM's"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16), // Reduced from 18
                        const SizedBox(width: 4), // Reduced from 6
                        Text('Suggestions'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 16), // Reduced from 18
                        const SizedBox(width: 4), // Reduced from 6
                        Text('Global Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content area - Disable swiping to prevent bypassing premium check
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swiping
                children: const [
                  // Inbox Tab - Personal DMs
                  NewInboxPage(),

                  // Suggestions Tab - User suggestions
                  SuggestionsInbox(),

                  // Global Tab - Global Chat
                  GlobalChatPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
