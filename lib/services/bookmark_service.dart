import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/models/post.dart';
import 'notification_service.dart';

/// Service for managing post bookmarks/saves with efficient caching
class BookmarkService {
  BookmarkService._();
  static final BookmarkService instance = BookmarkService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ============================================
  // CACHING LAYER - EVENT-DRIVEN (NEVER EXPIRES)
  // ============================================

  /// In-memory cache of bookmarked post IDs for instant lookups
  /// NEVER expires - only invalidates on bookmark/unbookmark events
  Set<int>? _cachedBookmarkIds;

  /// Cached bookmarked posts (for Saved tab)
  /// NEVER expires - only invalidates on bookmark/unbookmark events
  List<PostModel>? _cachedPosts;

  /// Clear all caches (call on logout or manual refresh)
  void clearCache() {
    _cachedBookmarkIds = null;
    _cachedPosts = null;
    debugPrint('🧹 Bookmark cache cleared');
  }

  /// Force refresh cache from database
  Future<void> refreshCache() async {
    debugPrint('🔄 Refreshing bookmark cache...');
    _cachedBookmarkIds = null;
    await _ensureCacheLoaded();
  }

  /// Ensure cache is loaded (lazy loading)
  /// Cache NEVER expires - lives forever until invalidated by events
  Future<void> _ensureCacheLoaded() async {
    if (_cachedBookmarkIds != null) return; // Already loaded, use forever!

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _cachedBookmarkIds = {};
        return;
      }

      final response = await _client
          .from('bookmarks')
          .select('post_id')
          .eq('user_id', userId);

      _cachedBookmarkIds =
          response.map((item) => item['post_id'] as int).toSet();

