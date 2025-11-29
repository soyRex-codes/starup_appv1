import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for reporting users
class UserReportService {
  static final _supabase = Supabase.instance.client;

  /// Get all pending user reports (admin only)
  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      final result = await _supabase
          .from('user_reports')
          .select('''
            *,
            reported_user:users!reported_user_id(id, name, email),
            reporter:users!reporter_id(id, name, email)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error fetching pending user reports: $e');
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

      await _supabase.from('user_reports').update({
        'status': 'resolved',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'action_taken': actionTaken,
        'admin_notes': adminNotes,
      }).eq('id', reportId);

      debugPrint('✅ User report resolved: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error resolving user report: $e');
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

      await _supabase.from('user_reports').update({
        'status': 'dismissed',
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'action_taken': 'no_action',
        'admin_notes': adminNotes,
      }).eq('id', reportId);

      debugPrint('✅ User report dismissed: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error dismissing user report: $e');
      return false;
    }
  }
}
