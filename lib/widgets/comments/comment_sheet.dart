import 'package:flutter/material.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/services/comment_service.dart';
import 'package:foundervers/app/theme.dart';
import 'package:foundervers/widgets/comments/comment_thread.dart';
import 'package:foundervers/widgets/comments/comment_input.dart';

/// Bottom sheet for displaying and managing post comments
class CommentSheet extends StatefulWidget {
  final PostModel post;
  final ValueChanged<int>? onCountChanged;

  const CommentSheet({
    required this.post,
    this.onCountChanged,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    PostModel post, {
    ValueChanged<int>? onCountChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        post: post,
        onCountChanged: onCountChanged,
      ),
    );
  }

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final CommentService _commentService = CommentService();
  final ScrollController _scrollController = ScrollController();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  String? _error;
  CommentModel? _replyingTo;

  int get _totalVisibleComments {
    int total = 0;
    for (final comment in _comments) {
      total += _countWithReplies(comment);
    }
    return total;
  }

  void _notifyCountChanged() {
    widget.onCountChanged?.call(_totalVisibleComments);
  }

  int _countWithReplies(CommentModel comment) {
    if (comment.replies.isEmpty) return 1;
    return 1 +
        comment.replies.fold<int>(
          0,
          (sum, reply) => sum + _countWithReplies(reply),
        );
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await _commentService.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
        _notifyCountChanged();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load comments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddComment(
      String content, CommentCategory? category) async {
    try {
      if (_replyingTo != null) {
        // Add reply
        await _commentService.addReply(
          parentCommentId: _replyingTo!.id,
          content: content,
          postId: widget.post.id,
        );
        setState(() => _replyingTo = null);
      } else {
        // Add root comment
        if (category == null) {
          throw Exception('Category is required for root comments');
        }
        await _commentService.addComment(
          postId: widget.post.id,
          content: content,
          category: category,
        );
      }

      // Reload comments to show the new one
      await _loadComments();

      // Scroll to bottom to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_replyingTo != null ? 'Reply added!' : 'Comment added!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(commentId);
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _handleReply(CommentModel comment) {
    setState(() => _replyingTo = comment);
  }

  void _handleCancelReply() {
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = screenHeight; // Full screen height
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.bg : AppColors.bg;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            _buildHandleBar(isDark),

            // Header
            _buildHeader(isDark),

            // Comments list
            Expanded(
              child: _buildCommentsList(isDark),
            ),

            // Input section
            CommentInput(
              postId: widget.post.id,
              replyingTo: _replyingTo,
              onSubmit: _handleAddComment,
              onCancelReply: _handleCancelReply,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandleBar(bool isDark) {
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                if (_comments.isNotEmpty)
                  Text(
                    '$_totalVisibleComments ${_totalVisibleComments == 1 ? 'comment' : 'comments'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            iconSize: 24,
            style: IconButton.styleFrom(
              foregroundColor: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(bool isDark) {
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _comments.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: borderColor,
        ),
        itemBuilder: (context, index) {
          final comment = _comments[index];
          return CommentThread(
            comment: comment,
            onReply: _handleReply,
            onDelete: _handleDeleteComment,
          );
        },
      ),
    );
  }
}
