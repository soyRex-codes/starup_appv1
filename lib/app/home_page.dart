import 'package:flutter/material.dart';
import 'package:foundervers/features/feed/feed_page.dart';
// Replaced legacy InboxPage with new optimized messaging inbox
import 'package:foundervers/features/dm/new_inbox_page.dart';
import 'package:foundervers/features/dm/dm_unread_controller.dart';
import 'package:foundervers/features/Global_public_chat-for_founders/global_chat_page.dart';
import 'package:foundervers/features/ecosystem/ecosystem_application_page.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/core/cache/feed_cache.dart';

import '../features/post_creation/post_creation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final GlobalKey<FeedPageState> _feedPageKey = GlobalKey<FeedPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedPage(key: _feedPageKey),
      const EcosystemApplicationPage(),
      const GlobalChatPage(),
      const NewInboxPage(),
    ];
    // Initialize unread controller once user is available (Firebase auth already initialized earlier in app start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DmUnreadController.instance.ensureStarted();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: _NavBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
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
        color: AppColors.bg, // Use theme background
        border: Border(
            top: BorderSide(color: AppColors.border)), // Use theme border
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              Expanded(
                  child: _NavBtn(
                      label: 'Feed',
                      icon: AppIcons.feed(size: 24),
                      active: index == 0,
                      onTap: () => onTap(0))),
              // Ecosystem now in position 2
              Expanded(
                  child: _NavBtn(
                      label: 'Ecosystem',
                      icon: Image.asset(
                        'lib/icons/ecosystem_application.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      active: index == 1,
                      onTap: () => onTap(1))),
              // Create button in the middle
              _AddNavBtn(onTap: onAdd),
              // Global Chat tab
              Expanded(
                  child: _NavBtn(
                      label: 'Global',
                      icon: AppIcons.globalChat(size: 24),
                      active: index == 2,
                      onTap: () => onTap(2))),
              // DMs with unread badge listener now in position 5
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: DmUnreadController.instance.unread,
                  builder: (context, unread, _) => _NavBtn(
                    label: 'DMs',
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AppIcons.dms(size: 24),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors
                                    .primary, // Use orange for unread badge
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : unread.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                    active: index == 3,
                    onTap: () => onTap(3),
                  ),
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
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(child: AppIcons.post(size: 24))),
              const SizedBox(height: 0),
              const Text('Create',
                  style: TextStyle(
                      fontSize: 9.0, fontWeight: FontWeight.w600, height: 1.0)),
            ],
          ),
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
      required this.onTap});
  final String label;
  final Widget icon;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.primarySoft
        : Colors.transparent; // Use orange tint for active state
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  SizedBox(width: 24, height: 24, child: Center(child: icon)),
            ),
            const SizedBox(height: 0),
            Text(label, style: const TextStyle(fontSize: 8.5, height: 1.0)),
          ],
        ),
      ),
    );
  }
}
