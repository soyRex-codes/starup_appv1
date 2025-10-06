import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_user.dart';

class AdminAuthService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Admin emails - In production, this should be in database or environment variables
  static const List<String> _adminEmails = [
    'admin@foundervers.com',
    'raj@foundervers.com',
    'support@foundervers.com',
    'rajkushwaha0213@gmail.com',
    // Add more admin emails as needed
  ];

  static bool isAdminEmail(String email) {
    return _adminEmails.contains(email.toLowerCase());
  }

  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) return false;
      
      return isAdminEmail(user.email!);
    } catch (e) {
      if (kDebugMode) debugPrint('Admin check error: $e');
      return false;
    }
  }

  static Future<AdminUser?> getCurrentAdminUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.email == null) return null;
      
      if (!isAdminEmail(user.email!)) return null;

      // Get user profile from database
      final profile = await _client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();

      return AdminUser(
        id: user.id,
        email: user.email!,
        name: profile['name'] ?? profile['full_name'] ?? 'Admin',
        isAdmin: true,
        createdAt: DateTime.parse(profile['created_at']),
        lastLoginAt: DateTime.parse(profile['last_login_at'] ?? profile['created_at']),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Get admin user error: $e');
      return null;
    }
  }

  static Future<void> logAdminAction(String action, Map<String, dynamic> details) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('admin_audit_logs').insert({
        'admin_id': user.id,
        'action': action,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Admin audit log error: $e');
    }
  }
}