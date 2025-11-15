import 'package:supabase_flutter/supabase_flutter.dart';

class SuggestionService {
  static final _supabase = Supabase.instance.client;

  /// Submit a new suggestion for a post
  static Future<bool> submitSuggestion({
    required int postId,
    required String type,
    required String title,
    required String description,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userName = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@')[0] ??
          'Anonymous';

      await _supabase.from('suggestions').insert({
        'post_id': postId,
        'suggester_id': user.id,
        'suggester_name': userName,
        'suggester_email': user.email,
        'suggestion_type': type,
        'title': title,
        'description': description,
        'is_read': false, // New suggestions are unread by default
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all suggestions for posts owned by current user
  static Future<List<Map<String, dynamic>>> getMySuggestions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('suggestions')
          .select('''
            *,
            post:posts(id, title, name, user_id)
          ''')
          .eq('post.user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get suggestions for a specific post (only if you're the post creator)
  static Future<List<Map<String, dynamic>>> getPostSuggestions(
      int postId) async {
    try {
      final response = await _supabase
          .from('suggestions')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Mark suggestion as read (only post creator can do this)
  static Future<bool> markAsRead(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get the suggestion with its post_id
      final suggestion = await _supabase
          .from('suggestions')
          .select('id, post_id')
          .eq('id', suggestionId)
          .maybeSingle();

      if (suggestion == null) return false;

      // Check if user owns the post
      final post = await _supabase
          .from('posts')
          .select('user_id')
          .eq('id', suggestion['post_id'])
          .maybeSingle();

      if (post == null || post['user_id'] != user.id) {
        return false; // User doesn't own the post
      }

      // Update the suggestion as read
      final updateResult = await _supabase
          .from('suggestions')
          .update({'is_read': true})
          .eq('id', suggestionId)
          .select('id');

      // Return true only if the update affected at least one row
      return updateResult.isNotEmpty;
    } catch (e) {
      print('Error marking suggestion as read: $e');
      return false;
    }
  }

  /// Mark suggestion as unread (only post creator can do this)
  static Future<bool> markAsUnread(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get the suggestion with its post_id
      final suggestion = await _supabase
          .from('suggestions')
          .select('id, post_id')
          .eq('id', suggestionId)
          .maybeSingle();

      if (suggestion == null) return false;

      // Check if user owns the post
      final post = await _supabase
          .from('posts')
          .select('user_id')
          .eq('id', suggestion['post_id'])
          .maybeSingle();

      if (post == null || post['user_id'] != user.id) {
        return false; // User doesn't own the post
      }

      // Update the suggestion as unread
      final updateResult = await _supabase
          .from('suggestions')
          .update({'is_read': false})
          .eq('id', suggestionId)
          .select('id');

      // Return true only if the update affected at least one row
      return updateResult.isNotEmpty;
    } catch (e) {
      print('Error marking suggestion as unread: $e');
      return false;
    }
  }

  /// Delete suggestion (post creator or suggester can do this)
  static Future<bool> deleteSuggestion(String suggestionId) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Fetch suggestion with related post information to check authorization
      final suggestionResponse = await _supabase
          .from('suggestions')
          .select('suggester_id, post_id, post:posts(user_id)')
          .eq('id', suggestionId)
          .maybeSingle();

      // Check if suggestion exists
      if (suggestionResponse == null) {
        return false; // Suggestion not found
      }

      final suggesterId = suggestionResponse['suggester_id'] as String?;
      final postData = suggestionResponse['post'] as Map<String, dynamic>?;
      final postOwnerId = postData?['user_id'] as String?;

      // Verify authorization: current user must be either the suggester or post creator
      final isAuthorized = user.id == suggesterId || user.id == postOwnerId;

      if (!isAuthorized) {
        return false; // Not authorized to delete this suggestion
      }

      // Perform the delete operation
      await _supabase.from('suggestions').delete().eq('id', suggestionId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get count of unread suggestions for the current user's posts
  static Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      // Count unread suggestions for posts owned by the current user
      // Join with posts table to filter by post owner
      final response = await _supabase
          .from('suggestions')
          .select('id, post!inner(user_id)')
          .eq('is_read', false)
          .eq('post.user_id', user.id);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}
