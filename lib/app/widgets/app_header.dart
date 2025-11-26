import 'package:flutter/material.dart';
import 'package:foundervers/features/notifications/notifications.dart';
import 'package:foundervers/widgets/foundervers_logo.dart';
import 'package:foundervers/services/notification_service.dart';

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
    this.onSearchFocusChanged,
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
  final ValueChanged<bool>?
      onSearchFocusChanged; // notify parent about focus state

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchText);
    _searchFocusNode = FocusNode();

    // Listen to text changes to rebuild for clear button visibility
    _searchController.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });

    // Auto-collapse when search loses focus and text is empty
    _searchFocusNode.addListener(() {
      final isFocused = _searchFocusNode.hasFocus;
      if (!isFocused && _searchController.text.isEmpty && _isSearchExpanded) {
        setState(() {
          _isSearchExpanded = false;
        });
      }
      widget.onSearchFocusChanged?.call(isFocused);
    });
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != oldWidget.searchText &&
        widget.searchText != _searchController.text) {
      _searchController.text = widget.searchText;
    }
  }

  void _expandSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
    // Auto-focus keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _collapseSearch() {
    setState(() {
      _isSearchExpanded = false;
    });
    _searchFocusNode.unfocus();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      widget.onClearSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSearchExpanded
              ? _buildExpandedHeader()
              : _buildCollapsedHeader(),
        ),

        // Active filter chips below header
        if (widget.hasActiveFilters && widget.filterSummary != null) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
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
                        widget.filterSummary!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onClearSearch,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  // Collapsed state: Logo + Search icon + Filter + Menu + Bell
  Widget _buildCollapsedHeader() {
    return Row(
      key: const ValueKey('collapsed'),
      children: [
        // Logo
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: const FounderVersLogo(
            width: 40,
            height: 40,
          ),
        ),
        const Spacer(),

        // Search icon button
        IconButton(
          onPressed: _expandSearch,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: const EdgeInsets.all(4),
          icon: const Icon(
            Icons.search,
            size: 24,
          ),
        ),

        // Filter icon with badge
        if (widget.onFilterTap != null)
          IconButton(
            onPressed: widget.onFilterTap,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: const EdgeInsets.all(4),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 24,
                  color: widget.hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                if (widget.hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Menu button
        IconButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: const EdgeInsets.all(4),
          icon: const Icon(
            Icons.menu,
            size: 24,
          ),
        ),

        // Notification icon with badge
        const SizedBox(width: 4),
        StreamBuilder<int>(
          stream: NotificationService.instance.unreadCountStream,
          initialData: NotificationService.instance.unreadCount,
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotificationsPage()));
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 24,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Expanded state: Back arrow + Full-width search input + Clear button
  Widget _buildExpandedHeader() {
    return Row(
      key: const ValueKey('expanded'),
      children: [
        // Back arrow to collapse
        IconButton(
          onPressed: _collapseSearch,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: const EdgeInsets.all(4),
          icon: Icon(
            Icons.arrow_back,
            size: 24,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(width: 8),

        // Full-width search input
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: widget.onSearchChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search startups, founders, ideas...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 22,
                  color: Colors.grey[600],
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onClearSearch();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
