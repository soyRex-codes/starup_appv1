import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:foundervers/core/constants.dart';

class SinglePostFeedPage extends StatefulWidget {
  const SinglePostFeedPage({super.key, required this.post});

  final PostModel post;

  @override
  State<SinglePostFeedPage> createState() => _SinglePostFeedPageState();
}

class _SinglePostFeedPageState extends State<SinglePostFeedPage> {
  late PostModel _post;
  final _me = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  void _handlePostEdited() {
    // Refresh post data if needed, or just rely on parent to refresh
    // For now, we can just setState to trigger a rebuild if we had logic to fetch fresh data
    // But since we pass the post object, we might need to fetch it again if we want real-time updates
    // For simplicity in this refactor, we'll assume the edit flow returns updated data or we could fetch it here.
    // Given the current architecture, we'll just keep the current post or maybe fetch it.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: EnhancedPostCard(
          post: _post,
          meUid: _me?.id,
          subtitle: subtitle,
          goalLabel: goalLabel,
          onEdited: _handlePostEdited,
          onDeleted: _handlePostDeleted,
          isDetailView: true, // Enable detail view mode
        ),
      ),
    );
  }
}
