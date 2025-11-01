import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';
import 'package:foundervers/features/feed/feed_service.dart';
import 'package:foundervers/models/post.dart';

class PostService {
  final SupabaseClient _s = Supa.client;

  /// Maps StorageException to a more descriptive Exception
  Exception _handleStorageException(StorageException e) {
    if (e.statusCode == '404') {
      return Exception(
          'Storage bucket not found. Please check your Supabase configuration.');
    } else if (e.statusCode == '413') {
      return Exception('File is too large. Maximum size is 50MB.');
    } else if (e.statusCode == '403') {
      return Exception(
          'Permission denied. Please check your storage policies.');
    } else {
      return Exception('Upload failed: ${e.message}');
    }
  }

  /// Generic fallback for non-storage exceptions
  Exception _handleGenericUploadException(dynamic e) {
    return Exception('Upload failed: ${e.toString()}');
  }

  Future<void> _ensureUserExists({
    required String uid,
    String? email,
    String? name,
  }) async {
    try {
      await _s.rpc('ensure_user_exists', params: {
        'p_uid': uid,
        'p_email': email,
        'p_name': name,
      });
    } catch (_) {
      // Silently ignore; trigger may also create user. We only care about FK success.
    }
  }

  Future<int> createPost({
    required String userId,
    required String authorName,
    required String title,
    String? description,
    String? category,
    num? fundingGoal,
    String? postGoal,
    String? postGoalDescription,
    String? email,
    String moderationStatus = 'approved',
  }) async {
    // Ensure user exists to satisfy FK (defensive; trigger should also handle this)
    await _ensureUserExists(uid: userId, email: email, name: authorName);
    final insert = await _s
        .from('posts')
        .insert({
          'user_id': userId,
          'name': authorName,
          'title': title,
          'description': description,
          'category': category,
          'funding_goal': fundingGoal,
          'post_goal': postGoal,
          'post_goal_description': postGoalDescription,
          'email': email,
          'moderation_status': moderationStatus,
        })
        .select('id,updated_at')
        .limit(1);
    final row = Map<String, dynamic>.from(((insert as List).first) as Map);

    // Invalidate feed cache after successful creation
    FeedService().invalidateCache();

    return (row['id'] as num).toInt();
  }

  Future<void> insertMediaRows({
    required int postId,
    required List<Map<String, dynamic>> mediaList,
  }) async {
    if (mediaList.isEmpty) {
      return;
    }

    try {
      await _s.from('media').insert(mediaList);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost({
    required int id,
    String? title,
    String? description,
    String? category,
    num? fundingGoal,
    String? postGoal,
    String? postGoalDescription,
  }) async {
    final Map<String, dynamic> patch = {};
    if (title != null) patch['title'] = title;
    if (description != null) patch['description'] = description;
    if (category != null) patch['category'] = category;
    if (fundingGoal != null) patch['funding_goal'] = fundingGoal;
    if (postGoal != null) patch['post_goal'] = postGoal;
    if (postGoalDescription != null) {
      patch['post_goal_description'] = postGoalDescription;
    }
    if (patch.isEmpty) return;
    await _s.from('posts').update(patch).eq('id', id);

    // Invalidate feed cache after successful update
    FeedService().invalidateCache();
  }

  Future<void> deletePost({required int id}) async {
    // Fetch media paths first for storage cleanup
    List<Map<String, dynamic>> media = [];
    try {
      final rows = await _s.from('media').select('file_path').eq('post_id', id);
      media = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      // Ignore fetch errors; proceed with DB delete
    }
    await _s.from('posts').delete().eq('id', id);

    // Invalidate feed cache after successful deletion
    FeedService().invalidateCache();

    // Attempt storage cleanup (best effort)
    for (final m in media) {
      final path = m['file_path']?.toString();
      if (path == null || path.isEmpty) continue;
      try {
        await _s.storage.from('startupbuilder').remove([path]);
      } catch (_) {
        // Ignore individual failures
      }
    }
  }

  Future<String> uploadMediaBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      await _s.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true, // Allow overwrite if file exists
            ),
          );

