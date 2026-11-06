import 'package:flutter/material.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/core/cache/feed_cache.dart';
import 'package:foundervers/features/chat/chat_page_with_tabs.dart';
import 'package:foundervers/features/dm/dm_unread_controller.dart';
import 'package:foundervers/features/ecosystem/ecosystem_application_page.dart';
import 'package:foundervers/features/feed/feed_page.dart';
import 'package:foundervers/features/post_creation/post_creation_page.dart';
import 'package:foundervers/services/deep_link_service.dart';
import 'package:foundervers/services/supa.dart';
import 'package:foundervers/core/storage_utils.dart';
import 'package:foundervers/features/profile/unified_profile_page.dart';
import 'package:foundervers/widgets/terai_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final GlobalKey<FeedPageState> _feedPageKey = GlobalKey<FeedPageState>();
  bool _deepLinksInitialized = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedPage(key: _feedPageKey, onCreatePost: _createPost),
      const EcosystemApplicationPage(),
      const ChatPageWithTabs(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DmUnreadController.instance.ensureStarted();
      if (!_deepLinksInitialized) {
        DeepLinkService.initialize(context);
        _deepLinksInitialized = true;
      }
    });
  }

  void _selectPage(int index) => setState(() => _index = index);

  Future<void> _createPost() async {
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PostCreationPage()),
    );
    if (created == true && mounted) {
      FeedCache.instance.clear();
      setState(() => _index = 0);
      _feedPageKey.currentState?.refreshAfterPostCreation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width >= TeraiBreakpoints.desktop) {
        return _WideShell(
          index: _index,
          page: _pages[_index],
          onSelect: _selectPage,
          onCreate: _createPost,
        );
      }
      if (width >= TeraiBreakpoints.mobile) {
        return _RailShell(
          index: _index,
          page: _pages[_index],
          onSelect: _selectPage,
        );
      }
      return _MobileShell(
        index: _index,
        page: _pages[_index],
        onSelect: _selectPage,
        onCreate: _createPost,
      );
    });
  }
}

class _WideShell extends StatelessWidget {
  const _WideShell(
      {required this.index,
      required this.page,
      required this.onSelect,
      required this.onCreate});
  final int index;
  final Widget page;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Container(
          width: 244,
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: TeraiLogo(width: 118, height: 48)),
                    ),
                    const SizedBox(height: 28),
                    _SideDestination(
                        icon: Icons.home_rounded,
                        label: 'Discover',
                        selected: index == 0,
                        onTap: () => onSelect(0)),
                    _SideDestination(
                        icon: Icons.grid_view_rounded,
                        label: 'Ecosystem',
                        selected: index == 1,
                        onTap: () => onSelect(1)),
                    ValueListenableBuilder<int>(
                      valueListenable: DmUnreadController.instance.unread,
                      builder: (_, unread, __) => _SideDestination(
                          icon: Icons.forum_rounded,
                          label: 'Messages',
                          badge: unread,
                          selected: index == 2,
                          onTap: () => onSelect(2)),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create post')),
                    const SizedBox(height: 12),
                    _SideDestination(
                      icon: Icons.account_circle_outlined,
                      label: 'Profile',
                      selected: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UnifiedProfilePage(),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Ideas grow better together.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ]),
            ),
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          child: Row(children: [
            Expanded(child: _AnimatedPage(index: index, child: page)),
            if (index == 0) ...[
              VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
              const SizedBox(width: 316, child: _DiscoverRail()),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell(
      {required this.index, required this.page, required this.onSelect});
  final int index;
  final Widget page;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        SafeArea(
          child: NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (destination) {
              if (destination == 3) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const UnifiedProfilePage(),
                ));
              } else {
                onSelect(destination);
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              // Create post is kept in the feed header at tablet widths so it
              // remains aligned with the content instead of floating above
              // the navigation destinations.
              padding: const EdgeInsets.only(bottom: 8),
              child: const SizedBox(height: 8),
            ),
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: Text('Discover')),
              NavigationRailDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: Text('Ecosystem')),
              NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: Text('Messages')),
              NavigationRailDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: Text('Profile')),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(child: _AnimatedPage(index: index, child: page)),
      ]),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell(
      {required this.index,
      required this.page,
      required this.onSelect,
      required this.onCreate});
  final int index;
  final Widget page;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedPage(index: index, child: page),
      floatingActionButton: FloatingActionButton.small(
          onPressed: onCreate,
          tooltip: 'Create post',
          child: const Icon(Icons.add_rounded)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4))
          ],
        ),
        child: BottomAppBar(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: Row(children: [
            Expanded(
              child: _MobileNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                selected: index == 0,
                onTap: () => onSelect(0),
              ),
            ),
            Expanded(
              child: _MobileNavItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'Ecosystem',
                selected: index == 1,
                onTap: () => onSelect(1),
              ),
            ),
            const SizedBox(width: 62),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: DmUnreadController.instance.unread,
                builder: (_, unread, __) => _MobileNavItem(
                  icon: Icons.forum_outlined,
                  selectedIcon: Icons.forum_rounded,
                  label: 'Messages',
                  badge: unread,
                  selected: index == 2,
                  onTap: () => onSelect(2),
                ),
              ),
            ),
            Expanded(
              child: _MobileNavItem(
                icon: Icons.account_circle_outlined,
                selectedIcon: Icons.account_circle_rounded,
                label: 'Profile',
                selected: false,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const UnifiedProfilePage(),
                )),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Badge(
          isLabelVisible: badge > 0,
          label: Text(badge > 99 ? '99+' : '$badge'),
          child: Icon(selected ? selectedIcon : icon, color: color, size: 23),
        ),
        const SizedBox(height: 3),
        Text(label,
            maxLines: 1,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}

