import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> upsertUser({
    required String userId,
    required String email,
    String? name,
    String? username,
    String? fullName,
    String? avatarUrl,
    bool emailVerified = false,
    bool updateLastLoginOnlyIfExists = false,
  }) async {
    try {
      if (updateLastLoginOnlyIfExists) {
        // Try update first; if zero rows affected, fall back to insert.
        final updateResp = await _client.from('users').update({
          'last_login_at': DateTime.now().toIso8601String(),
          'email_verified': emailVerified
        }).eq('id', userId);
        if (updateResp is List && updateResp.isNotEmpty) return;
      }
      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'username': username,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'email_verified': emailVerified,
        'last_login_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Upsert user error: $e');
    }
  }

  Future<Map<String, dynamic>?> getById(String userId) async {
    try {
      final rows =
          await _client.from('users').select('*').eq('id', userId).limit(1);
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list.isEmpty ? null : list.first;
    } catch (e) {
      if (kDebugMode) debugPrint('Get user by ID error: $e');
      return null;
    }
  }

  /// Get public profile information for any user
  /// Excludes sensitive data like email
  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    try {
      final rows = await _client.from('users').select('''
            id,
            name,
            username,
            full_name,
            bio,
            company,
            location,
            avatar_url,
            email_verified,
            is_premium,
            premium_expires_at,
            created_at
          ''').eq('id', userId).limit(1);

      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return list.isEmpty ? null : list.first;
    } catch (e) {
      debugPrint('Error fetching public profile: $e');
      return null;
    }
  }

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return getById(user.id);
  }
}
