import 'package:flutter/material.dart';
import 'package:foundervers/features/dm/new_inbox_page.dart';
import 'package:foundervers/features/Global_public_chat-for_founders/global_chat_page.dart';
import 'package:foundervers/features/suggestions/suggestions_inbox.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Compact tab bar directly at top (SafeArea handles status bar)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
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
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text("DM's"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18),
                        const SizedBox(width: 6),
                        Text('Suggestions'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 46,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public, size: 18),
                        const SizedBox(width: 6),
                        Text('Global Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: TabBarView(
                controller: _tabController,
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
