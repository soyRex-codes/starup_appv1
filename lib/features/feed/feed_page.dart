import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/core/visibility.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/features/feed/feed_history_service.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/models/post_age.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/app/widgets/filter_sheet.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:foundervers/features/onboarding/feed_onboarding_overlay.dart';
import 'package:foundervers/app/widgets/app_menu_drawer.dart';
import 'package:foundervers/services/user_blocking_service.dart';
import 'package:foundervers/app/widgets/error_state_widget.dart';

import '../../app/theme.dart';
import '../../app/widgets/app_header.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.onNavVisibilityChanged});

  final ValueChanged<bool>? onNavVisibilityChanged;

  @override
  FeedPageState createState() => FeedPageState();
}

class FeedPageState extends State<FeedPage> {
  final _svc = FeedService();
  final _me = Supabase.instance.client.auth.currentUser;
  final int _limit = 20;
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final List<PostModel> _posts = [];
  List<String> _categoryFilters = []; // empty = All
  String _search = '';
  List<String> _goalFilters = []; // empty = all goals
  PostAge _dateRangeFilter = PostAge.all; // Date range filter
  final _scrollCtrl = ScrollController();
  Timer? _searchTimer; // Debounce timer for search
  Timer? _hideNavTimer; // Debounce timer for nav hide/show
  bool _showOnboarding = false;

  // Auto-hide navigation state
  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  final double _scrollThreshold =
      50; // Minimum scroll distance to trigger hide/show
  bool _isSearchBarFocused = false;

  // Background refresh state
  Timer? _backgroundRefreshTimer;
  StreamSubscription? _blockSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _checkOnboarding();
    _setupScrollListener();
    
