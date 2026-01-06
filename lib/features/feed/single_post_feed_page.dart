import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:foundervers/core/constants.dart';
import 'package:foundervers/services/post_counts_manager.dart';

class SinglePostFeedPage extends StatefulWidget {
  const SinglePostFeedPage({super.key, required this.post});

  final PostModel post;

  @override
  State<SinglePostFeedPage> createState() => _SinglePostFeedPageState();
}

class _SinglePostFeedPageState extends State<SinglePostFeedPage> {
  late PostModel _post;
  final _me = Supabase.instance.client.auth.currentUser;
  final _supa = Supabase.instance.client;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _subscribeToPostUpdates();
  }

  /// Subscribe to real-time updates for this specific post
  void _subscribeToPostUpdates() {
    _subscription = _supa
        .channel('post_${_post.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _post.id,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            final views = newData['views'] as int? ?? _post.views;
            final comments = newData['comment_count'] as int? ?? _post.commentCount;

            // Update PostCountsManager so all UI instances update
            PostCountsManager.instance.updateCounts(
              _post.id,
              views: views,
              comments: comments,
            );
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  void _handlePostEdited() {
    // Refresh post data if needed, or just rely on parent to refresh
    // For now, we can just setState to trigger a rebuild if we had logic to fetch fresh data
    // But since we pass the post object, we might need to fetch it again if we want real-time updates
    // For simplicity in this refactor, we'll just keep the current post or maybe fetch it.
    // Let's just setState to be safe.
    setState(() {});
  }

  void _handlePostDeleted() {
    Navigator.of(context).pop(true); // Return true to indicate deletion/change
  }

  @override
  Widget build(BuildContext context) {
    final category = (_post.category ?? '').toString();
    final subtitle = [
      if (category.isNotEmpty) '#$category',
    ].join(' · ');
    
    final goalLabel = _post.postGoal != null
        ? AppConstants.goalLabel(_post.postGoal!,
            customDescription: _post.postGoalDescription)
        : null;

    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final postCard = EnhancedPostCard(
      post: _post,
      meUid: _me?.id,
      subtitle: subtitle,
      goalLabel: goalLabel,
      onEdited: _handlePostEdited,
      onDeleted: _handlePostDeleted,
      isDetailView: true, // Enable detail view mode
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: isLargeScreen
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: postCard,
                ),
              )
            : postCard,
      ),
    );
  }
}
