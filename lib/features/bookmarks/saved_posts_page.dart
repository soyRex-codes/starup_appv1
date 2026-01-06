import 'package:flutter/material.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/services/bookmark_service.dart';
import 'package:foundervers/features/feed/enhanced_post_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  final _bookmarkService = BookmarkService.instance;
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarkedPosts();
  }

  Future<void> _loadBookmarkedPosts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use cache by default, force refresh only when explicitly requested
      final posts = await _bookmarkService.getBookmarkedPosts(
        limit: 50,
        forceRefresh: false, // Let cache handle this
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    // Force refresh from database
    try {
      final posts = await _bookmarkService.getBookmarkedPosts(
        limit: 50,
        forceRefresh: true, // Bypass cache
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handlePostEdited() {
    // Refresh the list when a post is edited
    _loadBookmarkedPosts();
  }

  void _handlePostDeleted() {
    // Refresh the list when a post is deleted
    _loadBookmarkedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Saved Posts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load saved posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No saved posts yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Posts you bookmark will appear here for easy access later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final postCard = EnhancedPostCard(
            key: ValueKey('saved_post_${post.id}'),
            post: post,
            meUid: _currentUserId,
            subtitle: _buildSubtitle(post),
            goalLabel: _buildGoalLabel(post),
            onEdited: _handlePostEdited,
            onDeleted: _handlePostDeleted,
          );
          final isLargeScreen = MediaQuery.of(context).size.width > 600;
          return isLargeScreen
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: postCard,
                  ),
                )
              : postCard;
        },
      ),
    );
  }

  String _buildSubtitle(PostModel post) {
    final parts = <String>[];
    if (post.category != null && post.category!.isNotEmpty) {
      parts.add(post.category!);
    }
    if (post.status != null && post.status!.isNotEmpty) {
      parts.add(post.status!);
    }
    return parts.join(' • ');
  }

  String? _buildGoalLabel(PostModel post) {
    if (post.postGoal != null && post.postGoal!.isNotEmpty) {
      return 'Goal: ${post.postGoal}';
    }
    return null;
  }
}