    // Listen for block/unblock events to auto-refresh feed
    _blockSubscription = UserBlockingService().onBlockStateChanged.listen((_) {
      if (mounted) {
        _load(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _blockSubscription?.cancel();
    _scrollCtrl.dispose();
    _searchTimer?.cancel();
    _hideNavTimer?.cancel();
    _backgroundRefreshTimer?.cancel();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollCtrl.addListener(() {
      final currentOffset = _scrollCtrl.offset;
      final difference = currentOffset - _lastScrollOffset;

      if (_isSearchBarFocused) {
        _lastScrollOffset = currentOffset;
        return;
      }

      // Only trigger if scrolled more than threshold
      if (difference.abs() > _scrollThreshold) {
        // Cancel any pending nav visibility changes
        _hideNavTimer?.cancel();

        // Debounce the hide/show to prevent jittery behavior
        _hideNavTimer = Timer(const Duration(milliseconds: 100), () {
          if (difference > 0 && _isHeaderVisible) {
            // Scrolling down - hide header/nav
            setState(() => _isHeaderVisible = false);
            widget.onNavVisibilityChanged?.call(false);
          } else if (difference < 0 && !_isHeaderVisible) {
            // Scrolling up - show header/nav
            setState(() => _isHeaderVisible = true);
            widget.onNavVisibilityChanged?.call(true);
          }
        });
        _lastScrollOffset = currentOffset;
      }

      // Always show at top
      if (currentOffset <= 0 && !_isHeaderVisible) {
        _hideNavTimer?.cancel();
        setState(() => _isHeaderVisible = true);
        widget.onNavVisibilityChanged?.call(true);
      }

      // Pagination logic (existing)
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          !_loading) {
        _load();
      }
    });
  }

  Future<void> _checkOnboarding() async {
    final completed = await FeedOnboardingOverlay.hasCompletedOnboarding();
    if (!completed && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  /// Public method to refresh the feed (called when new posts are created)
  Future<void> refreshAfterPostCreation() async {
    await _refreshFeed();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _offset = 0;
        _posts.clear();
      });
    }
    setState(() {
      _error = null;
      _loading = _posts.isEmpty;
      _loadingMore = _posts.isNotEmpty;
    });

    bool shouldScheduleBackgroundRefresh = false;

    try {
      final newPosts = await _svc.fetchPosts(
        categories: _categoryFilters,
        goals: _goalFilters,
        search: _search.trim().isNotEmpty ? _search.trim() : null,
        dateRange: _dateRangeFilter.value,
        limit: _limit,
        offset: _offset,
        onCacheCheck: (needsRefresh) {
          // Schedule background refresh if cache is stale (>3 min old)
          if (needsRefresh && _posts.isEmpty) {
            shouldScheduleBackgroundRefresh = true;
          }
        },
      );
      final filtered = newPosts
          .where((p) => VisibilityRules.canSeePost(
              post: _postToVisMap(p), me: _me, admins: AppEnv.adminEmails))
          .toList();
      setState(() {
        _posts.addAll(filtered);
        _offset += _limit;
      });

      // Mark posts as seen for Smart Feed algorithm
      if (filtered.isNotEmpty) {
        FeedHistoryService.instance.markAsSeen(filtered.map((p) => p.id).toList());
      }

      // Schedule background refresh if cache was stale
      if (shouldScheduleBackgroundRefresh) {
        _scheduleBackgroundRefresh();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  /// Schedule a background refresh without showing loading indicator
  void _scheduleBackgroundRefresh() {
    // Cancel any existing timer
    _backgroundRefreshTimer?.cancel();

    // Wait 500ms before triggering (to avoid rapid re-renders)
    _backgroundRefreshTimer = Timer(const Duration(milliseconds: 500), () {
      _performBackgroundRefresh();
    });
  }

  /// Perform background refresh silently
  Future<void> _performBackgroundRefresh() async {
    if (!mounted) return;

    try {
      // Fetch fresh data silently (no loading indicator)
      final newPosts = await _svc.fetchPosts(
        categories: _categoryFilters,
        goals: _goalFilters,
        search: _search.trim().isNotEmpty ? _search.trim() : null,
        dateRange: _dateRangeFilter.value,
        limit: _limit,
        offset: 0, // First page only
        silentRefresh: true, // This tells the service to update cache silently
      );

      final filtered = newPosts
          .where((p) => VisibilityRules.canSeePost(
              post: _postToVisMap(p), me: _me, admins: AppEnv.adminEmails))
          .toList();

      if (mounted && filtered.isNotEmpty) {
        // Smoothly update UI with fresh data
        setState(() {
          // Replace first page with fresh data
          if (_posts.length >= filtered.length) {
            _posts.replaceRange(0, filtered.length, filtered);
          } else {
            _posts
              ..clear()
              ..addAll(filtered);
            _offset = _limit;
          }
        });
      }
    } catch (e) {
      // Silent failure - don't show error to user during background refresh
      debugPrint('Background refresh failed: $e');
    }
  }

  Map<String, dynamic> _postToVisMap(PostModel p) {
    return {
      'user_id': p.userId,
      'moderation_status': p.moderationStatus,
      'status': p.status,
    };
  }

  Future<void> _openFilterSheet() async {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Map<String, dynamic>? result;

    if (isTablet) {
      // Show as a Dialog on tablets (iPad)
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FilterSheet(
                initialCategories: _categoryFilters,
                initialGoals: _goalFilters,
                initialDateRange: _dateRangeFilter,
              ),
            ),
          ),
        ),
      );
    } else {
      // Show as BottomSheet on phones
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FilterSheet(
          initialCategories: _categoryFilters,
          initialGoals: _goalFilters,
          initialDateRange: _dateRangeFilter,
        ),
      );
    }

