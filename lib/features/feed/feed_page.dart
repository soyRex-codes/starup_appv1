import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:foundervers/core/env.dart';
import 'package:foundervers/core/visibility.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/app/widgets/filter_sheet.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';

import '../../app/theme.dart';
import '../../app/widgets/app_header.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

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
  String? _categoryFilter; // null = All
  String _search = '';
  String? _goalFilter; // null = all goals
  final _scrollCtrl = ScrollController();
  Timer? _searchTimer; // Debounce timer for search

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
    try {
      final newPosts = await _svc.fetchPosts(
        category: _categoryFilter,
        goal: _goalFilter,
        search: _search.trim().isNotEmpty ? _search.trim() : null,
        limit: _limit,
        offset: _offset,
      );
      final filtered = newPosts
          .where((p) => VisibilityRules.canSeePost(
              post: _postToVisMap(p), me: _me, admins: AppEnv.adminEmails))
          .toList();
      setState(() {
        _posts.addAll(filtered);
        _offset += _limit;
      });
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

  Map<String, dynamic> _postToVisMap(PostModel p) {
    return {
      'user_id': p.userId,
      'moderation_status': p.moderationStatus,
      'status': p.status,
    };
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialCategory: _categoryFilter,
        initialGoal: _goalFilter,
      ),
    );

    if (result != null) {
      setState(() {
        _categoryFilter = result['category'];
        _goalFilter = result['goal'];
      });
      _load(reset: true);
    }
  }

  String _getFilterSummary() {
    final parts = <String>[];
    if (_categoryFilter != null) {
      parts.add(_formatCategoryLabel(_categoryFilter!));
    }
    if (_goalFilter != null) {
      parts.add(_formatGoalLabel(_goalFilter!));
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

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  /// Public method to refresh the feed (called when new posts are created)
  Future<void> refreshAfterPostCreation() async {
    await _refreshFeed();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchTimer?.cancel();
    super.dispose();
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

  Future<void> _refreshFeed() async {
    // Use force refresh to bypass cache
    await _svc.refreshPosts(
      category: _categoryFilter,
      goal: _goalFilter,
      search: _search.trim().isNotEmpty ? _search.trim() : null,
      limit: _limit,
      offset: 0,
    );
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    // No more client-side filtering - all filtering is now server-side
    final displayPosts = _posts;
    return Scaffold(
      body: Column(
        children: [
          // Fixed Header
          Material(
            elevation: 3,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: AppHeader(
                searchText: _search,
                onSearchChanged: _onSearchChanged,
                onClearSearch: _onClearSearch,
                onFilterTap: _openFilterSheet,
                hasActiveFilters:
                    _categoryFilter != null || _goalFilter != null,
                filterSummary: (_categoryFilter != null || _goalFilter != null)
                    ? _getFilterSummary()
                    : null,
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
                      ? ListView(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          children: [
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            ])
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
                            return Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 8 : 0,
                                bottom: 12,
                              ),
                              child: EnhancedPostCard(
                                post: p,
                                meUid: _me?.id,
                                subtitle: subtitle,
                                goalLabel: goalLabel,
                                onEdited: () => _load(reset: true),
                                onDeleted: () {
                                  setState(() => _posts
                                      .removeWhere((pp) => pp.id == p.id));
                                },
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
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
