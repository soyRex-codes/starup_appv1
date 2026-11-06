import 'package:flutter/material.dart';
import 'package:foundervers/features/dm/new_inbox_page.dart';
import 'package:foundervers/features/suggestions/suggestions_inbox.dart';

/// Chat page for private messages and user suggestions.
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
    // Initialize with 2 tabs, using the last selected index.
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _lastSelectedIndex > 1 ? 0 : _lastSelectedIndex,
    );

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
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Messages',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                                'Continue conversations and exchange useful feedback.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Theme.of(context).dividerColor)),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(
                            height: 44,
                            icon: Icon(Icons.inbox_outlined, size: 18),
                            text: 'Direct messages'),
                        Tab(
                            height: 44,
                            icon:
                                Icon(Icons.lightbulb_outline_rounded, size: 18),
                            text: 'Product Feedback'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [NewInboxPage(), SuggestionsInbox()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