    if (result != null) {
      setState(() {
        _categoryFilters = List<String>.from(result!['categories'] ?? []);
        _goalFilters = List<String>.from(result['goals'] ?? []);
        _dateRangeFilter = PostAge.fromValue(result['dateRange'] ?? 'all');
      });
      _load(reset: true);
    }
  }

  String _getFilterSummary() {
    final parts = <String>[];
    if (_categoryFilters.isNotEmpty) {
      parts.add(_categoryFilters.length == 1
          ? _formatCategoryLabel(_categoryFilters.first)
          : 'Categories (${_categoryFilters.length})');
    }
    if (_goalFilters.isNotEmpty) {
      parts.add(_goalFilters.length == 1
          ? _formatGoalLabel(_goalFilters.first)
          : 'Goals (${_goalFilters.length})');
    }
    if (_dateRangeFilter != PostAge.all) {
      parts.add(_dateRangeFilter.label);
    }
    return parts.join(' + ');
  }

  String _formatCategoryLabel(String category) {
    switch (category) {
      case 'technology':
        return 'Technology';
      case 'healthcare':
        return 'Healthcare';
      case 'finance':
        return 'Finance';
      case 'education':
        return 'Education';
      case 'entertainment':
        return 'Entertainment';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }

  String _formatGoalLabel(String goal) {
    switch (goal) {
      case 'funding':
        return 'Funding';
      case 'team':
        return 'Team';
      case 'skills':
        return 'Skills';
      case 'partnership':
        return 'Partnership';
      case 'mentorship':
        return 'Mentorship';
      case 'feedback':
        return 'Feedback';
      case 'other':
        return 'Other Goals';
      default:
        return goal;
    }
  }



  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchTimer?.cancel();

    // Set the search text immediately for UI feedback
    setState(() => _search = query);

    // Debounce the actual search API call
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _load(reset: true);
      }
    });
  }

  void _onClearSearch() {
    _searchTimer?.cancel();
    setState(() => _search = '');
    _load(reset: true);
  }

  void _handleSearchFocusChanged(bool isFocused) {
    if (_isSearchBarFocused == isFocused) return;
    setState(() {
      _isSearchBarFocused = isFocused;
      _lastScrollOffset = _scrollCtrl.offset;
      if (isFocused && !_isHeaderVisible) {
        _isHeaderVisible = true;
        widget.onNavVisibilityChanged?.call(true);
      }
    });
  }

  Future<void> _refreshFeed() async {
    // Use force refresh to bypass cache
    await _svc.refreshPosts(
      categories: _categoryFilters,
      goals: _goalFilters,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
      dateRange: _dateRangeFilter.value,
      limit: _limit,
      offset: 0,
    );
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    // No more client-side filtering - all filtering is now server-side
    final displayPosts = _posts;

    final mainContent = Scaffold(
      endDrawer: const AppMenuDrawer(),
      body: Column(
        children: [
          // Fixed Header with auto-hide animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: _isHeaderVisible ? null : 0,
            curve: Curves.fastOutSlowIn,
            child: AnimatedOpacity(
              opacity: _isHeaderVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: Material(
                elevation: 3,
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: AppHeader(
                    searchText: _search,
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: _onClearSearch,
                    onFilterTap: _openFilterSheet,
                    onSearchFocusChanged: _handleSearchFocusChanged,
                    hasActiveFilters:
                        _categoryFilters.isNotEmpty || _goalFilters.isNotEmpty,
                    filterSummary:
                        (_categoryFilters.isNotEmpty || _goalFilters.isNotEmpty)
                            ? _getFilterSummary()
                            : null,
                  ),
                ),
              ),
            ),
          ),
          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFeed,
              color: AppColors.primary, // Use orange for refresh indicator
              backgroundColor: Colors.white,
              displacement: 40,
              strokeWidth: 2.5,
              child: _loading
                  ? ListView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.zero,
                      children: [
                        ...List.generate(
                            4,
                            (i) => Padding(
                                  padding: EdgeInsets.only(
                                    top: i == 0 ? 8 : 0,
                                    bottom: 12,
                                  ),
                                  child: const _PostSkeleton(),
                                )),
                      ],
                    )
                    : _error != null
                        ? ErrorStateWidget(
                            onRetry: () => _load(reset: true),
                          )
                        : ListView.builder(
                          controller: _scrollCtrl,
                          padding: EdgeInsets.zero,
                          itemCount: displayPosts.length + 1,
                          itemBuilder: (context, i) {
                            if (i == displayPosts.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: _loadingMore
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: () => _load(),
                                          child: const Text('Load more'),
                                        ),
                                ),
                              );
                            }
                            final p = displayPosts[i];
                            final category = (p.category ?? '').toString();
                            final subtitle = [
                              if (category.isNotEmpty) '#$category',
                            ].join(' · ');
                            final goalLabel = p.postGoal != null
                                ? AppConstants.goalLabel(p.postGoal!,
                                    customDescription: p.postGoalDescription)
                                : null;
                            final postCard = EnhancedPostCard(
                              post: p,
                              meUid: _me?.id,
                              subtitle: subtitle,
                              goalLabel: goalLabel,
                              onEdited: () => _load(reset: true),
                              onDeleted: () {
                                setState(() =>
                                    _posts.removeWhere((pp) => pp.id == p.id));
                              },
                            );

                            return Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 8 : 0,
                                bottom: 12,
                              ),
                              child: isLargeScreen
                                  ? Center(
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 700),
                                        child: postCard,
                                      ),
                                    )
                                  : postCard,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );

    // Wrap with onboarding overlay if first-time user
    if (_showOnboarding) {
      return FeedOnboardingOverlay(
        onComplete: () {
          setState(() => _showOnboarding = false);
        },
        child: mainContent,
      );
    }

    return mainContent;
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AnimatedShimmer(height: 170),
        SizedBox(height: 14),
        AnimatedShimmer(height: 18, width: 160),
        SizedBox(height: 10),
        AnimatedShimmer(height: 12, width: 100),
        SizedBox(height: 10),
        AnimatedShimmer(height: 12),
      ],
    );
  }
}
