import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostLikeSummary {
  const PostLikeSummary({required this.count, required this.likedByMe});

  final int count;
  final bool likedByMe;
}

class PostLikeService {
  PostLikeService._();
  static final PostLikeService instance = PostLikeService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<int, PostLikeSummary>> getSummaries(List<int> postIds) async {
    if (postIds.isEmpty || _client.auth.currentUser == null) return {};

    try {
      final response = await _client.rpc(
        'get_post_like_summaries',
        params: {'p_post_ids': postIds},
      );
      final summaries = <int, PostLikeSummary>{};
      for (final raw in response as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final postId = _asInt(row['post_id']);
        if (postId == null) continue;
        summaries[postId] = PostLikeSummary(
          count: _asInt(row['like_count']) ?? 0,
          likedByMe: row['liked_by_me'] == true,
        );
      }
      return summaries;
    } catch (error) {
      // The feed remains usable before the additive migration is deployed.
      if (kDebugMode) debugPrint('Post likes are not available yet: $error');
      return {};
    }
  }

  Future<void> setLiked({required int postId, required bool liked}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to like posts.');

    if (liked) {
      try {
        await _client.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
      }
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    }
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