      debugPrint(
          '✅ Bookmark cache loaded: ${_cachedBookmarkIds!.length} bookmarks (cached forever)');
    } catch (e) {
      debugPrint('❌ Error loading bookmark cache: $e');
      _cachedBookmarkIds = {};
    }
  }

  // ============================================
  // BOOKMARK OPERATIONS (with cache updates)
  // ============================================

  /// Add a bookmark for a post
  /// Returns true if successful, false if already bookmarked or error
  Future<bool> addBookmark(int postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Cannot bookmark: User not authenticated');
        return false;
      }

      // Optimistic update - add to cache immediately
      await _ensureCacheLoaded();
      _cachedBookmarkIds?.add(postId);

      await _client.from('bookmarks').insert({
        'user_id': userId,
        'post_id': postId,
      });

      // Notify post owner about the bookmark
      _notifyPostOwner(postId, userId);

      // Invalidate posts cache since we added a new bookmark
      _cachedPosts = null;

      debugPrint('✅ Bookmark added for post $postId (cache invalidated)');
      return true;
    } on PostgrestException catch (e) {
      // Error code 23505 = unique constraint violation (already bookmarked)
      if (e.code == '23505') {
        debugPrint('⚠️ Post $postId already bookmarked');
        // Still add to cache in case it was missing
        _cachedBookmarkIds?.add(postId);
        return false;
      }
      debugPrint('❌ Error adding bookmark: ${e.message}');
      // Rollback optimistic update
      _cachedBookmarkIds?.remove(postId);
      return false;
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
      // Rollback optimistic update
      _cachedBookmarkIds?.remove(postId);
      return false;
    }
  }

  /// Remove a bookmark for a post
  /// Returns true if successful
  Future<bool> removeBookmark(int postId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Cannot remove bookmark: User not authenticated');
        return false;
      }

      // Optimistic update - remove from cache immediately
      await _ensureCacheLoaded();
      _cachedBookmarkIds?.remove(postId);

      await _client
          .from('bookmarks')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);

      // Invalidate posts cache since we removed a bookmark
      _cachedPosts = null;

      debugPrint('✅ Bookmark removed for post $postId (cache invalidated)');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
      // Rollback optimistic update
      _cachedBookmarkIds?.add(postId);
      return false;
    }
  }

  /// Toggle bookmark status for a post
  /// Returns the new bookmark status (true = bookmarked, false = not bookmarked)
  Future<bool> toggleBookmark(int postId) async {
    final isCurrentlyBookmarked = await isBookmarked(postId);

    if (isCurrentlyBookmarked) {
      await removeBookmark(postId);
      return false;
    } else {
      await addBookmark(postId);
      return true;
    }
  }

  /// Check if a post is bookmarked by current user
  /// FAST: Uses in-memory cache, no DB call after initial load
  Future<bool> isBookmarked(int postId) async {
    await _ensureCacheLoaded();
    return _cachedBookmarkIds?.contains(postId) ?? false;
  }

  /// Synchronous version - use only if cache is already loaded
  /// Returns false if cache not loaded
  bool isBookmarkedSync(int postId) {
    return _cachedBookmarkIds?.contains(postId) ?? false;
  }

  /// Get all bookmarked posts for current user
  /// Returns list of posts with full details
  /// EVENT-DRIVEN: Cache never expires, only invalidates on bookmark changes
  Future<List<PostModel>> getBookmarkedPosts({
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Return cached posts if loaded and not forcing refresh
    if (!forceRefresh && offset == 0 && _cachedPosts != null) {
      debugPrint(
          '📦 Returning cached bookmarked posts (${_cachedPosts!.length} posts) - NEVER EXPIRES');
      return _cachedPosts!;
    }

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Cannot get bookmarks: User not authenticated');
        return [];
      }

      final response = await _client
          .from('bookmarks')
          .select('''
            created_at,
            posts:post_id (
              id,
              user_id,
              name,
              category,
              title,
              description,
              funding_goal,
              post_goal,
              post_goal_description,
              status,
              moderation_status,
              created_at,
              updated_at,
              comment_count,
              media (
                id,
                post_id,
                filename,
                original_name,
                file_path,
                file_size,
                type,
                uploaded_at
              )
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts = <PostModel>[];
      for (final item in response) {
        if (item['posts'] != null) {
          try {
            final postData = item['posts'] as Map<String, dynamic>;
            posts.add(PostModel.fromJson(postData));
          } catch (e) {
            debugPrint('⚠️ Error parsing post: $e');
          }
        }
      }

      // Enrich posts with author info to avoid Unknown User labels
      if (posts.isNotEmpty) {
        final userIds = posts.map((p) => p.userId).toSet();
        try {
          final usersResp = await _client
              .from('users')
              .select('id,name,username,full_name,avatar_url,email_verified')
              .filter(
                'id',
                'in',
                '(${userIds.map((e) => '"$e"').join(',')})',
              );

          final authors = <String, AuthorSummary>{};
          for (final user in usersResp as List) {
            final row = Map<String, dynamic>.from(user as Map);
            final uid = (row['id'] ?? '').toString();
            if (uid.isEmpty) continue;
            authors[uid] = AuthorSummary(
              userId: uid,
              name: row['name'] as String?,
              username: row['username'] as String?,
              fullName: row['full_name'] as String?,
              avatarUrl: row['avatar_url'] as String?,
              emailVerified: row['email_verified'] as bool?,
            );
          }

          for (var i = 0; i < posts.length; i++) {
            final author = authors[posts[i].userId];
            if (author != null) {
              posts[i] = posts[i].copyWith(author: author);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error enriching bookmarked posts with authors: $e');
        }
      }

      // Cache first page only (lives forever until invalidated)
      if (offset == 0) {
        _cachedPosts = posts;
      }

      debugPrint(
          '✅ Fetched ${posts.length} bookmarked posts from DB (cached forever)');
      return posts;
    } catch (e) {
      debugPrint('❌ Error fetching bookmarked posts: $e');
      return [];
    }
  }

  /// Get bookmark count for a specific post
  Future<int> getBookmarkCount(int postId) async {
    try {
      final response =
          await _client.from('bookmarks').select('id').eq('post_id', postId);

      return response.length;
    } catch (e) {
      debugPrint('❌ Error getting bookmark count: $e');
      return 0;
    }
  }

  /// Get IDs of all bookmarked posts for current user (for efficient checking)
  /// Returns cached set - no DB call needed
  Future<Set<int>> getBookmarkedPostIds() async {
    await _ensureCacheLoaded();
    return Set<int>.from(_cachedBookmarkIds ?? {});
  }

  /// Clear all bookmarks for current user
  Future<bool> clearAllBookmarks() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('bookmarks').delete().eq('user_id', userId);

      // Clear cache
      _cachedBookmarkIds?.clear();
      _cachedPosts = null;

      debugPrint('✅ All bookmarks cleared (cache cleared)');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing bookmarks: $e');
      return false;
    }
  }

  /// Notify post owner about bookmark
  void _notifyPostOwner(int postId, String bookmarkerId) async {
    try {
      // Get current user's name (try full_name first, fall back to name)
      final currentUser = await _client
          .from('users')
          .select('full_name, name')
          .eq('id', bookmarkerId)
          .maybeSingle();

      final bookmarkerName =
          currentUser?['full_name'] ?? currentUser?['name'] ?? 'Someone';

      // Get post owner and title
      final post = await _client
          .from('posts')
          .select('user_id, title, description')
          .eq('id', postId)
          .maybeSingle();

      if (post != null && post['user_id'] != bookmarkerId) {
        final postTitle = (post['title'] as String?)?.isNotEmpty == true
            ? post['title']
            : (post['description'] as String?)?.substring(0, 50) ?? 'your post';

        await NotificationService.notifyBookmark(
          postOwnerId: post['user_id'],
          bookmarkerName: bookmarkerName,
          postId: postId,
          postTitle: postTitle,
          bookmarkerId: bookmarkerId,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send bookmark notification: $e');
      // Don't throw - notification failure shouldn't break bookmark functionality
    }
  }
}
