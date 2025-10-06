import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';

/// Service to register and manage device push tokens for FCM notifications.
class DeviceService {
  final SupabaseClient _s = Supa.client;

  /// Registers (upserts) a device token for the given user.
  /// If the token already exists for the user, ensures updated_at refreshed.
  Future<void> registerToken({
    required String userId,
    required String token,
    String? platform, // ios / android / web
    String? appVersion,
  }) async {
    try {
      await _s.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'app_version': appVersion,
      }, onConflict: 'user_id,fcm_token');
    } catch (e) {
      // Non-fatal; log or ignore for now.
    }
  }

  /// Remove a token (e.g., on logout or when FCM invalidates it)
  Future<void> removeToken(
      {required String userId, required String token}) async {
    try {
      await _s
          .from('user_devices')
          .delete()
          .match({'user_id': userId, 'fcm_token': token});
    } catch (_) {}
  }

  /// List tokens for debugging or diagnostics
  Future<List<String>> listTokens(String userId) async {
    try {
      final rows = await _s
          .from('user_devices')
          .select('fcm_token')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(rows)
          .map((e) => e['fcm_token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (_) {}
    return const [];
  }
}
