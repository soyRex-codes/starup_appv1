import 'package:supabase_flutter/supabase_flutter.dart';

class VisibilityRules {
  static bool isAdmin(String? email, List<String> admins) {
    if (email == null || email.isEmpty) return false;
    return admins.contains(email.toLowerCase());
  }

  // Posts: show if approved + published OR I’m the author OR I’m admin
  static bool canSeePost({
    required Map<String, dynamic> post,
    required User? me,
    required List<String> admins,
  }) {
    final status = (post['status'] ?? 'published') as String;
    final mod = (post['moderation_status'] ?? 'approved') as String;
    final authorId = (post['user_id'] ?? '') as String;
    final isAuthor = (me?.id ?? '') == authorId;
    final isAdm = isAdmin(me?.email, admins);
    if (isAuthor || isAdm) return true;
    return status == 'published' && mod == 'approved';
  }

  // Messages: show if approved OR I’m the sender OR I’m admin
  static bool canSeeMessage({
    required Map<String, dynamic> message,
    required User? me,
    required List<String> admins,
  }) {
    final mod = (message['moderation_status'] ?? 'approved') as String;
    final senderId =
        (message['user_id'] ?? message['sender_id'] ?? '') as String;
    final isSender = (me?.id ?? '') == senderId;
    final isAdm = isAdmin(me?.email, admins);
    if (isSender || isAdm) return true;
    return mod == 'approved' && (message['deleted_at'] == null);
  }
}