class _AnimatedPage extends StatelessWidget {
  const _AnimatedPage({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(index), child: child),
      );
}

class _SideDestination extends StatelessWidget {
  const _SideDestination(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      this.badge = 0});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Icon(icon,
                  size: 22,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color),
              const SizedBox(width: 13),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? theme.colorScheme.primary : null))),
              if (badge > 0) Badge(label: Text(badge > 99 ? '99+' : '$badge')),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DiscoverRail extends StatefulWidget {
  const _DiscoverRail();

  @override
  State<_DiscoverRail> createState() => _DiscoverRailState();
}

class _DiscoverRailState extends State<_DiscoverRail> {
  late final Future<List<Map<String, dynamic>>> _people = _loadPeople();

  Future<List<Map<String, dynamic>>> _loadPeople() async {
    final currentUserId = Supa.client.auth.currentUser?.id;
    var query = Supa.client
        .from('users')
        .select('id,name,full_name,username,avatar_url');
    if (currentUserId != null) query = query.neq('id', currentUserId);
    final response = await query.limit(5);
    return (response as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          children: [
            Row(children: [
              Expanded(
                child: Text('People to discover',
                    style: theme.textTheme.titleMedium),
              ),
              Icon(Icons.people_alt_outlined,
                  size: 19, color: theme.textTheme.bodySmall?.color),
            ]),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _people,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final people = snapshot.data ?? const [];
                if (people.isEmpty) {
                  return Text('New people will appear here.',
                      style: theme.textTheme.bodySmall);
                }
                return Column(
                  children: people
                      .map((person) => _PersonSuggestion(person: person))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Better matches start with context',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 7),
                    Text(
                      'Share the problem you are solving and the kind of partner you need.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonSuggestion extends StatelessWidget {
  const _PersonSuggestion({required this.person});
  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context) {
    final name = (person['full_name'] ??
            person['name'] ??
            person['username'] ??
            'Terai member')
        .toString();
    final username = (person['username'] ?? '').toString();
    final avatar =
        StorageUtils.resolvePublicUrl(person['avatar_url'] as String?);
    final initial = name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase();
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UnifiedProfilePage(
          userId: person['id']?.toString(),
          userName: name,
        ),
      )),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(initial,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (username.isNotEmpty)
                Text('@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
        ]),
      ),
    );
  }
}
