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
  
  // Static variable to persist selected tab across rebuilds
  static int _lastSelectedIndex = 0;
  
  // Debounce to fix iPadOS 26 double-tap bug (Flutter issue #177992)
  DateTime? _lastTabChangeTime;
  int? _lastIntentionalIndex;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 tabs, using the last selected index
    _tabController = TabController(length: 3, vsync: this, initialIndex: _lastSelectedIndex);
    
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final newIndex = _tabController.index;
    final now = DateTime.now();
    
    // iPadOS 26 workaround: If we just changed to a non-zero tab and immediately
    // get a change to 0, this is the double-tap bug - ignore it
    if (newIndex == 0 && 
        _lastIntentionalIndex != null && 
        _lastIntentionalIndex != 0 &&
        _lastTabChangeTime != null &&
        now.difference(_lastTabChangeTime!).inMilliseconds < 500) {
      // Restore the intentional index
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lastIntentionalIndex != null) {
          _tabController.animateTo(_lastIntentionalIndex!);
        }
      });
      return;
    }
    
    // This is a legitimate tab change
    _lastTabChangeTime = now;
    _lastIntentionalIndex = newIndex;
    _lastSelectedIndex = newIndex;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
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

                  // Global Tab - Global Chat (Premium Locked)
                  _GlobalChatTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalChatTab extends StatefulWidget {
  const _GlobalChatTab();

  @override
  State<_GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<_GlobalChatTab> {
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_isPremium == true) {
      return const GlobalChatPage();
    }

    return Center(
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
              'Global Chat is Locked',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connect with founders worldwide! This is a premium feature exclusive to our members.',
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
                    featureName: 'Global Chat',
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
    );
  }
}
