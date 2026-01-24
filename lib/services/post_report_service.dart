import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for reporting posts
class PostReportService {
  static final _supabase = Supabase.instance.client;

  /// Report reasons
  static const List<String> reportReasons = [
    'spam',
    'harassment',
    'inappropriate',
    'misleading',
    'hate_speech',
    'violence',
    'other',
  ];

  /// Human-readable labels for report reasons
  static const Map<String, String> reasonLabels = {
    'spam': 'Spam or Scam',
    'harassment': 'Harassment or Bullying',
    'inappropriate': 'Inappropriate Content',
    'misleading': 'False or Misleading',
    'hate_speech': 'Hate Speech',
    'violence': 'Violence or Threats',
    'other': 'Other',
  };

  /// Report a post
  /// Returns true if report was submitted successfully
  static Future<bool> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Cannot report: User not authenticated');
        return false;
      }

      if (!reportReasons.contains(reason)) {
        debugPrint('Invalid report reason: $reason');
        return false;
      }

      // Submit report to database
      await _supabase.from('post_reports').insert({
        'post_id': postId,
        'reporter_id': userId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });

      debugPrint('Post reported successfully: $postId');
      return true;
    } on PostgrestException catch (e) {
      // Handle duplicate report (user already reported this post)
      if (e.code == '23505') {
        debugPrint('User has already reported this post');
        return false;
      }
      debugPrint('Error reporting post: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error reporting post: $e');
      return false;
    }
  }

  /// Check if current user has already reported a post
  static Future<bool> hasUserReportedPost(String postId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('post_reports')
          .select('id')
          .eq('post_id', postId)
          .eq('reporter_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Error checking report status: $e');
      return false;
    }
  }

  /// Get all pending reports (admin only)
  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      final result = await _supabase
          .from('post_reports')
          .select('''
            *,
            post:posts(id, title, description, user_id, status),
            reporter:users!reporter_id(id, name, email)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error fetching pending reports: $e');
      return [];
    }
  }

  /// Get all reports for a specific post (admin only)
  static Future<List<Map<String, dynamic>>> getPostReports(String postId) async {
    try {
      final result = await _supabase
          .from('post_reports')
          .select('''
            *,
            reporter:users!reporter_id(id, name, email)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Error fetching post reports: $e');
      return [];
    }
  }

  /// Resolve a report (admin only)
  static Future<bool> resolveReport({
    required String reportId,
    required String actionTaken,
    String? adminNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('post_reports').update({
        'status': 'resolved',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'action_taken': actionTaken,
        'admin_notes': adminNotes,
      }).eq('id', reportId);

      debugPrint('Report resolved: $reportId');
      return true;
    } catch (e) {
      debugPrint('Error resolving report: $e');
      return false;
    }
  }

  /// Dismiss a report without action (admin only)
  static Future<bool> dismissReport({
    required String reportId,
    String? adminNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('post_reports').update({
        'status': 'dismissed',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'action_taken': 'no_action',
        'admin_notes': adminNotes,
      }).eq('id', reportId);

      debugPrint('Report dismissed: $reportId');
      return true;
    } catch (e) {
      debugPrint('Error dismissing report: $e');
      return false;
    }
  }

  /// Get report statistics (admin only)
  static Future<Map<String, int>> getReportStats() async {
    try {
      final counts = await _supabase
          .from('post_reports')
          .select('status')
          .then((data) {
        final stats = <String, int>{
          'total': data.length,
          'pending': 0,
          'resolved': 0,
          'dismissed': 0,
        };

        for (final report in data) {
          final status = report['status'] as String;
          stats[status] = (stats[status] ?? 0) + 1;
        }

        return stats;
      });

      return counts;
    } catch (e) {
      debugPrint('Error fetching report stats: $e');
      return {'total': 0, 'pending': 0, 'resolved': 0, 'dismissed': 0};
    }
  }
}
