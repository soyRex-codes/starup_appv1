import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';
import 'package:foundervers/models/post.dart';
import 'package:foundervers/features/post_creation/post_service.dart';
import 'package:foundervers/core/cache/feed_cache.dart';

class FeedService {
  final SupabaseClient _s = Supa.client;
  final PostService _postService = PostService();
  final FeedCache _cache = FeedCache.instance;

  Future<List<PostModel>> fetchPosts({
    String? category,
    String? goal,
    String? search,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless forcing refresh)
    if (!forceRefresh) {
      final cached = _cache.get(
        category: category,
        goal: goal,
        search: search,
        offset: offset,
      );
      if (cached != null) {
        return cached;
      }
    }
    // CRITICAL FIX: Use explicit post-media relationship to prevent wrong images
    // First fetch posts without media join to avoid Supabase join issues
    var q = _s.from('posts').select(
          'id,user_id,name,category,title,description,funding_goal,post_goal,post_goal_description,email,created_at,updated_at,moderation_status,status',
        );

    // Apply filters
    if (category != null && category.isNotEmpty) {
      q = q.eq('category', category);
    }
    if (goal != null && goal.isNotEmpty) {
      q = q.eq('post_goal', goal);
    }

    // Apply search filter using PostgreSQL's text search
    if (search != null && search.trim().isNotEmpty) {
      final searchTerm = search.trim().toLowerCase();
      // Search in title, description, and name fields using ilike for case-insensitive search
      q = q.or(
          'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%,name.ilike.%$searchTerm%');
    }

    final data = await q
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final rawPosts =
        (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Fetch media separately with explicit post_id filtering to prevent wrong images
    final postIds =
        rawPosts.map((p) => p['id']).where((id) => id != null).toList();
    final Map<int, List<Map<String, dynamic>>> mediaByPostId = {};

    if (postIds.isNotEmpty) {
      final mediaQuery = _s.from('media').select('*');
      dynamic mediaResp;
      if (postIds.length == 1) {
        mediaResp = await mediaQuery.eq('post_id', postIds.first);
      } else {
        final values = '(${postIds.join(',')})';
        mediaResp = await mediaQuery.filter('post_id', 'in', values);
      }
      final mediaList = (mediaResp as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Group media by post_id for correct association
      for (final media in mediaList) {
        final postId = media['post_id'] as int?;
        if (postId != null) {
          mediaByPostId.putIfAbsent(postId, () => []).add(media);
        }
      }
    }

    // Add media to each post
    for (final post in rawPosts) {
      final postId = post['id'] as int?;
      post['media'] = mediaByPostId[postId] ?? [];
    }

    // Distinct user ids
    final userIds = rawPosts
        .map((p) => (p['user_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, AuthorSummary> authors = {};
    if (userIds.isNotEmpty) {
      final usersQuery =
          _s.from('users').select('id,name,username,full_name,avatar_url');
      dynamic usersResp;
      if (userIds.length == 1) {
        usersResp = await usersQuery.eq('id', userIds.first);
      } else {
        // PostgREST IN filter needs quoted list
        final values = '(${userIds.map((e) => '"$e"').join(',')})';
        usersResp = await usersQuery.filter('id', 'in', values);
      }
      final users = (usersResp as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final u in users) {
        final uid = (u['id'] ?? '').toString();
        if (uid.isEmpty) continue;
        authors[uid] = AuthorSummary(
          userId: uid,
          name: u['name'] as String?,
          username: u['username'] as String?,
          fullName: u['full_name'] as String?,
          avatarUrl: u['avatar_url'] as String?,
        );
      }
    }

    final posts = rawPosts
        .map((r) =>
            PostModel.fromJson(r).copyWith(author: authors[r['user_id']]))
        .toList();

    // Cache the results for future use
    _cache.put(
      category: category,
      goal: goal,
      search: search,
      offset: offset,
      posts: posts,
    );

    return posts;
  }

  /// Clear cache when posts are modified
  void invalidateCache({String? category, String? goal}) {
    _cache.invalidate(category: category, goal: goal);
  }

  /// Force refresh and update cache
  Future<List<PostModel>> refreshPosts({
    String? category,
    String? goal,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final posts = await fetchPosts(
      category: category,
      goal: goal,
      search: search,
      limit: limit,
      offset: offset,
      forceRefresh: true,
    );

    // Update cache with fresh data
    _cache.put(
      category: category,
      goal: goal,
      search: search,
      offset: offset,
      posts: posts,
    );

    return posts;
  }
}

extension FeedServiceMutations on FeedService {
  Future<void> deletePost({required int id}) => _postService.deletePost(id: id);
}
