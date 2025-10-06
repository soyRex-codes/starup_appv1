import 'package:flutter/material.dart';
import 'package:foundervers/app/app_icons.dart';
import 'package:foundervers/features/profile/profile_page.dart';
import 'package:foundervers/features/suggestions/suggestions_inbox.dart';
import 'package:foundervers/features/about/about_us_page.dart';
import 'package:foundervers/features/settings/settings_page.dart';
import 'package:foundervers/features/help_support/help_support_page.dart';
import 'package:foundervers/features/notifications/notifications.dart';
import 'package:foundervers/features/admin/admin_dashboard.dart';
import 'package:foundervers/features/admin/services/admin_auth_service.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';

/// Reusable sticky style header combining logo, search bar, category menu & goal chips.
class AppHeader extends StatefulWidget {
  const AppHeader({
    super.key,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.filterSummary,
    this.onProfileTap,
    this.profileAvatar,
  });

  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onFilterTap; // unified filter button
  final bool hasActiveFilters; // show indicator if filters are active
  final String?
      filterSummary; // summary of active filters (e.g., "Technology + Funding")
  final VoidCallback?
      onProfileTap; // optional profile button action (appears at right side)
  final Widget? profileAvatar; // optional custom avatar widget

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  bool _isSearchExpanded = false;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchText);
    _searchFocusNode = FocusNode();

    // Listen for focus changes to auto-collapse when focus is lost
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _searchController.text) {
      _searchController.text = widget.searchText;
    }
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _isSearchExpanded = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchFocusNode.unfocus();
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          widget.onClearSearch();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main header row
            Row(children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearchExpanded
                      ? const SizedBox
                          .shrink() // Hide branding when search is expanded
                      : Row(
                          key: const ValueKey('branding'),
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: const FounderVersLogo(
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // Search icon/button
              Container(
                decoration: BoxDecoration(
                  color: _isSearchExpanded
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _toggleSearch,
                  tooltip: _isSearchExpanded ? 'Close search' : 'Search posts',
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: const EdgeInsets.all(6),
                  icon: _isSearchExpanded
                      ? Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        )
                      : ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                          child: AppIcons.search(size: 22),
                        ),
                ),
              ),
              if (widget.onFilterTap != null && !_isSearchExpanded) ...[
                const SizedBox(width: 4),
                _UnifiedFilterButton(
                  onTap: widget.onFilterTap!,
                  hasActiveFilters: widget.hasActiveFilters,
                  summary: widget.filterSummary,
                ),
                // Menu button - positioned after filter button
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _MenuAction(
                                    icon: AppIcons.profile(size: 22),
                                    label: 'Profile & Account',
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(ctx).push(MaterialPageRoute(
                                          builder: (_) => const ProfilePage()));
                                    }),
                                const SizedBox(height: 8),
                                _MenuAction(
                                    icon: AppIcons.suggest(size: 22),
                                    label: 'Suggestions Inbox',
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(ctx).push(MaterialPageRoute(
                                          builder: (_) =>
                                              const SuggestionsInbox()));
                                    }),
                                // Admin Dashboard - only for admins
                                FutureBuilder<bool>(
                                  future: AdminAuthService.isCurrentUserAdmin(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data == true) {
                                      return Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          _MenuAction(
                                            icon: const Icon(
                                              Icons.admin_panel_settings,
                                              size: 22,
                                              color: Color(0xFFFF5722),
                                            ),
                                            label: 'Admin Dashboard',
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              Navigator.of(ctx).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const AdminDashboard(),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          const Divider(height: 8),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                const SizedBox(height: 8),
                                _MenuAction(
                                    icon: AppIcons.about(size: 22),
                                    label: 'About FounderVers',
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(ctx).push(MaterialPageRoute(
                                          builder: (_) => const AboutUsPage()));
                                    }),
                                const SizedBox(height: 8),
                                const Divider(height: 16),
                                _MenuAction(
                                    icon: AppIcons.settings(size: 22),
                                    label: 'Settings',
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(ctx).push(MaterialPageRoute(
                                          builder: (_) =>
                                              const SettingsPage()));
                                    }),
                                const SizedBox(height: 8),
                                _MenuAction(
                                    icon: AppIcons.help(size: 22),
                                    label: 'Help & Support',
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      Navigator.of(ctx).push(MaterialPageRoute(
                                          builder: (_) =>
                                              const HelpSupportPage()));
                                    }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(0, 211, 119, 93),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AppIcons.menu(size: 20),
                  ),
                ),
                // Notification icon (simple, lightweight)
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const NotificationsPage()));
                    },
                    child: Image.asset(
                      'lib/icons/notification.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
              if (widget.onProfileTap != null && !_isSearchExpanded) ...[
                const SizedBox(width: 10),
                _ProfileButton(
                    onTap: widget.onProfileTap!, avatar: widget.profileAvatar),
              ],
            ]),

            // Expandable search field
            if (_isSearchExpanded) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    hintText: 'Search posts...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 6),
                      child: AppIcons.search(size: 18),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: AppIcons.delete(size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.onClearSearch();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Optional filter summary row when active
        if (widget.hasActiveFilters &&
            widget.filterSummary != null &&
            !_isSearchExpanded) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Filtered by: ${widget.filterSummary}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

class _UnifiedFilterButton extends StatelessWidget {
  const _UnifiedFilterButton({
    required this.onTap,
    required this.hasActiveFilters,
    this.summary,
  });

  final VoidCallback onTap;
  final bool hasActiveFilters;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: hasActiveFilters
              ? Theme.of(context).colorScheme.primaryContainer
              : const Color(0xFFF2EEF9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActiveFilters
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFD3CCE8),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600]!,
                BlendMode.srcIn,
              ),
              child: AppIcons.filter(size: 20),
            ),
            if (hasActiveFilters)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap, this.avatar});
  final VoidCallback onTap;
  final Widget? avatar;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: avatar ??
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EEF9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0DAF0)),
            ),
            child: const Icon(Icons.person, size: 20, color: Colors.black54),
          ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction(
      {required this.icon, required this.label, required this.onTap});
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 28, height: 28, child: Center(child: icon)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500))),
            const SizedBox(width: 20), // Spacer for alignment
          ],
        ),
      ),
    );
  }
}
