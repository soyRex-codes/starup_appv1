import 'package:flutter/material.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/app/widgets/app_menu_drawer.dart';
import 'package:foundervers/features/notifications/notifications.dart';
import 'package:foundervers/services/notification_service.dart';
import 'package:foundervers/widgets/terai_logo.dart';

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
    this.onCreatePost,
  });
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final String? filterSummary;
  final VoidCallback? onProfileTap;
  final Widget? profileAvatar;
  final ValueChanged<bool>? onSearchFocusChanged;
  final VoidCallback? onCreatePost;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _mobileSearch = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchText)
      ..addListener(_rebuild);
    _focusNode = FocusNode()..addListener(_focusChanged);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _focusChanged() =>
      widget.onSearchFocusChanged?.call(_focusNode.hasFocus);

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchText != _controller.text) {
      _controller.text = widget.searchText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _focusNode.removeListener(_focusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onClearSearch();
  }

  void _openMenu() {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      pageBuilder: (_, __, ___) => const _MenuPageWrapper(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= TeraiBreakpoints.mobile;
      return Container(
        color: theme.colorScheme.surface,
        padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 10, wide ? 24 : 14,
            widget.hasActiveFilters ? 10 : 12),
        child: Column(children: [
          Row(children: [
            if (!wide && !_mobileSearch) ...[
              const TeraiLogo(width: 102, height: 40),
              const Spacer(),
            ],
            if (wide) ...[
              Text('Discover', style: theme.textTheme.titleLarge),
              const SizedBox(width: 28),
              Expanded(
                  child: _SearchField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: widget.onSearchChanged,
                      onClear: _clear)),
              const SizedBox(width: 10),
            ] else if (_mobileSearch) ...[
              IconButton(
                  onPressed: () {
                    _focusNode.unfocus();
                    setState(() => _mobileSearch = false);
                  },
                  icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 4),
              Expanded(
                  child: _SearchField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: widget.onSearchChanged,
                      onClear: _clear)),
              const SizedBox(width: 4),
            ] else
              _HeaderAction(
                  icon: Icons.search_rounded,
                  tooltip: 'Search',
                  onTap: () {
                    setState(() => _mobileSearch = true);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _focusNode.requestFocus());
                  }),
            if (wide || !_mobileSearch) ...[
              if (widget.onCreatePost != null) ...[
                const SizedBox(width: 4),
                if (constraints.maxWidth >= 900)
                  FilledButton.icon(
                    onPressed: widget.onCreatePost,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create post'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  )
                else
                  IconButton.filled(
                    onPressed: widget.onCreatePost,
                    tooltip: 'Create post',
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
              _HeaderAction(
                icon: Icons.tune_rounded,
                tooltip: 'Filter',
                active: widget.hasActiveFilters,
                onTap: widget.onFilterTap,
              ),
              _NotificationAction(),
              _HeaderAction(
                  icon: Icons.menu_rounded, tooltip: 'Menu', onTap: _openMenu),
            ],
          ]),
          if (widget.hasActiveFilters && widget.filterSummary != null) ...[
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.filter_alt_rounded, size: 15),
                label: Text(widget.filterSummary!),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: widget.onFilterTap,
              ),
            ),
          ],
        ]),
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.controller,
      required this.focusNode,
      required this.onChanged,
      required this.onClear});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search people, ideas and problems',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18)),
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.icon,
      required this.tooltip,
      this.onTap,
      this.active = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          style: active
              ? IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  foregroundColor: Theme.of(context).colorScheme.primary)
              : null,
          icon: Icon(icon, size: 21),
        ),
      );
}

class _NotificationAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: NotificationService.instance.unreadCountStream,
        initialData: NotificationService.instance.unreadCount,
        builder: (_, snapshot) {
          final unread = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: _HeaderAction(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage())),
            ),
          );
        },
      );
}

class _MenuPageWrapper extends StatefulWidget {
  const _MenuPageWrapper();
  @override
  State<_MenuPageWrapper> createState() => _MenuPageWrapperState();
}

class _MenuPageWrapperState extends State<_MenuPageWrapper> {
  late final DateTime _openedAt = DateTime.now();
  void _handleTapOutside() {
    if (DateTime.now().difference(_openedAt).inMilliseconds > 500) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return TapRegion(
      onTapOutside: (_) => _handleTapOutside(),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
            width: width > 600 ? 340 : width * 0.86,
            child: const Material(elevation: 16, child: AppMenuDrawer())),
      ),
    );
  }
}
