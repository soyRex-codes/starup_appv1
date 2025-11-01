import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';
import 'package:foundervers/models/comment.dart';
import 'package:foundervers/services/notification_service.dart';

/// Service for managing comments with real-time capabilities
class CommentService {
  final SupabaseClient _client = Supa.client;

  /// Fetch all comments for a post with author info and organize into threads
  Future<List<CommentModel>> fetchComments(int postId) async {
    try {
      final data = await _client
          .from('comments')
          .select('''
            id,
            post_id,
            author_id,
            content,
            category,
            parent_comment_id,
            created_at,
            updated_at,
            edited,
            author:users!author_id(id, name, username, full_name, avatar_url)
          ''')
          .eq('post_id', postId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      final comments = (data as List)
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Organize into threads: parent comments with nested replies
      return _organizeThreads(comments);
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  /// Get comment count for a post
  Future<int> getCommentCount(int postId) async {
    try {
      final result = await _client.rpc('get_comment_count', params: {
        'p_post_id': postId,
      });
      return result as int? ?? 0;
    } catch (e) {
      // Fallback to manual count if RPC fails
      try {
        final response = await _client
            .from('comments')
            .select('id')
            .eq('post_id', postId)
            .isFilter('deleted_at', null)
            .count(CountOption.exact);
        return response.count;
      } catch (e2) {
        print('Error getting comment count: $e2');
        return 0;
      }
    }
  }

  /// Add a new root comment to a post
  Future<CommentModel> addComment({
    required int postId,
    required String content,
    required CommentCategory category,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        throw Exception('Comment cannot be empty');
      }

      final data = await _client.from('comments').insert({
        'post_id': postId,
        'author_id': userId,
        'content': trimmedContent,
        'category': category.value,
      }).select('''
            id,
            post_id,
            author_id,
            content,
            category,
            parent_comment_id,
            created_at,
            updated_at,
            edited,
            author:users!author_id(id, name, username, full_name, avatar_url)
          ''').single();

      final comment = CommentModel.fromJson(data);

      // Create notification for post owner (fire and forget)
      _notifyPostOwner(postId, comment);

      return comment;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// Add a reply to an existing comment
  Future<CommentModel> addReply({
    required String parentCommentId,
    required String content,
    required int postId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        throw Exception('Reply cannot be empty');
      }

      final data = await _client.from('comments').insert({
        'post_id': postId,
        'author_id': userId,
        'content': trimmedContent,
        'category': 'general', // Replies don't need categories
        'parent_comment_id': parentCommentId,
      }).select('''
            id,
            post_id,
            author_id,
            content,
            category,
            parent_comment_id,
            created_at,
            updated_at,
            edited,
            author:users!author_id(id, name, username, full_name, avatar_url)
          ''').single();

      final reply = CommentModel.fromJson(data);

      // Create notification for parent comment author (fire and forget)
      _notifyParentCommentAuthor(parentCommentId, postId, reply);

      return reply;
    } catch (e) {
      print('Error adding reply: $e');
      rethrow;
    }
  }

  /// Soft delete a comment (sets deleted_at timestamp)
  Future<void> deleteComment(String commentId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('comments')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', commentId)
          .eq('author_id', userId); // RLS ensures only author can delete
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time comment updates for a post
  Stream<List<CommentModel>> subscribeToComments(int postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .map((data) {
          final comments = data
              .map((json) => CommentModel.fromJson(json))
              .where((comment) => comment.id.isNotEmpty)
              .toList();
          return _organizeThreads(comments);
        });
  }

  /// Organize flat comment list into threaded structure
  List<CommentModel> _organizeThreads(List<CommentModel> comments) {
    final Map<String, List<CommentModel>> repliesByParent = {};
    final List<CommentModel> rootComments = [];

    // First pass: separate root comments and group replies
    for (final comment in comments) {
      if (comment.parentCommentId == null) {
        rootComments.add(comment);
      } else {
        repliesByParent
            .putIfAbsent(comment.parentCommentId!, () => [])
            .add(comment);
      }
    }

    // Second pass: attach replies to their parents
    return rootComments.map((root) {
      return _attachReplies(root, repliesByParent);
    }).toList();
  }

  /// Recursively attach replies to a comment
  CommentModel _attachReplies(
      CommentModel comment, Map<String, List<CommentModel>> repliesByParent) {
    final replies = repliesByParent[comment.id] ?? [];
    final nestedReplies =
        replies.map((r) => _attachReplies(r, repliesByParent)).toList();
    return comment.copyWith(replies: nestedReplies);
  }

  /// Create notification for post owner when someone comments
  Future<void> _notifyPostOwner(int postId, CommentModel comment) async {
    try {
      // Get post owner and title
      final post = await _client
          .from('posts')
          .select('user_id, title')
          .eq('id', postId)
          .single();

      final postOwnerId = post['user_id'] as String;
      final postTitle = post['title'] as String;

      // Get commenter name
      final commenterName = comment.author?.displayName ?? 'Someone';

      // Create notification
      await NotificationService.notifyComment(
        postOwnerId: postOwnerId,
        commenterName: commenterName,
        postId: postId,
        postTitle: postTitle,
        commenterId: comment.authorId,
      );
    } catch (e) {
      print('Error creating comment notification: $e');
      // Don't throw - notification is non-critical
    }
  }

  /// Create notification for parent comment author when someone replies
  Future<void> _notifyParentCommentAuthor(
      String parentCommentId, int postId, CommentModel reply) async {
    try {
      // Get parent comment author
      final parentComment = await _client
          .from('comments')
          .select('author_id')
          .eq('id', parentCommentId)
          .single();

      final parentAuthorId = parentComment['author_id'] as String;

      // Get replier name
      final replierName = reply.author?.displayName ?? 'Someone';

      // Create notification
      await NotificationService.notifyReply(
        originalCommenterId: parentAuthorId,
        replierName: replierName,
        commentId: parentCommentId,
        postId: postId,
        replierId: reply.authorId,
      );
    } catch (e) {
      print('Error creating reply notification: $e');
      // Don't throw - notification is non-critical
    }
  }
}