      return path; // Return storage path
    } on StorageException catch (e) {
      throw _handleStorageException(e);
    } catch (e) {
      throw _handleGenericUploadException(e);
    }
  }

  /// Streaming upload for large files (videos, large images) to prevent memory issues
  Future<String> uploadMediaFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
  }) async {
    try {
      await _s.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true, // Allow overwrite if file exists
            ),
          );

      return path; // Return storage path
    } on StorageException catch (e) {
      throw _handleStorageException(e);
    } catch (e) {
      throw _handleGenericUploadException(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    // First get the posts
    final rows = await _s
        .from('posts')
        .select('''
          id,
          user_id,
          name,
          title,
          description,
          category,
          funding_goal,
          post_goal,
          post_goal_description,
          email,
          created_at,
          updated_at,
          moderation_status,
          status
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts =
        (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Get media for all posts in one query if there are posts
    if (posts.isNotEmpty) {
      final postIds = posts.map((p) => p['id']).toList();
      final mediaRows = await _s
          .from('media')
          .select(
              'id,post_id,type,filename,original_name,file_path,file_size,uploaded_at')
          .filter('post_id', 'in', '(${postIds.join(',')})')
          .order('id');

      final mediaList = (mediaRows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Group media by post_id
      final mediaByPostId = <int, List<Map<String, dynamic>>>{};
      for (final media in mediaList) {
        final postId = media['post_id'] as int;
        mediaByPostId.putIfAbsent(postId, () => []).add(media);
      }

      // Add media to each post
      for (final post in posts) {
        final postId = post['id'] as int;
        post['media'] = mediaByPostId[postId] ?? [];
      }
    } else {
      // No posts, add empty media arrays
      for (final post in posts) {
        post['media'] = <Map<String, dynamic>>[];
      }
    }

    return posts;
  }

  /// Fetch posts for a specific user (for public profile viewing)
  Future<List<PostModel>> fetchUserPosts({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    // First get the posts
    final rows = await _s
        .from('posts')
        .select('''
          id,
          user_id,
          name,
          title,
          description,
          category,
          funding_goal,
          post_goal,
          post_goal_description,
          email,
          created_at,
          updated_at,
          moderation_status,
          status,
          comment_count
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts =
        (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (posts.isEmpty) {
      return [];
    }

    // Get media for all posts in one query if there are posts
    final postIds = posts.map((p) => p['id']).toList();
    final mediaRows = await _s
        .from('media')
        .select(
            'id,post_id,type,filename,original_name,file_path,file_size,uploaded_at')
        .filter('post_id', 'in', '(${postIds.join(',')})')
        .order('id');

    final mediaList = (mediaRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Group media by post_id
    final mediaByPostId = <int, List<Map<String, dynamic>>>{};
    for (final media in mediaList) {
      final postId = media['post_id'] as int;
      mediaByPostId.putIfAbsent(postId, () => []).add(media);
    }

    // Add media to each post
    for (final post in posts) {
      final postId = post['id'] as int;
      post['media'] = mediaByPostId[postId] ?? [];
    }

    // Convert to PostModel instances
    var postModels =
        posts.map((post) => PostModel.fromJson(post)).toList(growable: false);

    // Fetch author info (supports potential future multiple authors)
    final userIds =
        postModels.map((p) => p.userId).where((id) => id.isNotEmpty).toSet();

    if (userIds.isNotEmpty) {
      try {
        final usersResp = await _s
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

        postModels = postModels
            .map((post) => post.copyWith(author: authors[post.userId]))
            .toList(growable: false);
      } catch (e) {
        debugPrint('Error enriching posts with author info: $e');
      }
    }

    return postModels;
  }

  /// Fetch user creation timestamp (created_at) from users table.
  Future<DateTime?> fetchUserCreatedAt(String userId) async {
    try {
      final rows =
          await _s.from('users').select('created_at').eq('id', userId).limit(1);
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (list.isEmpty) return null;
      final raw = list.first['created_at'];
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  /// Returns a map of post_goal -> count for a user.
  Future<Map<String, int>> fetchGoalDistribution(
      {required String userId}) async {
    // Supabase Dart SDK (v2) does not currently expose a .group() helper; perform client-side aggregation.
    try {
      final rows = await _s
          .from('posts')
          .select('post_goal')
          .eq('user_id', userId)
          .limit(500); // safety cap
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final Map<String, int> dist = {};
      for (final r in list) {
        final g = (r['post_goal'] ?? 'unknown').toString();
        dist[g] = (dist[g] ?? 0) + 1;
      }
      return dist;
    } catch (_) {
      return {};
    }
  }
}
