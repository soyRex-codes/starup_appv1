import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_auth_service.dart';

class AdminService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Posts Management
  static Future<List<Map<String, dynamic>>> getAllPosts({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('posts').select('''
            *,
            user:users(id, name, email),
            media(*)
          ''').order('created_at', ascending: false);

      final posts = await query.range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(posts);
    } catch (e) {
      if (kDebugMode) debugPrint('Get all posts error: $e');
      rethrow;
    }
  }

  static Future<void> deletePost(int postId, String reason) async {
    try {
      // Log the action
      await AdminAuthService.logAdminAction('delete_post', {
        'post_id': postId,
        'reason': reason,
      });

      // Delete associated media first
      await _client.from('media').delete().eq('post_id', postId);

      // Delete the post
      await _client.from('posts').delete().eq('id', postId);
    } catch (e) {
      if (kDebugMode) debugPrint('Delete post error: $e');
      rethrow;
    }
  }

  static Future<void> updatePost(
      int postId, Map<String, dynamic> updates) async {
    try {
      await AdminAuthService.logAdminAction('update_post', {
        'post_id': postId,
        'updates': updates,
      });

      await _client.from('posts').update(updates).eq('id', postId);
    } catch (e) {
      if (kDebugMode) debugPrint('Update post error: $e');
      rethrow;
    }
  }

  // User Management
  static Future<List<Map<String, dynamic>>> getAllUsers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      final users = await query.range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(users);
    } catch (e) {
      if (kDebugMode) debugPrint('Get all users error: $e');
      rethrow;
    }
  }

  static Future<void> suspendUser(String userId, String reason) async {
    try {
      await AdminAuthService.logAdminAction('suspend_user', {
        'user_id': userId,
        'reason': reason,
      });

      await _client.from('users').update({
        'is_suspended': true,
        'suspension_reason': reason,
        'suspended_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Suspend user error: $e');
      rethrow;
    }
  }

  static Future<void> unsuspendUser(String userId) async {
    try {
      await AdminAuthService.logAdminAction('unsuspend_user', {
        'user_id': userId,
      });

      await _client.from('users').update({
        'is_suspended': false,
        'suspension_reason': null,
        'suspended_at': null,
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Unsuspend user error: $e');
      rethrow;
    }
  }

  // Analytics
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Get simple counts using length of returned arrays
      final users = await _client.from('users').select('id');
      final posts = await _client.from('posts').select('id');

      // Try to get messages, fallback if table doesn't exist
      int totalMessages = 0;
      try {
        final messages = await _client.from('chat_messages').select('id');
        totalMessages = (messages as List).length;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Chat messages table not found, skipping count');
        }
      }

      // Get recent activity (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentPosts = await _client
          .from('posts')
          .select('id')
          .gte('created_at', weekAgo.toIso8601String());

      final recentUsers = await _client
          .from('users')
          .select('id')
          .gte('created_at', weekAgo.toIso8601String());

      return {
        'total_users': (users as List).length,
        'total_posts': (posts as List).length,
        'total_messages': totalMessages,
        'recent_posts': (recentPosts as List).length,
        'recent_users': (recentUsers as List).length,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Get analytics error: $e');
      rethrow;
    }
  }

  // Global Chat Moderation
  static Future<List<Map<String, dynamic>>> getChatMessages({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final messages = await _client
          .from('chat_messages')
          .select('''
            *,
            user:users(id, name, email)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      if (kDebugMode) debugPrint('Get chat messages error: $e');
      rethrow;
    }
  }

  static Future<void> deleteChatMessage(int messageId, String reason) async {
    try {
      await AdminAuthService.logAdminAction('delete_chat_message', {
        'message_id': messageId,
        'reason': reason,
      });

      await _client.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      if (kDebugMode) debugPrint('Delete chat message error: $e');
      rethrow;
    }
  }

  // Business Applications Management
  static Future<List<Map<String, dynamic>>> getAllApplications({
    int limit = 50,
    int offset = 0,
    String? status,
    String? serviceType,
  }) async {
    try {
      final queryBuilder = _client.from('business_applications').select('*');

      // Filter out DRAFT applications by default - only show submitted applications
      final filteredQuery = status != null && status.isNotEmpty
          ? queryBuilder.eq('status', status)
          : queryBuilder.neq('status',
              'draft'); // Exclude DRAFT if no specific status selected

      final finalQuery = serviceType != null && serviceType.isNotEmpty
          ? filteredQuery.eq('service_type', serviceType)
          : filteredQuery;

      final applications = await finalQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(applications);
    } catch (e) {
      if (kDebugMode) debugPrint('Get all applications error: $e');
      rethrow;
    }
  }

  static Future<void> updateApplicationStatus(
      int applicationId, String status, String? adminNotes) async {
    try {
      await AdminAuthService.logAdminAction('update_application_status', {
        'application_id': applicationId,
        'status': status,
        'admin_notes': adminNotes,
      });

      final updates = {'status': status};
      if (adminNotes != null) {
        updates['admin_notes'] = adminNotes;
      }

      await _client
          .from('business_applications')
          .update(updates)
          .eq('id', applicationId);
    } catch (e) {
      if (kDebugMode) debugPrint('Update application status error: $e');
      rethrow;
    }
  }

  static Future<void> assignApplication(
      int applicationId, String assignedTo) async {
    try {
      await AdminAuthService.logAdminAction('assign_application', {
        'application_id': applicationId,
        'assigned_to': assignedTo,
      });

      await _client.from('business_applications').update({
        'assigned_to': assignedTo,
      }).eq('id', applicationId);
    } catch (e) {
      if (kDebugMode) debugPrint('Assign application error: $e');
      rethrow;
    }
  }

  /// Delete a business application
  /// Logs the admin action and removes the application from the database
  static Future<void> deleteApplication(int applicationId) async {
    try {
      // Log the admin action
      await AdminAuthService.logAdminAction('delete_application', {
        'application_id': applicationId,
      });

      // Delete the application
      await _client
          .from('business_applications')
          .delete()
          .eq('id', applicationId);

      if (kDebugMode) debugPrint('✅ Application $applicationId deleted');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Delete application error: $e');
      rethrow;
    }
  }
}
